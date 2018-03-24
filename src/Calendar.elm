module Calendar exposing (Model, init, update, view, subscriptions)

import Config exposing (CalendarConfig, EventConfig)
import Date exposing (Date)
import Date.Extra as Date
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Labels
import Mouse
import Style as S
import Calendar.Types exposing (Mode(..), Msg(..))
import Task
import View.Daily


-- MODEL


type alias Model =
    { activeMode : Mode
    , selectedDate : Date
    , draggingEventId : Maybe String
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
            ( { model | selectedDate = Date.add Date.Day -1 model.selectedDate }, Cmd.none, Nothing )

        Next ->
            ( { model | selectedDate = Date.add Date.Day 1 model.selectedDate }, Cmd.none, Nothing )

        StartEventDrag eventId mousePosition ->
            ( { model | draggingEventId = Just eventId }, Cmd.none, calendarConfig.startEventDrag eventId mousePosition )

        StopEventDrag eventId mousePosition ->
            ( { model | draggingEventId = Nothing }, Cmd.none, calendarConfig.changeEventFinish eventId (dateFromMousePosition model mousePosition) )


dateFromMousePosition : Model -> Mouse.Position -> Date
dateFromMousePosition { selectedDate } position =
    let
        newDate =
            selectedDate
    in
        selectedDate



-- VIEW


view : CalendarConfig msg -> EventConfig event -> List event -> Model -> Html Msg
view calendarConfig eventConfig events { activeMode, selectedDate } =
    let
        ( viewControls, viewCalendar ) =
            case activeMode of
                Daily ->
                    ( View.Daily.paginationControls selectedDate ( Today, Previous, Next )
                    , View.Daily.calendar selectedDate calendarConfig eventConfig events
                    )
    in
        div [ class "container" ]
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
    case model.draggingEventId of
        Just id ->
            Mouse.ups (StopEventDrag id)

        Nothing ->
            Sub.none
