WIP Elm Calendar Library


## Current Status

This library has only just been born, so it's in a somewhat sophomoric state.


## API Design Considerations

See: http://package.elm-lang.org/help/design-guidelines


### What concrete problem does this library aim to solve?

Web application authors using Elm currently have the following options when
tackling requirements involving interactive calendar functionality:

 * A JavaScript library (such as [FullCalendar][full-calendar-site]) through
   ports
 * Using a WIP, yet to be published Elm library such as [Elm Calendar][elm-calendar-github-repo]
 * Writing their own calendar implementation

These options all have their drawbacks when compared with a hypothetical
'production-ready' Elm library.

**Ports** seem to be a much less natural interface for an Elm app to integrate with
than a triplet of model, update, and view functions.

**Elm Calendar** provides some good core functionality, however it doesn't seem
ready for publication and hasn't been under active development for about 9
month.

I think that **writing their own** calendar is a reasonable option for any Elm
developer working on a production app.

This library aims to satisfy the core requirements for most Elm apps that need
interactive calendar behaviour


### What will it mean for this API to be a success?

Success could take a number of forms:

 * When I can use this library in my own projects
 * When others are able to make use of this library
 * When others contribute their expertise such that this library becomes worthy
   of publication and a pleasure to use

### Who has the problem this library solves? What do they want from an API?

I have this problem. I'd like:

 * a pleasantly simple API for basic use cases (such as widgets that don't
   require drag & drop - the interface for these should be dead simple);
 * an understandable and flexible API for full-featured interactive calendars;
 * to confidently rely on the correctness of the implementation, regardless of
   domain or locale; and
 * to add calendars to my apps without a particular architecture (outside of
   TEA) begin imposed on me.


### What specific things are needed to solve that problem?

A Calendar should provide:
 * Multiple modes, able to be used independently or in combinations
 * Display of events, with a simple way to customize the layout and style
 * Interactive creation, alteration, and removal of events
 * Support for recurring events
 * Integration with other calendars (e.g. [Google Calendar][google-calendar-api])

In order to do this, a consumer's events must have:
 * An id - implemented, but currently as a string
 * A label - implemented
 * A start time - implemented
 * A finish time - implemented
 * A description - not yet implemented
 * A recurring schedule - not yet implemented


### Have other people worked on this problem?

What lessons can be learned from them? Are there specific weaknesses you want to
avoid?

[FullCalendar][full-calendar-site] is featureful, but it's not in Elm! Shouldn't
Elm have a super sweet calender library of it's own?

TODO: Summarise design choices I'm making differently to FullCalendar.

[Elm Calendar][elm-calendar-github-repo] looked promising, but is still in a WIP
state and hasn't been touched in a long while. I would rather start from scratch
so that I can make my own design decisions and understand the code from the
ground up.

TODO: Summarise design choices I'm making differently to Elm Calendar.


## Feature Progress

### Daily Mode

* ~~Layout~~
* ~~Previous & next day buttons~~
* ~~Today button~~
* ~~Event display~~
* ~~Drag to extend finish time of event~~
* ~~Drag to reschedule event~~
* ~~Appropriate cursors for different event drag modes~~
* ~~Don't allow dragging the finish of an event to an earlier time than the start~~
* Fix unsafe javascript that breaks when you drag an event outside the viewport
* Change to a `grabbing` cursor when moving or extending
* Add new events (button)
* Remove events
* Display: deal with overlapping events
* Drag to add new events


### Weekly Mode

Not yet started. Should be able to leverage much of the behaviour implemented
for Daily mode.

* Mode switching


### Monthly Mode

Not yet started.


### Yearly Mode

Not yet started.


### Library

 * Untangle msg/Msg mess
 * Impose some semblence of sanity on the module structure
 * Tinker with various options for exposing configuration
 * Research trade-offs with different approaches to exposing CSS and layout
   customization

## License and Copyright

Copyright 2018 Flux Federation, MIT license.

This software was written by Kieran Trezona-le Comte, with the initial 2 days of
implementation work done during the Flux Federation monthly 'hack days'. You can
check out other useful stuff from Flux [here on Github][flux-github].


[full-calendar-site]: https://fullcalendar.io
[elm-calendar-github-repo]: https://github.com/thebritican/elm-calendar
[google-calendar-aip]: https://developers.google.com/calendar
[flux-github]: https://github.com/fluxfederation

