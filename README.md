WIP Elm Calendar Library


## Current Status

This library has only just been born, so it's in a somewhat sophomoric state.


### Daily Mode

* ~~Layout~~
* ~~Previous & next day buttons~~
* ~~Today button~~
* ~~Event display~~
* ~~Drag to extend finish time of event~~
* ~~Drag to reschedule event~~
* ~~Appropriate cursors for different event drag modes~~
* Add new events (button)
* Drag to add new events
* Remove events


### Weekly Mode

Not yet started. Should be able to leverage much of the behaviour implemented
for Daily mode.

* Mode switching


### Monthly Mode

Not yet started.


### Yearly Mode

Not yet started.

### Library

* Tests
* Untangle msg/Msg mess
* Impose some semblence of sanity on the module structure
* Tinker with various options for exposing configuration
* Research trade-offs with different approaches to exposing CSS and layout
  customization


## API Design Considerations

See: http://package.elm-lang.org/help/design-guidelines


### What is the concrete problem you want to solve?

Adding interactive calendars easily to Elm apps.


### What would it mean for your API to be a success?

I can easily add an interactive calendar to my own personal project.


### Who has this problem? What do they want from an API?

Me! I want:
 * Really simple API for basic use cases
 * _Still_ a really simple API for advanced use cases


### What specific things are needed to solve that problem?

View, add, remove, and edit events on a per day, per week, and per month
basis.

Events need to have:
 * Short label - implemented
 * Description?
 * Start time - implemented
 * Finish time - implemented
 * Recurring schedule?


### Have other people worked on this problem? What lessons can be learned from them? Are there specific weaknesses you want to avoid?

[FullCalendar][full-calendar-site] is featureful, but it's not in Elm! Shouldn't
Elm have a super sweet calender library of it's own?

[Elm Calendar][elm-calendar-github-repo] looked promising, but is still in a WIP
state and hasn't been touched in a long while. I would rather start from scratch
so that I can make my own design decisions and understand the code from the
ground up.

[full-calendar-site]: https://fullcalendar.io/
[elm-calendar-github-repo]: https://github.com/thebritican/elm-calendar



