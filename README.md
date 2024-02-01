# Roc IsoDate
A Roc package for parsing ISO 8601 Date/Time Strings 

![GitHub last commit][last_commit_badge]
![CI status][ci_status_badge]

## Implementation
This implementation is currently designed to convert an ISO date/time string into the [Utc][utc_roc] type provided by the Basic CLI and Basic Webserver platforms. The `Utc` type in these platforms is currently based on an unsigned integer which will not support pre-epoch dates. However, pull requests are currently in progress on both platfomrs to convert Utc to use signed integers. With this change in motion, this library has pre-emptively moved its own `Utc` type to a signed integer type.

Note that due to the expense of purchasing the ISO 8601-2:2019 standard document, my implementation is based on a [2016 pre-release][iso_8601_doc] copy of the 8601-1 standard, so my implementation may not fully conform to the latest revision to the standard.

## Progress
- Full support for parsing all date string types, as described [here][iso_8601_md].
- Partial support for parsing time strings.
  - local time representations, with the exception of fractional times are fully supported.
- can Parse from `Str` or from a `List U8` of Utf-8 bytes.


## Future Plans
- Fractional time representations.
- UTC timezone offset time representations.
- Full support for combined date/time representations.
- Time interval representations will be added once date/time support is complete.
- Once Parsing from iso is complete, add formatting dates and times to ISO strings.
- Research adding custom encoding/decoding for json parsers.

## Known Issues
- As mentioned above, no support yet for any strings containing time data, or for intervals.
- Also mentioned above: Basic CLI platform's Utc type does not support dates before 1970-01-01.

## ISO 8601 Date/Time Format
Description of ISO date/time [format][iso_8601_md] (WIP)

[ci_status_badge]: https://img.shields.io/github/actions/workflow/status/imclerran/roc-isodate/ci.yml
[last_commit_badge]: https://img.shields.io/github/last-commit/imclerran/roc-isodate

[iso_8601_doc]: https://www.loc.gov/standards/datetime/iso-tc154-wg5_n0038_iso_wd_8601-1_2016-02-16.pdf
[utc_roc]: https://github.com/roc-lang/basic-cli/blob/main/platform/Utc.roc
[iso_8601_md]: ISO_8601.md
