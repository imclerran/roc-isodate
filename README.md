# Roc IsoDate
A Roc package for parsing ISO 8601 Date/Time Strings 

## Implementation
This implementation is currently designed to convert an ISO date/time string into the [Utc](https://github.com/roc-lang/basic-cli/blob/main/platform/Utc.roc) Roc type provided by the Roc Basic-CLI platform. One of the shortcomings of this implementation is that the Utc type is backed by an unsigned integer (U128), meaning that it has no means of representing dates/time prior to the UNIX epoch date.

*NOTE: Pull requests are currently in progress on both roc-lang/basic-cli and basic-webserver platfomrs to convert Utc to use signed integers. With this change in motion, plans for this library have been updated to support conversion of pre-epoch dates to Utc*

Note that due to the expense of purchasing the ISO 8601-2:2019 standard document, my implementation is based on a [2016 pre-release](https://www.loc.gov/standards/datetime/iso-tc154-wg5_n0038_iso_wd_8601-1_2016-02-16.pdf) copy of the 8601-1 standard, so my implementation does not conform to the latest revision to the standard.

## Progress
- Full support for parsing all date string types, as described [here](FORMAT.md).
  - **Note:** *beginning work on support for pre-epoch dates.*
- Partial support for parsing time strings.
  - local time representations, with the exception of fractional times are fully supported.
- can Parse from `Str` or from a `List U8` of Utf-8 bytes.


## Future Plans
- Support for parsing pre-epoch dates to Utc.
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
Description of ISO date/time [format](FORMAT.md) (WIP)
