module Main exposing (main)

import Date exposing (Date)
import Date.Extra as Date
import Html exposing (..)
import Html.Attributes exposing (class)
import Calendar


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
    }


type alias Event =
    { id : String
    , start : Date
    , end : Date
    , label : String
    }


init : ( Model, Cmd Msg )
init =
    let
        arbitraryDate =
            Date.fromParts 2018 Date.Mar 22 10 0 0 0
    in
        { calendarModel =
            Calendar.init Calendar.Daily arbitraryDate
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
                newModel ! [ Cmd.map UpdateCalendar calendarCmd ]

        SelectDate date ->
            model ! []



-- VIEW


view : Model -> Html Msg
view model =
    div [ class "section" ]
        -- Wrap all msgs from the calendar view in our Msg type so we
        -- can pass them on with our own msgs to the Elm Runtime.
        [ Html.map UpdateCalendar (Calendar.view model.calendarModel) ]



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Calendar.subscriptions model.calendarModel
            |> Sub.map UpdateCalendar
        ]



-- This is one way we could handle supporting custom event types
-- viewConfig : Calendar.ViewConfig Event
-- eventConfig : Calendar.EventConfig Msg
-- timeSlotConfig : Calendar.TimeSlotConfig Msg
