module Calendar.EventHelpers exposing (addEvent, removeEvent, moveEvent, extendEvent, virtualiseEvents)

import Date exposing (Date)
import Date.Extra as Date
import Calendar.Types exposing (Event, Model, ProtoEvent)
import List.Extra as List


addEvent : Event e -> Model -> List (Event e) -> ( Model, List (Event e) )
addEvent event model events =
    (event :: events)
        |> syncEvents model


removeEvent : String -> Model -> List (Event e) -> ( Model, List (Event e) )
removeEvent id model events =
    List.filter (\e -> e.id /= id) events
        |> syncEvents model


moveEvent : String -> Date -> Model -> List (Event e) -> ( Model, List (Event e) )
moveEvent id newStart model events =
    List.updateIf (\e -> e.id == id) (updateEventStart newStart) events
        |> syncEvents model


extendEvent : String -> Date -> Model -> List (Event e) -> ( Model, List (Event e) )
extendEvent id newFinish model events =
    List.updateIf (\e -> e.id == id) (updateEventFinish newFinish) events
        |> syncEvents model


syncEvents : Model -> List (Event e) -> ( Model, List (Event e) )
syncEvents model events =
    ( { model | virtualEvents = virtualiseEvents events }, events )


virtualiseEvents : List (Event e) -> List ProtoEvent
virtualiseEvents =
    let
        virtualise event =
            { id = Just <| event.id
            , start = event.start
            , finish = event.finish
            , label = event.label
            }
    in
        List.map virtualise


updateEventStart : Date -> Event e -> Event e
updateEventStart newStart event =
    let
        offset =
            Date.diff Date.Minute (event.start) newStart

        newFinish =
            Date.add Date.Minute offset event.finish
    in
        { event | start = newStart, finish = newFinish }


updateEventFinish : Date -> Event e -> Event e
updateEventFinish newFinish event =
    if (Date.diff Date.Minute event.start newFinish) > 0 then
        { event | finish = newFinish }
    else
        event
