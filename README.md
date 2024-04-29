# Roc IsoDate

[![Roc-Lang][roc_badge]][roc_link]
[![GitHub last commit][last_commit_badge]][last_commit_link]
[![CI status][ci_status_badge]][ci_status_link]

Roc-IsoDate is a universal date and time package for Roc. It Features several useful types for working with dates and times. Its primary types (`Date`/`Time`/`DateTime`) store dates and times in a human friendly manner, but allow easy conversion to and from computer friendly types like `Utc` as well as web web friendly ISO 8601 strings. Roc IsoDate is intended to be a one-stop-shop for all things date and time. 📆 ⏰ 📦

## Implementation
Roc IsoDate's API revolves around its types, primarily `Date`, `Time`, and `DateTime`. These types provide useful functions for such as `fromIsoStr`, `fromIsoStr`, as well as functions for parsing directly from a list of Utf8 bytes. The types are based on records containing some of the most common data fields a user might want for working with dates and times in a human friendly manner, IE: `year`, `month`, `dayOfMonth`, `dayOfYear`, `hour`, `minute`, `second` and `nanosecond`. It also provides functions for performing math operations on these dates, as well as various constructors, and functions to convert to and from nanoseconds since the epoch for dates or since midnght for time.

Note that due to the expense of purchasing the ISO 8601-2:2019 standard document, my implementation of ISO string parsing is based on a [2016 pre-release][iso_8601_doc] copy of the 8601-1 standard, so my implementation may not fully conform to the latest revision to the standard.

## Progress
- Full support for parsing all date representations.
- Full support for parseing local time representations.
- Full support for offset from UTC time representations.
- Full support for combined date/time representations.
- Can Parse from `Str` or from a `List U8` of Utf-8 bytes.
- Unify API around `Date`/`Time`/`DateTime` types
  - This means converting to and from ISO strings is as simple as:
  - `DateTime.fromIsoStr str` or `Time.toIsoStr date`
  - Similarly, converting to and from `Utc` is easy:
  - `Date.toNanosSinceEpoch date |> Utc.fromNanosSinceEpoch` or 
    `DateTime.toNanosSinceEpoch utc |> Utc.fromNanosSinceEpoch`

## Future Plans
- Time interval representations will be added once the parsing to Date/Time/DateTime is complete [DONE 🚀].
- Once Parsing is complete, add formatting dates and times to ISO strings.
- Research adding custom encoding/decoding for json parsers.

## Unified API
To extend functionality and simplify the API, library *now* simply provides a collection of types for working with dates. Each of these types provide all the necessary functions for interacting with it, including functions for converting to and from ISO strings, and converting to and from Utc types, as well as various other constructors and math functions.

Thus, an application might look like the following:
```roc
app "MyDateApp"
    packages {
        pf: "https://github.com/roc-lang/basic-cli/releases/download/0.9.0/oKWkaruh2zXxin_xfsYsCJobH1tO8_JvNkFzDwwzNUQ.tar.br",
        dt: "https://github.com/imclerran/Roc-IsoDate/releases/download/v0.3.0/GLLnv2LpABZzVYHlata79rpfaF_bJaxsbYMLtk-mF_w.tar.br",

    }
    imports [
        dt.DateTime,
        dt.Duration,
        pf.Utc,
        pf.Stdout,
        pf.Task,
    ]
    provides [main] to pf

main =
    utcNow <- Task.await Utc.now
    dtNow = Utc.toNanosSinceEpoch utcNow |> DateTime.fromNanosSinceEpoch # Convert Utc to DateTime easily
    dtEpoch = DateTime.unixEpoch # Constructor for the epoch
    dtSomeTime = DateTime.fromIsoStr "2024-04-19T11:31:41.329515-05:00" # parse a DateTime from ISO str easily
    dtLaterDate = dtSomeTime |> DateTime.addDateTimeAndDuration (Duration.fromHours 25 |> unwrap "25 hours should not overflow") # Add a duration to a DateTime easily
    utcLaterDate = DateTime.toNanosSinceEpoch dtSomeTime |> Utc.fromNanosSinceEpoch # Convert parsed date to Utc
    nanosLaterDate = Utc.toNanosSinceEpoch utcLaterDate
    
    _ <- Stdout.line "ISO epoch: $(DateTime.toIsoStr dtEpoch)" |> Task.await
    _ <- Stdout.line "Time now: $(Num.toStr dtNow.time.hour):$(Num.toStr dtNow.time.minute):$(Num.toStr dtNow.time.second)" |> Task.await
    _ <- Stdout.line "Day some time: $(Num.toStr dtSomeTime.date.day)" |> Task.await
    Stdout.line "Utc nanos later date: $(Num.toStr nanosLaterDate)"

unwrap : Result a _, Str -> a
unwrap = \x, message ->
    when x is
        Ok v -> v
        Err _ -> crash message
```

This is just a small sample of the available functionality, but meant to demonstrate the general design of the API. Moving to and from computer-friendly representations like `Utc`, web-friendly representations like ISO `Str`s, and human friendly representations like `DateTime` are all just a single function call away. `Durations` and `TimeInterval`s also add quality of life functionality for easily manipulating dates and times.

## Known Issues
- Missing features mentioned above.
- ISO Requirement for combined date-time strings to have only non-reduced accuracy dates is not enforced
- ISO Requirement for combined date-time strings to be in completely basic or completely extended format are not enforced.

## ISO 8601 Date/Time Format
Description of ISO date/time [format][iso_8601_md] (WIP)


[roc_badge]: https://img.shields.io/endpoint?url=https%3A%2F%2Fpastebin.com%2Fraw%2FGcfjHKzb
[roc_link]: https://github.com/roc-lang/roc
[ci_status_badge]: https://img.shields.io/github/actions/workflow/status/imclerran/roc-isodate/ci.yml
[ci_status_link]: https://github.com/imclerran/Roc-IsoDate/actions/workflows/ci.yml
[last_commit_badge]: https://img.shields.io/github/last-commit/imclerran/roc-isodate
[last_commit_link]: https://github.com/imclerran/Roc-IsoDate/commits/main/

[iso_8601_doc]: https://www.loc.gov/standards/datetime/iso-tc154-wg5_n0038_iso_wd_8601-1_2016-02-16.pdf
[utc_link]: https://github.com/roc-lang/basic-cli/blob/main/platform/Utc.roc
[utctime_link]: https://github.com/imlerran/roc-isodate/blob/main/platform/UtcTime.roc
[iso_8601_md]: ISO_8601.md
