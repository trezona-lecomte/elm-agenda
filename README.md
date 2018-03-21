# Elm Agenda


## API Design Considerations

See: http://package.elm-lang.org/help/design-guidelines


### What is the concrete problem you want to solve?

Adding interactive calendars easily to Elm apps.


### What would it mean for your API to be a success?

I can easily add an interactive calendar to my own personal project.


### Who has this problem? What do they want from an API?

Me! I want:
 * Really simple API for basic use cases
 * _Still_ a really simple API for advanced use cases :-P


### What specific things are needed to solve that problem?

View, add, remove, and edit events on a per day, per week, and per month
basis.

Events need to have:
 * Short label
 * Description?
 * Start time
 * End time
 * Recurring schedule?


### Have other people worked on this problem? What lessons can be learned from them? Are there specific weaknesses you want to avoid?

Yes. https://fullcalendar.io/ in JS land, and
https://github.com/thebritican/elm-calendar in Elm land.

FullCalendar is good, but it's not in Elm.

Elm-Calendar is quite far along, but it's buggy, and appears to be
dead. I would rather start from scratch so that I can make my own design
decisions and understand the code from the ground up.




CSS: https://codepen.io/afontcu/pen/bapBxv


