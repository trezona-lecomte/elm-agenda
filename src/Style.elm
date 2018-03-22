module Style exposing (class)

import Html
import Html.Attributes as Html


class : String -> Html.Attribute msg
class class =
    Html.class <| "elm-agenda__" ++ class


containerClass : String
containerClass =
    "elm-agenda__container container"


calendarClass : String
calendarClass =
    "elm-agenda__calendar"


calendarHeaderClass : String
calendarHeaderClass =
    "elm-agenda__calendar-header"


dayCalendarClass : String
dayCalendarClass =
    "elm-agenda__day-calendar"


hoursColumnClass : String
hoursColumnClass =
    "elm-agenda__hours-column"


hoursItemClass : String
hoursItemClass =
    "elm-agenda__hours-item"


scheduleColumnClass : String
scheduleColumnClass =
    "elm-agenda__schedule-column"


buttonClass : String
buttonClass =
    "elm-agenda__button button"


paginationControlsClass : String
paginationControlsClass =
    "elm-agenda__pagination-controls"


controlsClass : String
controlsClass =
    "elm-agenda__controls"


modeControlsClass : String
modeControlsClass =
    "elm-agenda__mode-controls"
