module Calendar exposing (init, subscriptions, update, view)

import Calendar.Config exposing (Config, EventMapping)
import Calendar.DateHelpers exposing (dateFromQuarterString)
import Calendar.EventHelpers exposing (virtualiseEvents)
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
import Keyboard
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


init : Mode -> EventMapping event -> List (Event e) -> ( Model, Cmd Msg )
init mode eventMapping events =
    let
        selectedDate =
            Date.fromParts 1970 Date.Jan 1 8 0 0 0
    in
        ( { activeMode = mode
          , showSettings = False
          , useKeyboardShortcuts = True
          , showKeyboardShortcutHelp = False
          , selectedDate = selectedDate
          , draggingProtoEvent = Nothing
          , dragMode = Move
          , protoEvent = initProtoEvent selectedDate
          , eventFormActive = False
          , virtualEvents = virtualiseEvents events
          }
        , Task.perform SetDate Date.now
        )



-- UPDATE


update : Config event msg -> Msg -> Model -> ( Model, Cmd Msg, Maybe msg )
update config msg model =
    case msg of
        ChangeMode mode ->
            ( { model | activeMode = mode }, Cmd.none, Nothing )

        ShowSettings ->
            ( { model | showSettings = True }, Cmd.none, Nothing )

        HideSettings ->
            ( { model | showSettings = False }, Cmd.none, Nothing )

        ToggleKeyboardShortcuts ->
            ( { model | useKeyboardShortcuts = not model.useKeyboardShortcuts }, Cmd.none, Nothing )

        KeyDown keyCode ->
            case keyCode of
                191 ->
                    ( { model | showKeyboardShortcutHelp = True }, Cmd.none, Nothing )

                _ ->
                    ( model, Cmd.none, Nothing )

        KeyUp keyCode ->
            case keyCode of
                191 ->
                    ( { model | showKeyboardShortcutHelp = False }, Cmd.none, Nothing )

                _ ->
                    ( model, Cmd.none, Nothing )

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

        ChangeEventLabel proto label ->
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

        StartDraggingEvent mode protoEvent mousePosition ->
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

        StopDraggingEvent dragMode protoEvent mousePosition ->
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
                    case dateFromQuarterString model.selectedDate quarter of
                        Err err ->
                            ( model, Cmd.none, Nothing )

                        Ok newDate ->
                            ( replaceDraggedProtoEvent model (cacheEventUpdate dragMode protoEvent newDate)
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
                    case dateFromQuarterString model.selectedDate quarter of
                        Err err ->
                            -- TODO: Deal with errors properly
                            ( model, Cmd.none, Nothing )

                        Ok newDate ->
                            let
                                updatedModel =
                                    { model | draggingProtoEvent = Nothing }
                            in
                                ( updatedModel
                                , Cmd.none
                                , persistEventUpdate dragMode protoEvent newDate config
                                )

        RemoveEvent eventId ->
            ( model, Cmd.none, config.removeEvent eventId )


cacheEventUpdate : DragMode -> ProtoEvent -> Date -> ProtoEvent
cacheEventUpdate dragMode ({ start, finish } as protoEvent) date =
    case dragMode of
        Create ->
            { protoEvent | finish = date }

        Move ->
            let
                offset =
                    Date.diff Date.Minute start date

                newFinish =
                    Date.add Date.Minute offset finish
            in
                { protoEvent | start = date, finish = newFinish }

        Extend ->
            { protoEvent | finish = date }


persistEventUpdate : DragMode -> ProtoEvent -> Date -> Config event msg -> Maybe msg
persistEventUpdate dragMode protoEvent date config =
    case dragMode of
        Create ->
            config.createEvent { protoEvent | finish = date }

        Move ->
            Maybe.andThen (flip config.moveEvent date) protoEvent.id

        Extend ->
            Maybe.andThen (flip config.extendEvent date) protoEvent.id


replaceDraggedProtoEvent : Model -> ProtoEvent -> Model
replaceDraggedProtoEvent model newEvent =
    let
        replaceIfIdMatches event =
            if event.id == newEvent.id then
                newEvent
            else
                event

        events =
            List.map replaceIfIdMatches model.virtualEvents
    in
        { model | draggingProtoEvent = Just newEvent, virtualEvents = events }


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
                    , viewSettingsControls
                    ]
                , viewCalendar
                , viewEventForm model
                , viewSettingsForm model
                , viewKeyboardShortcutHelp model
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


viewSettingsControls : Html Msg
viewSettingsControls =
    div [ S.class "settings-button" ]
        [ a [ S.class "settings-link icon", onClick ShowSettings ]
            [ i [ class "fa fa-cog" ] [] ]
        ]


viewSettingsForm : Model -> Html Msg
viewSettingsForm model =
    if model.showSettings then
        div
            [ class "modal is-active" ]
            [ div [ class "modal-background" ]
                []
            , div [ class "modal-card" ]
                [ header [ class "modal-card-head" ]
                    [ p [ class "modal-card-title" ]
                        [ text "Settings" ]
                    , button [ class "delete", onClick HideSettings ]
                        []
                    ]

                -- TODO: This checkbox is buggy; we send the msg twice
                -- when the use clicks the label text.
                , section [ class "modal-card-body" ]
                    [ Html.form []
                        [ div [ class "field" ]
                            [ div [ class "control" ]
                                [ label
                                    [ S.class "checkbox"
                                    , onClick ToggleKeyboardShortcuts
                                    ]
                                    [ input
                                        [ type_ "checkbox"
                                        , checked model.useKeyboardShortcuts
                                        , style [ ( "margin-right", "5px" ) ]
                                        ]
                                        []
                                    , text "Enable keyboard shortcuts"
                                    ]
                                ]
                            ]
                        ]
                    ]
                , footer [ class "modal-card-foot" ]
                    [ button
                        [ class "button is-success"
                        , onClick HideSettings
                        ]
                        [ text "Done" ]
                    ]
                ]
            ]
    else
        div [ class "modal" ] []


viewKeyboardShortcutHelp : Model -> Html Msg
viewKeyboardShortcutHelp model =
    if model.showKeyboardShortcutHelp then
        div
            [ class "modal is-active" ]
            [ div [ class "modal-background" ]
                []
            , div [ class "modal-card" ]
                [ header [ class "modal-card-head" ]
                    [ p [ class "modal-card-title" ]
                        [ text "Keyboard Shortcuts" ]
                    ]
                , section [ class "modal-card-body" ]
                    [ table [ class "table is-bordered is-fullwidth" ]
                        [ thead []
                            [ tr []
                                [ th [] [ text "Description" ]
                                , th [] [ text "Shortcut" ]
                                ]
                            ]
                        , tr []
                            [ td [] [ text "Show shortcut help" ]
                            , td [] [ text "/ or ?" ]
                            ]
                        , tr []
                            [ td [] [ text "Move between date ranges" ]
                            , td [] [ text "j or n" ]
                            ]
                        , tr []
                            [ td [] [ text "Move to the current date" ]
                            , td [] [ text "t" ]
                            ]
                        , tr []
                            [ td [] [ text "Create a new event" ]
                            , td [] [ text "c" ]
                            ]
                        , tr []
                            [ td [] [ text "Delete an event" ]
                            , td [] [ text "Backspace or Delete" ]
                            ]
                        ]
                    ]
                ]
            ]
    else
        div [ class "modal" ] []


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
                        [ text "Edit Event" ]
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
                                    , placeholder "My event"
                                    , onInput <| ChangeEventLabel model.protoEvent
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
                    , Mouse.ups <| StopDraggingEvent model.dragMode event
                    )

                Nothing ->
                    ( Sub.none, Sub.none )

        ( keyDowns, keyUps ) =
            if model.useKeyboardShortcuts then
                ( Keyboard.downs KeyDown, Keyboard.ups KeyUp )
            else
                ( Sub.none, Sub.none )
    in
        Sub.batch
            [ mouseMoves
            , mouseUps
            , keyDowns
            , keyUps
            , Ports.draggedEvent <|
                decodeEventDrag
                    >> CacheEventUpdateFromFromDrag
            , Ports.stoppedDraggingEvent <|
                decodeEventDrag
                    >> PersistEventUpdateFromDrag
            ]



-- ENCODING / DECODING


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
