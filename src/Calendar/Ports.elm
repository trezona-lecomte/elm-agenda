port module Calendar.Ports exposing (..)


port dragEvent : String -> Cmd msg


port draggedEvent : (String -> msg) -> Sub msg


port stopDraggingEvent : String -> Cmd msg


port stoppedDraggingEvent : (String -> msg) -> Sub msg
