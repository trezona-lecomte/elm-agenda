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


init : Mode -> EventMapping event -> List event -> ( Model, Cmd Msg )
init mode eventMapping events =
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
          , virtualEvents = virtualiseEvents eventMapping events
          }
        , Task.perform SetDate Date.now
        )


virtualiseEvents : EventMapping event -> List event -> List ProtoEvent
virtualiseEvents map =
    let
        virtualise event =
            { id = Just <| map.id event
            , start = map.start event
            , finish = map.finish event
            , label = map.label event
            }
    in
        List.map virtualise



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

        DragEvent dragMode protoEvent mousePosition ->
            ( model
            , encodeEventDrag dragMode protoEvent mousePosition
                |> Ports.dragEvent
            , Nothing
            )

        StopEventDrag dragMode protoEvent mousePosition ->
            ( { model | draggingProtoEvent = Nothing }
            , encodeEventDrag dragMode protoEvent mousePosition
                |> Ports.stopDraggingEvent
            , Nothing
            )

        CacheEventUpdateFromFromDrag result ->
            -- TODO: Deal with errors properly
            case result of
                Err error ->
                    ( model, Cmd.none, Nothing )

                Ok (EventDrag dragMode protoEvent quarter) ->
                    case dateFromQuarter model quarter of
                        Err err ->
                            ( model, Cmd.none, Nothing )

                        Ok newDate ->
                            case dragMode of
                                Create ->
                                    ( replaceProtoEvent model { protoEvent | finish = newDate }
                                    , Cmd.none
                                    , Nothing
                                    )

                                Move ->
                                    ( replaceProtoEvent model (moveProtoEvent protoEvent newDate)
                                    , Cmd.none
                                    , Nothing
                                    )

                                Extend ->
                                    ( replaceProtoEvent model { protoEvent | finish = newDate }
                                    , Cmd.none
                                    , Nothing
                                    )

        PersistEventUpdateFromDrag result ->
            case result of
                Err error ->
                    -- TODO: Deal with errors properly
                    ( model, Cmd.none, Nothing )

                -- TODO: Reduce nesting
                Ok (EventDrag dragMode protoEvent quarter) ->
                    case dateFromQuarter model quarter of
                        Err err ->
                            let
                                foo =
                                    (Debug.log "error: " err)
                            in
                                -- TODO: Deal with errors properly
                                ( model, Cmd.none, Nothing )

                        Ok newDate ->
                            case dragMode of
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
            ( removeProtoEvent eventId model, Cmd.none, config.removeEvent eventId )


moveProtoEvent : ProtoEvent -> Date -> ProtoEvent
moveProtoEvent ({ id, start, finish, label } as protoEvent) newStart =
    let
        offset =
            Date.diff Date.Minute start newStart

        newFinish =
            Date.add Date.Minute offset finish
    in
        { protoEvent | start = newStart, finish = newFinish }


replaceProtoEvent : Model -> ProtoEvent -> Model
replaceProtoEvent model newEvent =
    let
        replaceIfIdMatches event =
            if event.id == newEvent.id then
                newEvent
            else
                event

        events =
            List.map replaceIfIdMatches model.virtualEvents
    in
        { model | virtualEvents = events }


removeProtoEvent : String -> Model -> Model
removeProtoEvent id model =
    { model | virtualEvents = List.filter (\e -> e.id /= Just id) model.virtualEvents }


encodeEventDrag : DragMode -> ProtoEvent -> Mouse.Position -> String
encodeEventDrag dragMode event mousePosition =
    Encode.encode 0 <|
        Encode.object
            [ ( "dragMode", dragModeEncoder dragMode )
            , ( "event", protoEventEncoder event )
            , ( "x", Encode.int mousePosition.x )
            , ( "y", Encode.int mousePosition.y )
            ]


dragModeEncoder : DragMode -> Encode.Value
dragModeEncoder dragMode =
    Encode.string <| toString dragMode


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


view : Model -> Html Msg
view ({ activeMode, draggingProtoEvent, virtualEvents } as model) =
    let
        ( viewControls, viewCalendar ) =
            case activeMode of
                Daily ->
                    ( View.Daily.paginationControls model ( Today, Previous, Next )
                    , View.Daily.calendar model virtualEvents
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
                    ( Mouse.moves <| DragEvent model.dragMode event
                    , Mouse.ups <| StopEventDrag model.dragMode event
                    )

                Nothing ->
                    ( Sub.none, Sub.none )
    in
        Sub.batch
            [ mouseMoves
            , mouseUps
            , Ports.draggedEvent <|
                decodeEventDrag
                    >> CacheEventUpdateFromFromDrag
            , Ports.stoppedDraggingEvent <|
                decodeEventDrag
                    >> PersistEventUpdateFromDrag
            ]


decodeEventDrag : String -> Result String EventDrag
decodeEventDrag =
    Decode.map3 EventDrag
        (Decode.field "dragMode" dragModeDecoder)
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


dragModeDecoder : Decode.Decoder DragMode
dragModeDecoder =
    Decode.string
        |> Decode.andThen
            (\str ->
                case str of
                    "Create" ->
                        Decode.succeed Create

                    "Move" ->
                        Decode.succeed Move

                    "Extend" ->
                        Decode.succeed Extend

                    other ->
                        Decode.fail <| "Unknown dragMode: " ++ other
            )
