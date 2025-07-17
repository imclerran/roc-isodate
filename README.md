# Roc IsoDate

[![Roc-Lang][roc_badge]][roc_link]
[![GitHub last commit][last_commit_badge]][last_commit_link]
[![CI status][ci_status_badge]][ci_status_link]
[![Latest release][version_badge]][version_link]

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

To extend functionality and simplify the API, library _now_ simply provides a collection of types for working with dates. Each of these types provide all the necessary functions for interacting with it, including functions for converting to and from ISO strings, and converting to and from Utc types, as well as various other constructors and math functions.

Thus, an application might look like the following:

```roc
main! = |_|
    req = format_request("America/Chicago")
    response = Http.send!(req)?
    if response.status >= 200 and response.status <= 299 then
        iso_str = get_iso_str(response.body)?
        dt_now = DT.from_iso_str(iso_str)?

        date_str = dt_now |> DT.format("{YYYY}-{MM}-{DD}")
        time_str = dt_now |> DT.format("{hh}:{mm}:{ss}")
        "The current Zulu date is: ${date_str}" |> Stdout.line!?
        "The current Zulu time is: ${time_str}"|> Stdout.line!
    else
        Err FailedToGetServerResponse(response.status)
```

This is just a small sample of the available functionality, but meant to demonstrate the general design of the API. Moving to and from computer-friendly representations like `Utc`, web-friendly representations like ISO `Str`s, and human friendly representations like `DateTime` are all just a single function call away. `Durations` and `TimeInterval`s also add quality of life functionality for easily manipulating dates and times.

## Known Issues

- Missing features mentioned above.
- ISO Requirement for combined date-time strings to have only non-reduced accuracy dates is not enforced
- ISO Requirement for combined date-time strings to be in completely basic or completely extended format are not enforced.

## ISO 8601 Date/Time Format

Description of ISO date/time [format][iso_8601_md] (WIP)

[roc_badge]: https://img.shields.io/endpoint?url=https%3A%2F%2Fpastebin.com%2Fraw%2FcFzuCCd7
[roc_link]: https://github.com/roc-lang/roc
[ci_status_badge]: https://img.shields.io/github/actions/workflow/status/imclerran/roc-isodate/ci.yaml?logo=github&logoColor=lightgrey
[ci_status_link]: https://github.com/imclerran/Roc-IsoDate/actions/workflows/ci.yaml
[last_commit_badge]: https://img.shields.io/github/last-commit/imclerran/roc-isodate?logo=git&logoColor=lightgrey
[last_commit_link]: https://github.com/imclerran/Roc-IsoDate/commits/main/
[version_badge]: https://img.shields.io/github/v/release/imclerran/roc-isodate
[version_link]: https://github.com/imclerran/roc-isodate/releases/latest
[iso_8601_doc]: https://www.loc.gov/standards/datetime/iso-tc154-wg5_n0038_iso_wd_8601-1_2016-02-16.pdf
[utc_link]: https://github.com/roc-lang/basic-cli/blob/main/platform/Utc.roc
[utctime_link]: https://github.com/imlerran/roc-isodate/blob/main/platform/UtcTime.roc
[iso_8601_md]: ISO_8601.md
