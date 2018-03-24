port module Calendar.Ports exposing (..)


port fetchQuarterAtPosition : String -> Cmd msg


port fetchedQuarterAtPosition : (String -> msg) -> Sub msg
