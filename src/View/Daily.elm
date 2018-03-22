module View.Daily exposing (calendar, controls)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Labels
import Style


calendar : Html msg
calendar =
    div [] []


controls : ( msg, msg ) -> Html msg
controls paginationMsgs =
    div [ class Style.controlsClass ]
        [ paginationControls paginationMsgs
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
