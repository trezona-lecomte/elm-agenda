module Calendar exposing (Model, init, subscriptions, update, view)

import Basics.Extra exposing (fmod)
import Calendar.Ports as Ports
import Calendar.Types exposing (Mode(..), Msg(..), DragMode(..))
import Config exposing (CalendarConfig, EventConfig)
import Date exposing (Date)
import Date.Extra as Date
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Json.Decode as Decode
import Json.Encode as Encode
import Labels
import Mouse
import Style as S
import Task
import View.Daily


-- MODEL


type alias Model =
    { activeMode : Mode
    , selectedDate : Date
    , draggingEventId : Maybe String
    , dragMode : DragMode
    }


intervalForMode : Mode -> Date.Interval
intervalForMode mode =
    case mode of
        Daily ->
            Date.Day


modes : List Mode
modes =
    [ Daily ]


init : Mode -> Date -> Model
init mode date =
    { activeMode = mode
    , selectedDate = date
    , draggingEventId = Nothing
    , dragMode = Move
    }



-- UPDATE


update : CalendarConfig msg -> EventConfig event -> Msg -> Model -> ( Model, Cmd Msg, Maybe msg )
update calendarConfig eventConfig msg model =
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

        StartEventDrag mode eventId mousePosition ->
            ( { model | draggingEventId = Just eventId, dragMode = mode }
            , Cmd.none
            , Nothing
            )

        DragEvent eventId mousePosition ->
            ( model
            , encodeEventIdAndMousePosition eventId mousePosition
                |> Ports.fetchQuarterAtPosition
            , Nothing
            )

        StopEventDrag eventId mousePosition ->
            ( { model | draggingEventId = Nothing }
            , encodeEventIdAndMousePosition eventId mousePosition
                |> Ports.fetchQuarterAtPosition
            , Nothing
            )

        AttemptEventUpdateFromDrag result ->
            case result of
                Err error ->
                    -- TODO: Deal with errors properly
                    ( model, Cmd.none, Nothing )

                -- TODO: Reduce nesting
                Ok ( eventId, quarter ) ->
                    case dateFromQuarter model quarter of
                        Err _ ->
                            -- TODO: Deal with errors properly
                            ( model, Cmd.none, Nothing )

                        Ok newFinishDate ->
                            let
                                updateEvent =
                                    case model.dragMode of
                                        Move ->
                                            calendarConfig.moveEvent

                                        Extend ->
                                            calendarConfig.extendEvent
                            in
                                ( model
                                , Cmd.none
                                , updateEvent eventId newFinishDate
                                )


encodeEventIdAndMousePosition : String -> Mouse.Position -> String
encodeEventIdAndMousePosition eventId mousePosition =
    Encode.encode 0 <|
        Encode.object
            [ ( "eventId", Encode.string eventId )
            , ( "x", Encode.int mousePosition.x )
            , ( "y", Encode.int mousePosition.y )
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


view : Model -> CalendarConfig msg -> EventConfig event -> List event -> Model -> Html Msg
view model calendarConfig eventConfig events { activeMode, selectedDate, draggingEventId } =
    let
        ( viewControls, viewCalendar ) =
            case activeMode of
                Daily ->
                    ( View.Daily.paginationControls selectedDate ( Today, Previous, Next )
                    , View.Daily.calendar selectedDate calendarConfig eventConfig events
                    )

        dragCursorStyle =
            case draggingEventId of
                Just id ->
                    ( "cursor", "ns-resize" )

                Nothing ->
                    ( "", "" )
    in
        div [ class "container", style [ dragCursorStyle ] ]
            [ div [ S.class "calendar" ]
                [ div [ S.class "calendar-header" ]
                    [ viewModeControls
                    , viewControls
                    ]
                , viewCalendar
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



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    let
        ( mouseMoves, mouseUps ) =
            case model.draggingEventId of
                Just id ->
                    ( Mouse.moves <| DragEvent id, Mouse.ups <| StopEventDrag id )

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


decodeQuarter : String -> Result String ( String, String )
decodeQuarter =
    Decode.map2 (,)
        (Decode.field "eventId" Decode.string)
        (Decode.field "quarter" Decode.string)
        |> Decode.decodeString
