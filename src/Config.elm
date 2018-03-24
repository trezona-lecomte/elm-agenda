module Config exposing (..)

import Date exposing (Date)


type alias EventConfig event =
    { id : event -> String
    , start : event -> Date
    , finish : event -> Date
    , label : event -> String
    }


type alias CalendarConfig msg =
    { moveEvent : String -> Date -> Maybe msg
    , extendEvent : String -> Date -> Maybe msg
    }
