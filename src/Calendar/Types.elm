module Calendar.Types exposing (Mode(..), Msg(..))

import Date exposing (Date)
import Mouse


type Mode
    = Daily


type Msg
    = ChangeMode Mode
    | SetDate Date
    | Today
    | Previous
    | Next
    | StartEventDrag String Mouse.Position
    | StopEventDrag String Mouse.Position
    | AttemptEventUpdateFromDrag (Result String ( String, String ))
