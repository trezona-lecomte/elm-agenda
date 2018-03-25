module Main exposing (main)

import Date exposing (Date)
import Date.Extra as Date
import Html exposing (..)
import Html.Attributes exposing (class)
import Calendar
import Calendar.Types as Calendar
import Config exposing (CalendarConfig, EventConfig)


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
        -- TODO: Default to today's date rather than this one.
        arbitraryDate =
            Date.fromParts 2018 Date.Mar 23 10 0 0 0

        events =
            -- TODO: Move fixture data to a dedicated module
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
        { calendarModel = Calendar.init Calendar.Daily arbitraryDate
        , events = events
        }
            ! []



-- UPDATE


type Msg
    = UpdateCalendar Calendar.Msg
    | NoOp



-- While not strictly necessary, it's nice to represent any Msg values related
-- to the Calendar in their own type.


type CalendarMsg
    = ChangeEventStart String Date
    | ChangeEventFinish String Date


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UpdateCalendar calendarMsg ->
            let
                ( updatedCalendar, calendarCmd, maybeMsg ) =
                    Calendar.update calendarConfig eventConfig calendarMsg model.calendarModel

                newModel =
                    { model | calendarModel = updatedCalendar }
            in
                -- Wrap all calendar cmds in our Msg type so we can send
                -- them to the Elm Runtime as if they were our own cmds.
                handleCalendarUpdate maybeMsg newModel ! [ Cmd.map UpdateCalendar calendarCmd ]

        NoOp ->
            model ! []


handleCalendarUpdate : Maybe CalendarMsg -> Model -> Model
handleCalendarUpdate msg model =
    case msg of
        Just (ChangeEventStart eventId newStart) ->
            { model | events = List.map (changeEventStart eventId newStart) model.events }

        Just (ChangeEventFinish eventId newFinish) ->
            { model | events = List.map (changeEventFinish eventId newFinish) model.events }

        Nothing ->
            model



-- TODO: Can the event update logic live in the library somewhere?


changeEventStart : String -> Date -> Event -> Event
changeEventStart id newDate event =
    if event.id == id then
        let
            offset =
                Date.diff Date.Minute event.start newDate

            newFinish =
                Date.add Date.Minute offset event.finish
        in
            { event | start = newDate, finish = newFinish }
    else
        event


changeEventFinish : String -> Date -> Event -> Event
changeEventFinish id newDate event =
    if event.id == id && (Date.diff Date.Minute event.start newDate) > 0 then
        { event | finish = newDate }
    else
        event



-- VIEW


view : Model -> Html Msg
view { calendarModel, events } =
    div [ class "section" ]
        -- Wrap all msgs from the calendar view in our Msg type so we
        -- can pass them on with our own msgs to the Elm Runtime.
        [ Html.map UpdateCalendar (Calendar.view calendarModel calendarConfig eventConfig events calendarModel) ]



-- CALENDAR CONFIGURATION


calendarConfig : CalendarConfig CalendarMsg
calendarConfig =
    -- CalendarConfig is where you define handler functions for the various
    -- events that the calendar can emit.
    { moveEvent = \eventId newStart -> Just <| ChangeEventStart eventId newStart
    , extendEvent = \eventId newFinish -> Just <| ChangeEventFinish eventId newFinish
    }


eventConfig : EventConfig Event
eventConfig =
    -- EventConfig defines functions to access the required fields of your Event
    -- type. Normally these will be record field accessor functions.
    { id = .id
    , start = .start
    , finish = .finish
    , label = .label
    }



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        -- Batch together the Calendar subscriptions along with your own.
        [ Calendar.subscriptions model.calendarModel
            |> Sub.map UpdateCalendar
        ]
