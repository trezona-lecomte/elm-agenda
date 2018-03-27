module View.Daily exposing (..)

import Calendar.Config exposing (Config, EventMapping)
import Calendar.Types exposing (Model, Mode, Msg(..), DragMode(..))
import Date exposing (Date)
import Date.Extra as Date
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (on, onClick, onMouseOver)
import Json.Decode
import Labels
import Mouse
import Style as S


paginationControls : Model -> ( Msg, Msg, Msg ) -> Html Msg
paginationControls { selectedDate } ( todayMsg, prevMsg, nextMsg ) =
    div [ S.class "pagination-controls" ]
        [ simpleButton Labels.todayButton todayMsg
        , simpleButton Labels.previousPageButton prevMsg
        , currentDate selectedDate
        , simpleButton Labels.nextPageButton nextMsg
        ]


currentDate : Date -> Html Msg
currentDate date =
    div
        [ S.class "current-date is-size-6" ]
        [ text <| Date.toFormattedString "EE MMM d y" date ]


simpleButton : String -> Msg -> Html Msg
simpleButton label msg =
    button [ class "button", onClick msg ] [ text label ]


calendar : Config event msg -> Model -> List event -> Html Msg
calendar { eventMapping } { activeMode, selectedDate, draggingEventId } events =
    let
        eventsOnSelectedDate =
            List.filter
                (\e -> Date.equalBy Date.Day (eventMapping.start e) selectedDate)
                events
    in
        div [ S.class "day-calendar" ]
            [ div [ S.class "hours-column" ]
                (hoursHeader :: List.map hourItem hours)
            , div [ S.class "schedule-column" ]
                (scheduleHeader activeMode
                    :: List.map quarterHourItem quarterHours
                    ++ List.map (eventItem draggingEventId eventMapping) eventsOnSelectedDate
                )
            ]


hoursHeader : Html Msg
hoursHeader =
    div [ S.class "hours-header" ] [ text "Time" ]


scheduleHeader : Mode -> Html Msg
scheduleHeader mode =
    div [ S.class "schedule-header" ] [ text <| toString mode ++ " Schedule" ]


hourItem : String -> Html Msg
hourItem hour =
    div [ S.class "hours-item" ] [ text hour ]


quarterHourItem : Int -> Html Msg
quarterHourItem quarter =
    div
        [ S.class <| "schedule-quarter-hour-item"
        , id <| "quarter-" ++ toString quarter
        , style
            [ ( "grid-row", toString <| quarter + 1 )
            , ( "grid-column", "1" )
            ]
        ]
        []


eventItem : Maybe String -> EventMapping event -> event -> Html Msg
eventItem draggingEventId { id, start, finish, label } event =
    let
        shadowIfInteracting =
            case draggingEventId of
                Just _ ->
                    ( "box-shadow", "2px 2px 1px 1px rgb(200, 200, 200)" )

                Nothing ->
                    ( "", "" )
    in
        div
            [ S.class "schedule-event-item"
            , style
                [ gridRowForEvent ( start event, finish event )
                , ( "grid-column", "1" )
                , shadowIfInteracting
                ]
            ]
            [ div [ S.class "schedule-event-label is-size-7" ]
                [ div [ S.class "schedule-event-label-text" ] [ text <| label event ]
                , div [ S.class "schedule-event-time" ]
                    [ text <|
                        String.join
                            " - "
                            (List.map toShortTime [ start event, finish event ])
                    ]
                , div [ S.class "schedule-event-remove-button" ]
                    [ button [ onClick <| RemoveEvent <| id event ] [ text "X" ]
                    ]
                ]
            , eventMoveHandle draggingEventId <| id event
            , eventExtendHandle draggingEventId <| id event
            ]


toShortTime : Date -> String
toShortTime =
    Date.toFormattedString "h:mm a"


eventMoveHandle : Maybe String -> String -> Html Msg
eventMoveHandle draggingEventId eventId =
    let
        cursor =
            case draggingEventId of
                Just _ ->
                    "grabbing"

                Nothing ->
                    "grab"
    in
        div
            [ S.class <| "schedule-event-move-handle"
            , style [ ( "cursor", cursor ) ]
            , on "mousedown" <| Json.Decode.map (StartEventDrag Move eventId) Mouse.position
            ]
            []


eventExtendHandle : Maybe String -> String -> Html Msg
eventExtendHandle draggingEventId eventId =
    let
        cursor =
            case draggingEventId of
                Just _ ->
                    "grabbing"

                Nothing ->
                    "ns-resize"
    in
        div
            [ S.class <| "schedule-event-extend-handle"
            , style [ ( "cursor", cursor ) ]
            , on "mousedown" <| Json.Decode.map (StartEventDrag Extend eventId) Mouse.position
            ]
            []



-- TODO: Test the gridRowForEvent logic!


gridRowForEvent : ( Date, Date ) -> ( String, String )
gridRowForEvent ( start, finish ) =
    let
        startHour =
            start
                |> Date.hour

        finishHour =
            finish
                |> Date.hour

        startQuarterHour =
            start
                |> Date.minute
                |> nearestQuarterHour

        finishQuarterHour =
            finish
                |> Date.minute
                |> nearestQuarterHour

        gridRowStart =
            startHour
                |> (*) 4
                |> (+) startQuarterHour
                |> toString

        gridRowFinish =
            finishHour
                |> (*) 4
                |> (+) finishQuarterHour
                |> toString
    in
        ( "grid-row", gridRowStart ++ " / " ++ gridRowFinish )


nearestQuarterHour : Int -> Int
nearestQuarterHour minute =
    if minute < 7 then
        0
    else if minute < 22 then
        1
    else if minute < 37 then
        2
    else if minute < 52 then
        3
    else
        4


hours : List String
hours =
    [ "1am"
    , "2am"
    , "3am"
    , "4am"
    , "5am"
    , "6am"
    , "7am"
    , "8am"
    , "9am"
    , "10am"
    , "11am"
    , "12am"
    , "1pm"
    , "2pm"
    , "3pm"
    , "4pm"
    , "5pm"
    , "6pm"
    , "7pm"
    , "8pm"
    , "9pm"
    , "10pm"
    , "11pm"
    , "12pm"
    ]


quarterHours : List Int
quarterHours =
    List.range 1 96
