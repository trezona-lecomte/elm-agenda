module Calendar exposing (Mode(..), Msg, Model, init, update, view, subscriptions)

import Date exposing (Date)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Labels
import Style as S
import View.Daily


-- MODEL


type alias Model =
    { activeMode : Mode
    , currentDate : Date
    }


type Mode
    = Daily


modes : List Mode
modes =
    [ Daily ]


init : Mode -> Date -> Model
init mode date =
    { activeMode = mode
    , currentDate = date
    }



-- UPDATE


type Msg
    = ChangeMode Mode
    | PreviousPage
    | NextPage


update : Msg -> Model -> ( Model, Maybe msg )
update msg model =
    case msg of
        ChangeMode mode ->
            ( { model | activeMode = mode }, Nothing )

        PreviousPage ->
            ( model, Nothing )

        NextPage ->
            ( model, Nothing )



-- VIEW


view : Model -> Html Msg
view { activeMode } =
    let
        ( viewControls, viewCalendar ) =
            case activeMode of
                Daily ->
                    ( View.Daily.paginationControls ( PreviousPage, NextPage ), View.Daily.calendar )
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
    Sub.none
