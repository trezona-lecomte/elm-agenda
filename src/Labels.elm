module Labels exposing (..)


todayButton : String
todayButton =
    "Today"


previousPageButton : String
previousPageButton =
    "<"


nextPageButton : String
nextPageButton =
    ">"


changeModeButton : a -> String
changeModeButton a =
    toString a


addEventButton : String
addEventButton =
    "Add Event"
