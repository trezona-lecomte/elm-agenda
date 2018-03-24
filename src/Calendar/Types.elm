module Calendar.Types exposing (..)

import Date exposing (Date)
import Mouse


type Mode
    = Daily


type DragMode
    = Move
    | Extend


type Msg
    = ChangeMode Mode
    | SetDate Date
    | Today
    | Previous
    | Next
    | StartEventDrag DragMode String Mouse.Position
    | DragEvent String Mouse.Position
    | StopEventDrag String Mouse.Position
    | AttemptEventUpdateFromDrag (Result String ( String, String ))