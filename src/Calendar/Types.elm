module Calendar.Types exposing (..)

import Date exposing (Date)
import Date.Extra as Date
import Mouse


type alias Model =
    { activeMode : Mode
    , selectedDate : Date
    , draggingEventId : Maybe String
    , dragMode : DragMode
    , protoEvent : ProtoEvent
    , eventFormActive : Bool
    }


type Mode
    = Daily


type DragMode
    = Create
    | Move
    | Extend


type alias ProtoEvent =
    { start : Date
    , finish : Date
    , label : String
    }


initProtoEvent : Date -> ProtoEvent
initProtoEvent date =
    let
        defaultStart =
            Date.fromParts
                (Date.year date)
                (Date.month date)
                (Date.day date)
                8
                0
                0
                0

        defaultFinish =
            Date.add Date.Minute 15 defaultStart
    in
        { start = defaultStart
        , finish = defaultFinish
        , label = ""
        }


type Msg
    = ChangeMode Mode
    | SetDate Date
    | Today
    | Previous
    | Next
    | AddEvent
    | InputEventLabel ProtoEvent String
    | CloseEventForm
    | PersistProtoEvent ProtoEvent
    | StartEventDrag DragMode String Mouse.Position
    | DragEvent String Mouse.Position
    | StopEventDrag String Mouse.Position
    | AttemptEventUpdateFromDrag (Result String ( String, String ))
    | RemoveEvent String
