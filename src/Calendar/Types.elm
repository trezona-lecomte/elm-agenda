module Calendar.Types exposing (..)

import Date exposing (Date)
import Date.Extra as Date
import Keyboard
import Mouse


type alias Model =
    { activeMode : Mode
    , showSettings : Bool
    , useKeyboardShortcuts : Bool
    , showKeyboardShortcutHelp : Bool
    , eventFormActive : Bool
    , selectedDate : Date
    , draggingProtoEvent : Maybe ProtoEvent
    , dragMode : DragMode
    , protoEvent : ProtoEvent
    , virtualEvents : List ProtoEvent
    }


type Mode
    = Daily


type DragMode
    = Create
    | Move
    | Extend


type alias Event e =
    { e
        | id : String
        , start : Date
        , finish : Date
        , label : String
    }


type alias ProtoEvent =
    { id : Maybe String
    , start : Date
    , finish : Date
    , label : String
    }


initProtoEvent : Date -> ProtoEvent
initProtoEvent date =
    let
        defaultFinish =
            Date.add Date.Minute 15 date
    in
        { id = Nothing
        , start = date
        , finish = defaultFinish
        , label = "Untitled"
        }


type Msg
    = ChangeMode Mode
    | ShowSettings
    | HideSettings
    | ToggleKeyboardShortcuts
    | KeyDown Keyboard.KeyCode
    | KeyUp Keyboard.KeyCode
    | SetDate Date
    | Today
    | Previous
    | Next
    | AddEvent
    | ChangeEventLabel ProtoEvent String
    | CloseEventForm
    | PersistProtoEvent ProtoEvent
    | StartDraggingEvent DragMode ProtoEvent Mouse.Position
    | DragEvent DragMode ProtoEvent Mouse.Position
    | StopDraggingEvent DragMode ProtoEvent Mouse.Position
    | CacheEventUpdateFromFromDrag (Result String EventDrag)
    | PersistEventUpdateFromDrag (Result String EventDrag)
    | RemoveEvent String


type EventDrag
    = EventDrag DragMode ProtoEvent String
