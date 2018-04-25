module View.Daily exposing (..)

import Calendar.Types exposing (..)
import Date exposing (Date)
import Date.Extra as Date
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (on, onClick, onMouseOver)
import Json.Decode
import Labels
import Mouse
import Style as S


paginationControls : Model -> ( Msg, Msg, Msg ) -> Html Msg
paginationControls { selectedDate } ( todayMsg, prevMsg, nextMsg ) =
    div [ S.class "pagination-controls" ]
        [ simpleButton Labels.todayButton todayMsg
        , simpleButton Labels.previousPageButton prevMsg
        , currentDate selectedDate
        , simpleButton Labels.nextPageButton nextMsg
        ]


currentDate : Date -> Html Msg
currentDate date =
    div
        [ S.class "current-date is-size-6" ]
        [ text <| Date.toFormattedString "EE MMM d y" date ]


simpleButton : String -> Msg -> Html Msg
simpleButton label msg =
    button [ class "button", onClick msg ] [ text label ]


calendar : Model -> List ProtoEvent -> Html Msg
calendar { activeMode, selectedDate, draggingProtoEvent } events =
    let
        eventsOnSelectedDate =
            List.filter
                (\e -> Date.equalBy Date.Day e.start selectedDate)
                events
    in
        div [ S.class "day-calendar" ]
            [ div [ S.class "hours-column" ]
                (hoursHeader :: List.map hourItem hours)
            , div [ S.class "schedule-column" ]
                (scheduleHeader activeMode
                    :: List.map quarterHourItem quarterHours
                    ++ List.map (eventItem draggingProtoEvent) eventsOnSelectedDate
                )
            ]


hoursHeader : Html Msg
hoursHeader =
    div [ S.class "hours-header" ] [ text "Time" ]


scheduleHeader : Mode -> Html Msg
scheduleHeader mode =
    div [ S.class "schedule-header" ] [ text <| toString mode ++ " Schedule" ]


hourItem : String -> Html Msg
hourItem hour =
    div [ S.class "hours-item" ] [ text hour ]


quarterHourItem : Int -> Html Msg
quarterHourItem quarter =
    div
        [ S.class <| "schedule-quarter-hour-item"
        , id <| "quarter-" ++ toString quarter
        , style
            [ ( "grid-row", toString <| quarter + 1 )
            , ( "grid-column", "1" )
            ]
        ]
        []


eventItem : Maybe ProtoEvent -> ProtoEvent -> Html Msg
eventItem draggingProtoEvent protoEvent =
    let
        shadowIfInteracting =
            case draggingProtoEvent of
                Just _ ->
                    ( "box-shadow", "2px 2px 1px 1px rgb(200, 200, 200)" )

                Nothing ->
                    ( "", "" )

        removeButtonIfPersisted =
            case protoEvent.id of
                Nothing ->
                    div [] []

                Just id ->
                    div [ S.class "schedule-event-remove-button" ]
                        [ a [ S.class "schedule-event-remove-link icon is-small", onClick <| RemoveEvent id ]
                            [ i [ class "fas fa-times" ] [] ]
                        ]
    in
        div
            [ S.class "schedule-event-item"
            , style
                [ gridRowForEvent ( protoEvent.start, protoEvent.finish )
                , ( "grid-column", "1" )
                , shadowIfInteracting
                ]
            ]
            -- TODO: Gracefully handle a very long event name.
            [ div [ S.class "schedule-event-content is-size-7" ]
                [ div [ S.class "schedule-event-summary" ] [ text <| protoEvent.label ]
                , div [ S.class "schedule-event-time" ]
                    [ text <|
                        String.join
                            " - "
                            (List.map toShortTime [ protoEvent.start, protoEvent.finish ])
                    ]
                , removeButtonIfPersisted
                ]
            , eventMoveHandle draggingProtoEvent protoEvent
            , eventExtendHandle draggingProtoEvent protoEvent
            ]


toShortTime : Date -> String
toShortTime =
    Date.toFormattedString "h:mm a"


eventMoveHandle : Maybe ProtoEvent -> ProtoEvent -> Html Msg
eventMoveHandle draggingProtoEvent event =
    let
        cursor =
            case draggingProtoEvent of
                Just _ ->
                    "grabbing"

                Nothing ->
                    "grab"
    in
        div
            [ S.class <| "schedule-event-move-handle"
            , style [ ( "cursor", cursor ) ]
            , on "mousedown" <|
                Json.Decode.map
                    (StartEventDrag Move event)
                    Mouse.position
            ]
            []


eventExtendHandle : Maybe ProtoEvent -> ProtoEvent -> Html Msg
eventExtendHandle draggingProtoEvent event =
    let
        cursor =
            case draggingProtoEvent of
                Just _ ->
                    "grabbing"

                Nothing ->
                    "ns-resize"
    in
        div
            [ S.class <| "schedule-event-extend-handle"
            , style [ ( "cursor", cursor ) ]
            , on "mousedown" <|
                Json.Decode.map
                    (StartEventDrag Extend event)
                    Mouse.position
            ]
            []


eventToProtoEvent : { id : String, start : Date, finish : Date, label : String } -> ProtoEvent
eventToProtoEvent { id, start, finish, label } =
    { id = Just id
    , start = start
    , finish = finish
    , label = label
    }



-- TODO: Test the gridRowForEvent logic!


gridRowForEvent : ( Date, Date ) -> ( String, String )
gridRowForEvent ( start, finish ) =
    let
        startHour =
            start
                |> Date.hour

        finishHour =
            finish
                |> Date.hour

        startQuarterHour =
            start
                |> Date.minute
                |> nearestQuarterHour

        finishQuarterHour =
            finish
                |> Date.minute
                |> nearestQuarterHour

        gridRowStart =
            startHour
                |> (*) 4
                |> (+) startQuarterHour
                |> toString

        gridRowFinish =
            finishHour
                |> (*) 4
                |> (+) finishQuarterHour
                |> toString
    in
        ( "grid-row", gridRowStart ++ " / " ++ gridRowFinish )


nearestQuarterHour : Int -> Int
nearestQuarterHour minute =
    if minute < 7 then
        0
    else if minute < 22 then
        1
    else if minute < 37 then
        2
    else if minute < 52 then
        3
    else
        4


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


quarterHours : List Int
quarterHours =
    List.range 1 96
