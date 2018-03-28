module Main exposing (main)

import Calendar
import Calendar.Types as Calendar
import Calendar.Config as Calendar
import Date exposing (Date)
import Date.Extra as Date
import Html exposing (..)
import Html.Attributes exposing (class)
import Result.Extra as Result


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
    , errors : List String
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
        ( calendarModel, calendarCmd ) =
            Calendar.init Calendar.Daily

        events =
            -- []
            -- TODO: Move fixture data to a dedicated module
            [ { id = "1"
              , start = Date.fromParts 2018 Date.Mar 27 1 0 0 0
              , finish = Date.fromParts 2018 Date.Mar 27 1 45 0 0
              , label = "Abstract out some crisp encapsulations"
              }
            ]

        -- , { id = "2"
        --   , start = Date.fromParts 2018 Date.Mar 26 11 30 0 0
        --   , finish = Date.fromParts 2018 Date.Mar 26 12 0 0 0
        --   , label = "Yell at fools on the internet"
        --   }
        -- ]
    in
        { calendarModel = calendarModel
        , events = events
        , errors = []
        }
            ! [ Cmd.map UpdateCalendar calendarCmd ]



-- UPDATE


type Msg
    = UpdateCalendar Calendar.Msg
    | NoOp



-- While not strictly necessary, it's nice to represent any Msg values related
-- to the Calendar in their own type.


type CalendarMsg
    = CreateEvent Calendar.ProtoEvent
    | UpdateEventStart Calendar.ProtoEvent
    | UpdateEventFinish Calendar.ProtoEvent
    | RemoveEvent String


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UpdateCalendar calendarMsg ->
            let
                ( updatedCalendar, calendarCmd, maybeMsg ) =
                    Calendar.update calendarConfig calendarMsg model.calendarModel

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
        Just (CreateEvent protoEvent) ->
            case createEvent model protoEvent of
                Ok event ->
                    { model | events = event :: model.events }

                Err error ->
                    { model | errors = error :: model.errors }

        Just (UpdateEventStart protoEvent) ->
            { model | events = List.map (changeEventStart protoEvent) model.events }

        Just (UpdateEventFinish protoEvent) ->
            { model | events = List.map (changeEventFinish protoEvent) model.events }

        Just (RemoveEvent eventId) ->
            { model | events = List.filter (\e -> e.id /= eventId) model.events }

        Nothing ->
            model


createEvent : Model -> Calendar.ProtoEvent -> Result String Event
createEvent model { start, finish, label } =
    List.map (\e -> String.toInt e.id) model.events
        |> Result.combine
        |> Result.andThen (List.maximum >> Result.fromMaybe "")
        |> Result.withDefault 0
        |> validateEvent start finish label


validateEvent : Date -> Date -> String -> Int -> Result String Event
validateEvent start finish label id =
    Ok
        { id = toString id
        , start = start
        , finish = finish
        , label = label
        }



-- TODO: Can the event update logic live in the library somewhere?


changeEventStart : Calendar.ProtoEvent -> Event -> Event
changeEventStart { id, start, finish, label } event =
    case id of
        Just eventId ->
            if event.id == eventId then
                let
                    offset =
                        Date.diff Date.Minute event.start start

                    newFinish =
                        Date.add Date.Minute offset event.finish
                in
                    { event | start = start, finish = newFinish }
            else
                event

        Nothing ->
            event


changeEventFinish : Calendar.ProtoEvent -> Event -> Event
changeEventFinish { id, start, finish, label } event =
    case id of
        Just eventId ->
            if event.id == eventId && (Date.diff Date.Minute event.start finish) > 0 then
                { event | finish = finish }
            else
                event

        Nothing ->
            event



-- VIEW


view : Model -> Html Msg
view { calendarModel, events } =
    div [ class "section" ]
        -- Wrap all msgs from the calendar view in our Msg type so we
        -- can pass them on with our own msgs to the Elm Runtime.
        [ Html.map UpdateCalendar (Calendar.view calendarConfig calendarModel events) ]



-- CALENDAR CONFIGURATION


calendarConfig : Calendar.Config Event CalendarMsg
calendarConfig =
    { -- Your EventMapping defines functions to access the fields of your Event
      -- type. Usually these will be your record field accessor functions.
      eventMapping =
        { id = .id
        , start = .start
        , finish = .finish
        , label = .label
        }
    , createEvent =
        \protoEvent ->
            CreateEvent protoEvent |> Just

    -- These functions let you hook into the Calendar msgs that can be emitted.
    , updateEventStart =
        \protoEvent ->
            UpdateEventStart protoEvent |> Just
    , updateEventFinish =
        \protoEvent ->
            UpdateEventFinish protoEvent |> Just
    , removeEvent =
        \eventId ->
            RemoveEvent eventId |> Just
    }



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        -- Batch together the Calendar subscriptions along with your own.
        [ Calendar.subscriptions model.calendarModel
            |> Sub.map UpdateCalendar
        ]
