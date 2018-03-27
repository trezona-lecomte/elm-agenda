module Calendar.Types exposing (..)

import Date exposing (Date)
import Mouse


type alias Model =
    { activeMode : Mode
    , selectedDate : Date
    , draggingEventId : Maybe String
    , dragMode : DragMode
    , protoEvent : Maybe ProtoEvent
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
