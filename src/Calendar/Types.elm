module Calendar.Types exposing (..)

import Date exposing (Date)
import Date.Extra as Date
import Mouse


type alias Model =
    { activeMode : Mode
    , selectedDate : Date
    , draggingProtoEvent : Maybe ProtoEvent
    , dragMode : DragMode
    , protoEvent : ProtoEvent
    , eventFormActive : Bool
    , virtualEvents : List ProtoEvent
    }


type Mode
    = Daily


type DragMode
    = Create
    | Move
    | Extend


type alias ProtoEvent =
    { id : Maybe String
    , start : Date
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
        { id = Nothing
        , start = defaultStart
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
    | StartEventDrag DragMode ProtoEvent Mouse.Position
    | DragEvent ProtoEvent Mouse.Position
    | StopEventDrag ProtoEvent Mouse.Position
    | CacheEventUpdateFromFromDrag (Result String ( ProtoEvent, String ))
    | PersistEventUpdateFromDrag (Result String ( ProtoEvent, String ))
    | RemoveEvent String
