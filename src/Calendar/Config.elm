module Calendar.Config exposing (Config, EventMapping)

import Calendar.Types exposing (ProtoEvent)
import Date exposing (Date)


type alias Config event msg =
    { createEvent : ProtoEvent -> Maybe msg
    , moveEvent : String -> Date -> Maybe msg
    , extendEvent : String -> Date -> Maybe msg
    , removeEvent : String -> Maybe msg
    , eventMapping : EventMapping event
    }


type alias EventMapping event =
    { id : event -> String
    , start : event -> Date
    , finish : event -> Date
    , label : event -> String
    }
