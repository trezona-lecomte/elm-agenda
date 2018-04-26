module Calendar.DateHelpers exposing (dateFromQuarter, dateFromQuarterString)

import Basics.Extra exposing (fmod)
import Date exposing (Date)
import Date.Extra as Date


dateFromQuarter : Date -> Int -> Date
dateFromQuarter selectedDate quarter =
    let
        ( hour, minute ) =
            ( floor fractionOfDayInHours, minutesAsFraction )

        fractionOfDayInMinutes =
            -- N.B. +1 takes us to the 'end' of the quarter hour.
            (toFloat (quarter + 1) / quartersInDay) * minutesInDay

        fractionOfDayInHours =
            -- The hour that this quarter represents, as a fraction. E.g. 13:30
            -- would be 13.5
            fractionOfDayInMinutes / minutesInHour

        minutesAsFraction =
            (fmod fractionOfDayInMinutes 60) |> round
    in
        Date.fromParts
            (Date.year selectedDate)
            (Date.month selectedDate)
            (Date.day selectedDate)
            hour
            minute
            (Date.second selectedDate)
            (Date.millisecond selectedDate)


dateFromQuarterString : Date -> String -> Result String Date
dateFromQuarterString selectedDate quarterString =
    String.toInt quarterString
        |> Result.map (dateFromQuarter selectedDate)


quartersInDay : number
quartersInDay =
    96


minutesInDay : number
minutesInDay =
    1440


minutesInHour : number
minutesInHour =
    60
