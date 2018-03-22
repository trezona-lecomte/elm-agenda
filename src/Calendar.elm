module Calendar exposing (Mode(..), Msg, Model, init, update, view, subscriptions)

import Config exposing (EventConfig)
import Date exposing (Date)
import Date.Extra as Date
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Labels
import Style as S
import Task
import View.Daily


-- MODEL


type alias Model =
    { activeMode : Mode
    , currentDate : Date
    }


type Mode
    = Daily


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
    , currentDate = date
    }



-- UPDATE


type Msg
    = ChangeMode Mode
    | SetDate Date
    | Today
    | Previous
    | Next


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ChangeMode mode ->
            { model | activeMode = mode } ! []

        SetDate date ->
            { model | currentDate = date } ! []

        Today ->
            ( model, Task.perform SetDate Date.now )

        Previous ->
            { model | currentDate = Date.add Date.Day -1 model.currentDate } ! []

        Next ->
            { model | currentDate = Date.add Date.Day 1 model.currentDate } ! []



-- VIEW


view : EventConfig event -> List event -> Model -> Html Msg
view config events { activeMode, currentDate } =
    let
        ( viewControls, viewCalendar ) =
            case activeMode of
                Daily ->
                    ( View.Daily.paginationControls currentDate ( Today, Previous, Next )
                    , View.Daily.calendar config events
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
    Sub.none
