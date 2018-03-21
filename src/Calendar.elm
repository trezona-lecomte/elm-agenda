module Calendar exposing (Mode(..), Msg, Model, init, update, view, subscriptions)

import Date exposing (Date)
import Html exposing (..)


type Mode
    = Daily


type alias Model =
    { mode : Mode
    , currentDate : Date
    }


init : Mode -> Date -> Model
init mode date =
    { mode = mode
    , currentDate = date
    }


type Msg
    = Next
    | Back


update : Msg -> Model -> ( Model, Maybe msg )
update msg model =
    case msg of
        Next ->
            ( model, Nothing )

        Back ->
            ( model, Nothing )


view : Model -> Html Msg
view model =
    div [] [ text "hello calendar" ]


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
