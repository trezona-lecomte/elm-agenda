module Main exposing (main)

import Calendar
import Calendar.EventHelpers as Calendar
import Calendar.Types as Calendar
import Calendar.Config as Calendar
import Date exposing (Date)
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
            Calendar.init Calendar.Daily eventMapping []
    in
        { calendarModel = calendarModel
        , events = []
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
    | MoveEvent String Date
    | ExtendEvent String Date
    | RemoveEvent String


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UpdateCalendar calendarMsg ->
            let
                ( updatedCalendar, calendarCmd, maybeMsg ) =
                    Calendar.update calendarConfig calendarMsg model.calendarModel

                updatedModel =
                    handleCalendarUpdate maybeMsg { model | calendarModel = updatedCalendar }
            in
                -- Wrap all calendar cmds in our Msg type so we can send
                -- them to the Elm Runtime as if they were our own cmds.
                updatedModel ! [ Cmd.map UpdateCalendar calendarCmd ]

        NoOp ->
            model ! []


handleCalendarUpdate : Maybe CalendarMsg -> Model -> Model
handleCalendarUpdate msg model =
    case msg of
        Just (CreateEvent protoEvent) ->
            case createEvent model protoEvent of
                Ok event ->
                    let
                        ( updatedCalendarModel, updatedEvents ) =
                            Calendar.addEvent event model.calendarModel model.events
                    in
                        { model | events = updatedEvents, calendarModel = updatedCalendarModel }

                Err error ->
                    { model | errors = error :: model.errors }

        Just (MoveEvent id newStart) ->
            let
                ( updatedCalendarModel, updatedEvents ) =
                    Calendar.moveEvent id newStart model.calendarModel model.events
            in
                { model | events = updatedEvents, calendarModel = updatedCalendarModel }

        Just (ExtendEvent id newFinish) ->
            let
                ( updatedCalendarModel, updatedEvents ) =
                    Calendar.extendEvent id newFinish model.calendarModel model.events
            in
                { model | events = updatedEvents, calendarModel = updatedCalendarModel }

        Just (RemoveEvent eventId) ->
            let
                ( updatedCalendarModel, updatedEvents ) =
                    Calendar.removeEvent eventId model.calendarModel model.events
            in
                { model | events = updatedEvents, calendarModel = updatedCalendarModel }

        Nothing ->
            model


createEvent : Model -> Calendar.ProtoEvent -> Result String Event
createEvent model { start, finish, label } =
    List.map (\e -> String.toInt e.id) model.events
        |> Result.combine
        |> Result.andThen (List.maximum >> Result.fromMaybe "" >> Result.map (\id -> id + 1))
        |> Result.withDefault 1
        |> validateEvent start finish label


validateEvent : Date -> Date -> String -> Int -> Result String Event
validateEvent start finish label id =
    Ok
        { id = toString id
        , start = start
        , finish = finish
        , label = label
        }



-- VIEW


view : Model -> Html Msg
view { calendarModel } =
    div [ class "section" ]
        -- Wrap all msgs from the calendar view in our Msg type so we
        -- can pass them on with our own msgs to the Elm Runtime.
        [ Html.map UpdateCalendar (Calendar.view calendarModel) ]



-- CALENDAR CONFIGURATION


eventMapping : Calendar.EventMapping Event
eventMapping =
    { id = .id
    , start = .start
    , finish = .finish
    , label = .label
    }


calendarConfig : Calendar.Config Event CalendarMsg
calendarConfig =
    { -- Your EventMapping defines functions to access the fields of your Event
      -- type. Usually these will be your record field accessor functions.
      eventMapping = eventMapping
    , createEvent =
        \protoEvent ->
            CreateEvent protoEvent |> Just

    -- These functions let you hook into the Calendar msgs that can be emitted.
    , moveEvent =
        \id newStart ->
            MoveEvent id newStart |> Just
    , extendEvent =
        \id newFinish ->
            ExtendEvent id newFinish |> Just
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
