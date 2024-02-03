# Roc IsoDate
A Roc package for parsing ISO 8601 Date/Time Strings 

[![Roc-Lang][roc_new_badge]][roc_link]
[![GitHub last commit][last_commit_badge]][last_commit_link]
[![CI status][ci_status_badge]][ci_status_link]

## Implementation
Roc IsoDate is a rock package which which can convert an ISO date/time string into the [Utc][utc_link] type provided by the Basic CLI and Basic Webserver platforms, which stores the nanoseconds since the UNIX epoch date. When parsing time-only strings, the package returns a [UtcTime][utctime_link], which is similar to the `Utc` type, but stores the nanoseconds since midnight.

Note that due to the expense of purchasing the ISO 8601-2:2019 standard document, my implementation is based on a [2016 pre-release][iso_8601_doc] copy of the 8601-1 standard, so my implementation may not fully conform to the latest revision to the standard.

## Progress
- Full support for parsing all date representations.
- Full support for parseing local time representations.
- Full support for offset from UTC time representations.
- Full support for combined date/time representations.
- Can Parse from `Str` or from a `List U8` of Utf-8 bytes.

## Future Plans
- Time interval representations will be added once date/time support is complete.
- Once Parsing from iso is complete, add formatting dates and times to ISO strings.
- Research adding custom encoding/decoding for json parsers.

## Known Issues
- Missing features mentioned above.
- ISO Requirement for combined date-time strings to have only non-reduced accuracy dates is not enforced
- ISO Requirement for combined date-time strings to be in completely basic or completely extended format are not enforced.

## ISO 8601 Date/Time Format
Description of ISO date/time [format][iso_8601_md] (WIP)


[roc_badge]: https://img.shields.io/badge/Roc%20Lang-6B3ADC
[roc_new_badge]: https://pastebin.com/raw/GcfjHKzb
[roc_link]: https://github.com/roc-lang/roc
[ci_status_badge]: https://img.shields.io/github/actions/workflow/status/imclerran/roc-isodate/ci.yml
[ci_status_link]: https://github.com/imclerran/Roc-IsoDate/actions/workflows/ci.yml
[last_commit_badge]: https://img.shields.io/github/last-commit/imclerran/roc-isodate
[last_commit_link]: https://github.com/imclerran/Roc-IsoDate/commits/main/

[iso_8601_doc]: https://www.loc.gov/standards/datetime/iso-tc154-wg5_n0038_iso_wd_8601-1_2016-02-16.pdf
[utc_link]: https://github.com/roc-lang/basic-cli/blob/main/platform/Utc.roc
[utctime_link]: https://github.com/imlerran/roc-isodate/blob/main/platform/UtcTime.roc
[iso_8601_md]: ISO_8601.md
