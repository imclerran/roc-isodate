# Roc IsoDate

[![Roc-Lang][roc_badge]][roc_link]
[![GitHub last commit][last_commit_badge]][last_commit_link]
[![CI status][ci_status_badge]][ci_status_link]
[![Latest release][version_badge]][version_link]

Roc-IsoDate is a universal date and time package for Roc. It Features several useful types for working with dates and times. Its primary types (`Date`/`Time`/`DateTime`) store dates and times in a human friendly manner, but allow easy conversion to and from computer friendly types like `Utc` as well as web friendly ISO 8601 strings. Roc IsoDate is intended to be a one-stop-shop for all things date and time. 📆 ⏰ 📦

## Implementation

Roc IsoDate's API revolves around its types, primarily `Date`, `Time`, and `DateTime`, supported by `Month` and `Duration`. These types provide functions such as `from_iso_str` and `to_iso_str`, as well as functions for parsing directly from a list of UTF-8 bytes. They are nominal types, so a value can only be built through the constructors each type provides, such as `Date.from_ymd(2024, Mar, 15)` or `DateTime.from_iso_str("2024-03-15T09:30:00")`. Constructors validate their input and return a `Try`, with errors such as `InvalidDayOfMonth` or `YearOutOfRange` naming the field that was wrong, so every value the library hands back is a valid date or time. Each type exposes its parts through plainly named getters, such as `date.year()`, `date.month()`, `time.hour()`, or `date_time.date()`. A calendar month is represented by the `Month` type (`Jan` through `Dec`) rather than a raw number, so an invalid month cannot be passed to the API. `Month.from_u8` converts a number at the boundary of your program and reports an error for anything outside 1 to 12. A `Date` can represent any year from -999,999,999 to 999,999,999, and date arithmetic saturates to that range instead of overflowing, just as `Duration` arithmetic saturates at its own limits. The types also provide functions for performing math on dates and times, and for converting to and from nanoseconds since the epoch for dates, or since midnight for times.

Note that due to the expense of purchasing the ISO 8601-2:2019 standard document, my implementation of ISO string parsing is based on a [2016 pre-release][iso_8601_doc] copy of the 8601-1 standard, so my implementation may not fully conform to the latest revision to the standard.

## Progress

- Full support for parsing all date representations.
- Full support for parsing local time representations.
- Full support for offset from UTC time representations.
- Full support for combined date/time representations.
- Can Parse from `Str` or from a `List(U8)` of Utf-8 bytes.
- Unify API around `Date`/`Time`/`DateTime` types
  - This means converting to and from ISO strings is as simple as:
  - `DateTime.from_iso_str(str)` or `Time.to_iso_str(date)`
  - Similarly, converting to and from `Utc` is easy:
  - `Date.to_nanos_since_epoch(date) -> Utc.from_nanos_since_epoch()` or
    `Utc.to_nanos_since_epoch(utc) -> DateTime.from_nanos_since_epoch()`

## Future Plans

- Time interval representations will be added once the parsing to Date/Time/DateTime is complete [DONE 🚀].
- Once Parsing is complete, add formatting dates and times to ISO strings.
- Research adding custom encoding/decoding for json parsers.

## Unified API

To extend functionality and simplify the API, library _now_ simply provides a collection of types for working with dates. Each of these types provide all the necessary functions for interacting with it, including functions for converting to and from ISO strings, and converting to and from Utc types, as well as various other constructors and math functions.

Thus, an application might look like the following:

```roc
app [main!] {
	pf: platform "https://github.com/roc-lang/basic-cli/releases/download/0.26.0/GddgvsGjiNXrHFW6au5i5dUDbTs8FinQdrgE2Gqmw53t.tar.zst",
	http: "https://github.com/roc-lang/http/releases/download/2.0.0/6ZUwqYhCS8PU9Mo6MF7oV82ET2o7KYb57CLKDq4cq4sS.tar.zst",
	dt: "../package/main.roc",
}

import pf.Stdout
import pf.Http
import http.Method
import http.Request
import dt.DateTime as DT

main! = |_| {
	timezone = "Europe/Paris"
	request = Request.from_method(GET)
		.with_uri("https://timeapi.io/api/v1/timezone/zone?timeZone=${timezone}")
		.with_timeout(TimeoutMilliseconds(3000))
	response = Http.send!(request, {})?
	if response.status() >= 200 and response.status() <= 299 {
		iso_str = get_iso_str(response.body())?
		dt_now = DT.from_iso_str(iso_str)?
		date_str = dt_now.format("{YYYY}-{MM}-{DD}")
		time_str = dt_now.format("{hh}:{mm}:{ss}")
		_ = Stdout.line!("The current Zulu date is: ${date_str}")
		_ = Stdout.line!("The current Zulu time is: ${time_str}")
		Ok({})
	} else {
		Err(FailedToGetServerResponse(response.status()))
	}
}

get_iso_str : List(U8) -> Try(Str, _)
get_iso_str = |bytes| {
	str = bytes |> Str.from_utf8()?
	response : { local_time : Str }
	response = Json.parse(str)?
	Ok(response.local_time)
}
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
