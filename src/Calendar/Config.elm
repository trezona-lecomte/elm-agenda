module Calendar.Config exposing (Config, EventMapping)

import Date exposing (Date)


type alias Config event msg =
    { updateEventStart : String -> Date -> Maybe msg
    , updateEventFinish : String -> Date -> Maybe msg
    , eventMapping : EventMapping event
    }


type alias EventMapping event =
    { id : event -> String
    , start : event -> Date
    , finish : event -> Date
    , label : event -> String
    }
