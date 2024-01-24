# IsoRocDate
A Roc package for parsing ISO 8601 Date/Time Strings 

## Implementation
This implementation is currently designed to convert an ISO date/time string into the [Utc](https://github.com/roc-lang/basic-cli/blob/main/platform/Utc.roc) Roc type provided by the Roc Basic-CLI platform. One of the shortcomings of this implementation is that the Utc type is backed by an unsigned integer (U128), meaning that it has no means of representing dates/time prior to the UNIX epoch date.

This shortcoming may be addressed in future by supporting parsing ISO strings into other date/time formats such as [Roc DateTimes](https://github.com/Hasnep/roc-datetimes). However for the time being, implementation remains limited to the Basic CLI Utc type.

Note that due to the expense of purchasing the ISO 8601-2:2019 standard document, my implementation is based on a [2016 pre-release](https://www.loc.gov/standards/datetime/iso-tc154-wg5_n0038_iso_wd_8601-1_2016-02-16.pdf) copy of the 8601-1 standard, so my implementation does not conform to the latest revision to the standard.

## Progress
- So far this library has full support for parsing all date string types, as described [here](FORMAT.md).
- Support for time, date & time representations is planned
- Support for time intervals may be considered after full date/time support is complete.

## Known Issues
- As mentioned above, no support yet for any strings containing time data, or for intervals.
- Not performance optimized - regexing, or better yet a finite state machine parser would be much more performant.
- Also mentioned above: Basic CLI platform's Utc type does not support dates before 1970-01-01.

## ISO 8601 Date/Time Format
Description of ISO date/time [format](FORMAT.md) (WIP)
