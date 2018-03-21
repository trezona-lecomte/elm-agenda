module Main exposing (main)

import Date exposing (Date)
import Date.Extra as Date
import Html exposing (..)
import Calendar


main : Program Never Model Msg
main =
    Html.beginnerProgram
        { model = model
        , update = update
        , view = view
        }


type alias Model =
    { calendarModel : Calendar.Model
    }


type alias Event =
    { id : String
    , start : Date
    , end : Date
    , label : String
    }


model : Model
model =
    let
        arbitraryDate =
            Date.fromParts 2018 Date.Mar 22 10 0 0 0
    in
        { calendarModel =
            Calendar.init Calendar.Daily arbitraryDate
        }


type Msg
    = UpdateCalendar Calendar.Msg
    | SelectDate Date


update : Msg -> Model -> Model
update msg model =
    case msg of
        UpdateCalendar calendarMsg ->
            let
                ( updatedCalendar, maybeMsg ) =
                    Calendar.update calendarMsg model.calendarModel

                newModel =
                    { model | calendarModel = updatedCalendar }
            in
                case maybeMsg of
                    Nothing ->
                        newModel

                    Just updateMsg ->
                        update updateMsg newModel

        SelectDate date ->
            model


view : Model -> Html Msg
view model =
    div []
        -- Wrap all msgs from the calendar view in our Msg type so we
        -- can pass them on with our own msgs to the Elm Runtime.
        [ Html.map UpdateCalendar (Calendar.view model.calendarModel) ]



-- This is one way we could handle supporting custom event types
-- viewConfig : Calendar.ViewConfig Event
-- eventConfig : Calendar.EventConfig Msg
-- timeSlotConfig : Calendar.TimeSlotConfig Msg
