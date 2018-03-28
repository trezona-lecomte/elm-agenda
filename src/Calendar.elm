module Calendar exposing (init, subscriptions, update, view)

import Basics.Extra exposing (fmod)
import Calendar.Config exposing (Config, EventMapping)
import Calendar.Ports as Ports
import Calendar.Types exposing (..)
import Date exposing (Date)
import Date.Extra as Date
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Json.Decode as Decode
import Json.Decode.Extra as Decode
import Json.Encode as Encode
import Json.Encode.Extra as Encode
import Labels
import Mouse
import Style as S
import Task
import View.Daily


-- MODEL


intervalForMode : Mode -> Date.Interval
intervalForMode mode =
    case mode of
        Daily ->
            Date.Day


modes : List Mode
modes =
    [ Daily ]


init : Mode -> ( Model, Cmd Msg )
init mode =
    let
        selectedDate =
            Date.fromParts 1970 Date.Jan 1 0 0 0 0
    in
        ( { activeMode = mode
          , selectedDate = selectedDate
          , draggingProtoEvent = Nothing
          , dragMode = Move
          , protoEvent = initProtoEvent selectedDate
          , eventFormActive = False
          }
        , Task.perform SetDate Date.now
        )



-- UPDATE


update : Config event msg -> Msg -> Model -> ( Model, Cmd Msg, Maybe msg )
update config msg model =
    case msg of
        ChangeMode mode ->
            ( { model | activeMode = mode }, Cmd.none, Nothing )

        SetDate date ->
            ( { model | selectedDate = date }, Cmd.none, Nothing )

        Today ->
            ( model, Task.perform SetDate Date.now, Nothing )

        Previous ->
            ( { model | selectedDate = Date.add Date.Day -1 model.selectedDate }
            , Cmd.none
            , Nothing
            )

        Next ->
            ( { model | selectedDate = Date.add Date.Day 1 model.selectedDate }
            , Cmd.none
            , Nothing
            )

        AddEvent ->
            ( { model
                | protoEvent = initProtoEvent model.selectedDate
                , eventFormActive = True
              }
            , Cmd.none
            , Nothing
            )

        InputEventLabel proto label ->
            let
                updatedEvent =
                    { label = label
                    , id = proto.id
                    , start = proto.start
                    , finish = proto.finish
                    }
            in
                ( { model | protoEvent = updatedEvent }, Cmd.none, Nothing )

        CloseEventForm ->
            ( { model
                | protoEvent = initProtoEvent model.selectedDate
                , eventFormActive = False
              }
            , Cmd.none
            , Nothing
            )

        PersistProtoEvent proto ->
            ( { model
                | protoEvent = initProtoEvent model.selectedDate
                , eventFormActive = False
              }
            , Cmd.none
            , config.createEvent
                { id = proto.id
                , start = proto.start
                , finish = proto.finish
                , label = proto.label
                }
            )

        StartEventDrag mode protoEvent mousePosition ->
            ( { model | draggingProtoEvent = Just protoEvent, dragMode = mode }
            , Cmd.none
            , Nothing
            )

        DragEvent protoEvent mousePosition ->
            ( model
            , encodeProtoEventAndMousePosition protoEvent mousePosition
                |> Ports.fetchQuarterAtPosition
            , Nothing
            )

        StopEventDrag protoEvent mousePosition ->
            ( { model | draggingProtoEvent = Nothing }
            , encodeProtoEventAndMousePosition protoEvent mousePosition
                |> Ports.fetchQuarterAtPosition
            , Nothing
            )

        AttemptEventUpdateFromDrag result ->
            case result of
                Err error ->
                    -- TODO: Deal with errors properly
                    ( model, Cmd.none, Nothing )

                -- TODO: Reduce nesting
                Ok ( protoEvent, quarter ) ->
                    case dateFromQuarter model quarter of
                        Err err ->
                            let
                                foo =
                                    (Debug.log "error: " err)
                            in
                                -- TODO: Deal with errors properly
                                ( model, Cmd.none, Nothing )

                        Ok newDate ->
                            -- TODO: This is potentially buggy, because Ports
                            -- are async so the dragMode could have
                            -- changed from what it was when we sent the
                            -- original request to the Port.
                            case model.dragMode of
                                Create ->
                                    ( model
                                    , Cmd.none
                                    , config.createEvent { protoEvent | finish = newDate }
                                    )

                                Move ->
                                    ( model
                                    , Cmd.none
                                    , config.updateEventStart { protoEvent | start = newDate }
                                    )

                                Extend ->
                                    ( model
                                    , Cmd.none
                                    , config.updateEventFinish { protoEvent | finish = newDate }
                                    )

        RemoveEvent eventId ->
            ( model, Cmd.none, config.removeEvent eventId )


encodeProtoEventAndMousePosition : ProtoEvent -> Mouse.Position -> String
encodeProtoEventAndMousePosition event mousePosition =
    Encode.encode 0 <|
        Encode.object
            [ ( "event", protoEventEncoder event )
            , ( "x", Encode.int mousePosition.x )
            , ( "y", Encode.int mousePosition.y )
            ]


protoEventEncoder : ProtoEvent -> Encode.Value
protoEventEncoder { id, start, finish, label } =
    Encode.object
        [ ( "eventId", Encode.maybe Encode.string id )
        , ( "start", Encode.string <| Date.toUtcIsoString start )
        , ( "finish", Encode.string <| Date.toUtcIsoString finish )
        , ( "label", Encode.string label )
        ]


dateFromQuarter : Model -> String -> Result String Date
dateFromQuarter { selectedDate } quarter =
    let
        convert q =
            let
                ( hour, minute ) =
                    ( floor fractionOfDayInHours, minutesAsFraction )

                fractionOfDayInMinutes =
                    -- N.B. +1 takes us to the 'end' of the quarter hour.
                    (toFloat (q + 1) / quartersInDay) * minutesInDay

                fractionOfDayInHours =
                    -- The hour that this quarter represents, as a fraction. E.g. 13:30
                    -- would be 13.5
                    fractionOfDayInMinutes / minutesInHour

                minutesAsFraction =
                    (fmod fractionOfDayInMinutes 60) |> round
            in
                Date.fromParts
                    (Date.year selectedDate)
                    (Date.month selectedDate)
                    (Date.day selectedDate)
                    hour
                    minute
                    (Date.second selectedDate)
                    (Date.millisecond selectedDate)
    in
        String.toInt quarter
            |> Result.map convert


quartersInDay : number
quartersInDay =
    96


minutesInDay : number
minutesInDay =
    1440


minutesInHour : number
minutesInHour =
    60



-- VIEW


view : Config event msg -> Model -> List event -> Html Msg
view config ({ activeMode, draggingProtoEvent } as model) events =
    let
        ( viewControls, viewCalendar ) =
            case activeMode of
                Daily ->
                    ( View.Daily.paginationControls model ( Today, Previous, Next )
                    , View.Daily.calendar config model events
                    )

        dragCursorStyle =
            case draggingProtoEvent of
                Just _ ->
                    ( "cursor", "grabbing" )

                Nothing ->
                    ( "", "" )
    in
        div [ class "container", style [ dragCursorStyle ] ]
            [ div [ S.class "calendar" ]
                [ div [ S.class "calendar-header" ]
                    [ viewModeControls
                    , viewAddEventButton
                    , viewControls
                    ]
                , viewCalendar
                , viewEventForm model
                ]
            ]


viewModeControls : Html Msg
viewModeControls =
    div [ S.class "mode-controls" ]
        (List.map modeButton modes)


modeButton : Mode -> Html Msg
modeButton mode =
    button [ class "button", onClick (ChangeMode mode) ]
        [ text <| Labels.changeModeButton mode ]


viewAddEventButton : Html Msg
viewAddEventButton =
    div [ S.class "add-event" ]
        [ button [ class "button", onClick AddEvent ]
            [ text <| Labels.addEventButton ]
        ]


viewEventForm : Model -> Html Msg
viewEventForm model =
    if model.eventFormActive then
        div
            [ class "modal is-active" ]
            [ div [ class "modal-background" ]
                []
            , div [ class "modal-card" ]
                [ header [ class "modal-card-head" ]
                    [ p [ class "modal-card-title" ]
                        [ text "Modal title" ]
                    , button [ class "delete", onClick CloseEventForm ]
                        []
                    ]
                , section [ class "modal-card-body" ]
                    [ Html.form []
                        [ div [ class "field" ]
                            [ label [ class "label" ] [ text "Event Name" ]
                            , div [ class "control" ]
                                [ input
                                    [ class "input"
                                    , type_ "text"
                                    , placeholder "Text input"
                                    , onInput <| InputEventLabel model.protoEvent
                                    ]
                                    []
                                ]
                            ]
                        ]
                    ]
                , footer [ class "modal-card-foot" ]
                    [ button
                        [ class "button is-success"
                        , onClick <| PersistProtoEvent model.protoEvent
                        ]
                        [ text "Save" ]
                    , button
                        [ class "button"
                        , onClick CloseEventForm
                        ]
                        [ text "Cancel" ]
                    ]
                ]
            ]
    else
        div [ class "modal" ] []



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    let
        ( mouseMoves, mouseUps ) =
            case model.draggingProtoEvent of
                Just event ->
                    ( Mouse.moves <| DragEvent event
                    , Mouse.ups <| StopEventDrag event
                    )

                Nothing ->
                    ( Sub.none, Sub.none )
    in
        Sub.batch
            [ mouseMoves
            , mouseUps
            , Ports.fetchedQuarterAtPosition <|
                decodeQuarter
                    >> AttemptEventUpdateFromDrag
            ]


decodeQuarter : String -> Result String ( ProtoEvent, String )
decodeQuarter =
    Decode.map2 (,)
        (Decode.field "event" protoEventDecoder)
        (Decode.field "quarter" Decode.string)
        |> Decode.decodeString


protoEventDecoder : Decode.Decoder ProtoEvent
protoEventDecoder =
    Decode.map4
        ProtoEvent
        (Decode.maybe (Decode.field "eventId" Decode.string))
        (Decode.field "start" Decode.date)
        (Decode.field "finish" Decode.date)
        (Decode.field "label" Decode.string)
