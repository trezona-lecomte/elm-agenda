module Labels exposing (..)


previousPageButton : String
previousPageButton =
    "Previous"


nextPageButton : String
nextPageButton =
    "Next"


changeModeButton : a -> String
changeModeButton a =
    toString a
