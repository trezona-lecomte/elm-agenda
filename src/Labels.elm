module Labels exposing (..)


previousPageButton : String
previousPageButton =
    "<"


nextPageButton : String
nextPageButton =
    ">"


changeModeButton : a -> String
changeModeButton a =
    toString a
