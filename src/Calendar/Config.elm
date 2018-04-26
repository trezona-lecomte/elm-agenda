module Calendar.Config exposing (Config, EventMapping)

import Calendar.Types exposing (ProtoEvent)
import Date exposing (Date)


type alias Config event msg =
    { createEvent : ProtoEvent -> Maybe msg
    , updateEventStart : ProtoEvent -> Maybe msg
    , updateEventFinish : ProtoEvent -> Maybe msg
    , removeEvent : String -> Maybe msg
    , eventMapping : EventMapping event
    }


type alias EventMapping event =
    { id : event -> String
    , start : event -> Date
    , finish : event -> Date
    , label : event -> String
    }
