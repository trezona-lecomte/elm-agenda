module Config exposing (..)

import Date exposing (Date)
import Mouse


type alias EventConfig event =
    { id : event -> String
    , start : event -> Date
    , finish : event -> Date
    , label : event -> String
    }


type alias CalendarConfig msg =
    { startEventDrag : String -> Mouse.Position -> Maybe msg
    , changeEventFinish : String -> Date -> Maybe msg
    }
