module View.Daily exposing (calendar, paginationControls)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Labels
import Style


calendar : Html msg
calendar =
    div [ class Style.dayCalendarClass ]
        [ div [ class Style.hoursColumnClass ]
            (text "Time" :: List.map viewHour hours)
        , div [ class Style.scheduleColumnClass ] [ text "Schedule" ]
        ]


viewHour : String -> Html msg
viewHour hour =
    div [] [ text hour ]


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


paginationControls : ( msg, msg ) -> Html msg
paginationControls ( prevMsg, nextMsg ) =
    div [ class Style.paginationControlsClass ]
        [ paginateButton Labels.previousPageButton prevMsg
        , paginateButton Labels.nextPageButton nextMsg
        ]


paginateButton : String -> msg -> Html msg
paginateButton label msg =
    button [ class Style.buttonClass, onClick msg ] [ text label ]
