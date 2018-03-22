module Config exposing (..)

import Date exposing (Date)


type alias EventConfig event =
    { id : event -> String
    , start : event -> Date
    , finish : event -> Date
    , label : event -> String
    }
