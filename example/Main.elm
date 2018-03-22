module Main exposing (main)

import Date exposing (Date)
import Date.Extra as Date
import Html exposing (..)
import Html.Attributes exposing (class)
import Calendar
import Config exposing (EventConfig)


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }



-- MODEL


type alias Model =
    { calendarModel : Calendar.Model
    , events : List Event
    }


type alias Event =
    { id : String
    , start : Date
    , finish : Date
    , label : String
    }


init : ( Model, Cmd Msg )
init =
    let
        arbitraryDate =
            Date.fromParts 2018 Date.Mar 23 10 0 0 0

        events =
            [ { id = "1"
              , start = Date.fromParts 2018 Date.Mar 23 10 0 0 0
              , finish = Date.fromParts 2018 Date.Mar 23 11 0 0 0
              , label = "Abstract out some crisp encapsulations"
              }
            , { id = "2"
              , start = Date.fromParts 2018 Date.Mar 23 13 30 0 0
              , finish = Date.fromParts 2018 Date.Mar 23 14 15 0 0
              , label = "Yell at fools on the internet"
              }
            ]
    in
        { calendarModel =
            Calendar.init Calendar.Daily arbitraryDate
        , events = events
        }
            ! []



-- UPDATE


type Msg
    = UpdateCalendar Calendar.Msg
    | SelectDate Date


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UpdateCalendar calendarMsg ->
            let
                ( updatedCalendar, calendarCmd ) =
                    Calendar.update calendarMsg model.calendarModel

                newModel =
                    { model | calendarModel = updatedCalendar }
            in
                -- Wrap all calendar cmds in our Msg type so we can send
                -- them to the Elm Runtime as if they were our own cmds.
                newModel ! [ Cmd.map UpdateCalendar calendarCmd ]

        SelectDate date ->
            model ! []



-- VIEW


view : Model -> Html Msg
view { calendarModel, events } =
    div [ class "section" ]
        -- Wrap all msgs from the calendar view in our Msg type so we
        -- can pass them on with our own msgs to the Elm Runtime.
        [ Html.map UpdateCalendar (Calendar.view eventConfig events calendarModel) ]



-- CONFIG


eventConfig : EventConfig Event
eventConfig =
    { id = .id
    , start = .start
    , finish = .finish
    , label = .label
    }



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Calendar.subscriptions model.calendarModel
            |> Sub.map UpdateCalendar
        ]
