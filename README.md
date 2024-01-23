# Roc ISO Date Time
A Roc Library for parsing ISO 8601 Date/Time Strings

## Implementation
This implementation currently converts an ISO date/time string into the [Utc](https://github.com/roc-lang/basic-cli/blob/main/platform/Utc.roc) Roc type provided by the Roc Basic-CLI platform. One of the shortcomings of this implementation is that the Utc type is backed by an unsigned integer (U128), meaning that it has no means of representing dates/time prior to the UNIX epoch date.

This shortcoming may be addressed in future by supporting parsing ISO strings into other date/time formats such as [Roc DateTimes](https://github.com/Hasnep/roc-datetimes). However for the time being, implementation remains limited to the Basic CLI Utc type.


## ISO 8601 Date/Time Format
Description of ISO date/time [format](FORMAT_DESCRIPTION.md)