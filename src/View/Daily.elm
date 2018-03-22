module View.Daily exposing (calendar, paginationControls)

import Config exposing (EventConfig)
import Date exposing (Date)
import Date.Extra as Date
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Labels
import Style as S


paginationControls : Date -> ( msg, msg, msg ) -> Html msg
paginationControls date ( todayMsg, prevMsg, nextMsg ) =
    div [ S.class "pagination-controls" ]
        [ viewButton Labels.todayButton todayMsg
        , viewButton Labels.previousPageButton prevMsg
        , viewCurrentDate date
        , viewButton Labels.nextPageButton nextMsg
        ]


viewCurrentDate : Date -> Html msg
viewCurrentDate date =
    div [ S.class "current-date is-size-6" ]
        [ text <| Date.toFormattedString "EE MMMM d y" date ]


viewButton : String -> msg -> Html msg
viewButton label msg =
    button [ class "button", onClick msg ] [ text label ]


calendar : EventConfig event -> List event -> Html msg
calendar config events =
    div [ S.class "day-calendar" ]
        [ div [ S.class "hours-column" ]
            (viewHoursHeader :: List.map viewHour hours)
        , div [ S.class "schedule-column" ]
            (viewScheduleHeader
                :: List.map viewHourInSchedule hours
                ++ List.map (viewEvent config) events
            )
        ]


viewHoursHeader : Html msg
viewHoursHeader =
    div [ S.class "hours-header" ] [ text "Time" ]


viewScheduleHeader : Html msg
viewScheduleHeader =
    div [ S.class "schedule-header" ] [ text "Schedule" ]


viewHour : String -> Html msg
viewHour hour =
    div [ S.class "hours-item" ] [ text hour ]


viewHourInSchedule : String -> Html msg
viewHourInSchedule _ =
    div [ S.class "schedule-item" ] []


viewEvent : EventConfig event -> event -> Html msg
viewEvent config event =
    div
        [ S.class "schedule-event-item"
        , style [ gridRowForEvent ( config.start event, config.finish event ) ]
        ]
        [ text <| config.label event ]


gridRowForEvent : ( Date, Date ) -> ( String, String )
gridRowForEvent ( start, finish ) =
    let
        gridRowStart =
            start
                |> Date.hour
                |> (+) 1
                |> toString

        gridRowFinish =
            finish
                |> Date.hour
                |> (+) 1
                |> toString
    in
        ( "grid-row", gridRowStart ++ " / " ++ gridRowFinish )


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
