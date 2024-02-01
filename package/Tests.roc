interface Tests
    exposes []
    imports [
        Const.{
            nanosPerSecond,
            secondsPerDay,
        },
        IsoToUtc.{
            parseDateFromStr,
            parseTimeFromStr,
        },
        Utc.{
            Utc,
            fromNanosSinceEpoch,
        },
        UtcTime.{
            UtcTime,
            fromNanosSinceMidnight,
        },
        Utils.{
            calendarWeekToDaysInYear,
            numDaysSinceEpoch,
            numDaysSinceEpochToYear,
            splitListAtIndices,
            utf8ToFrac,
            utf8ToInt,
            validateUtf8SingleBytes,
        },
    ]

# <==== IsoToUtc.roc ====>
# <---- parseDate ---->
# CalendarDateCentury
expect parseDateFromStr "20" == (10_957) * secondsPerDay * nanosPerSecond |> Num.toI128 |> fromNanosSinceEpoch |> Ok
expect parseDateFromStr "19" == -25_567 * secondsPerDay * nanosPerSecond |> Num.toI128 |> fromNanosSinceEpoch |> Ok
expect parseDateFromStr "ab" == Err InvalidDateFormat

# CalendarDateYear
expect parseDateFromStr "2024" == (19_723) * secondsPerDay * nanosPerSecond |> Num.toI128 |> fromNanosSinceEpoch |> Ok
expect parseDateFromStr "1970" == 0 |> Num.toI128 |> fromNanosSinceEpoch |> Ok
expect parseDateFromStr "1968" == -731 * secondsPerDay * nanosPerSecond |> Num.toI128 |> fromNanosSinceEpoch |> Ok
expect parseDateFromStr "202f" == Err InvalidDateFormat

# WeekDateReducedBasic
expect parseDateFromStr "2024W04" == (19_723 + 21) * secondsPerDay * nanosPerSecond |> Num.toI128 |> fromNanosSinceEpoch |> Ok
expect parseDateFromStr "1970W01" == 0 |> Num.toI128 |> fromNanosSinceEpoch |> Ok
expect parseDateFromStr "1968W01" == -731 * secondsPerDay * nanosPerSecond |> Num.toI128 |> fromNanosSinceEpoch |> Ok
expect parseDateFromStr "2024W53" == Err InvalidDateFormat
expect parseDateFromStr "2024W00" == Err InvalidDateFormat
expect parseDateFromStr "2024Www" == Err InvalidDateFormat

# CalendarDateMonth
expect parseDateFromStr "2024-02" == (19_723 + 31) * secondsPerDay * nanosPerSecond |> Num.toI128 |> fromNanosSinceEpoch |> Ok
expect parseDateFromStr "1970-01" == 0 |> Num.toI128 |> fromNanosSinceEpoch |> Ok
expect parseDateFromStr "1968-01" == -731 * secondsPerDay * nanosPerSecond |> Num.toI128 |> fromNanosSinceEpoch |> Ok
expect parseDateFromStr "2024-13" == Err InvalidDateFormat
expect parseDateFromStr "2024-00" == Err InvalidDateFormat
expect parseDateFromStr "2024-0a" == Err InvalidDateFormat

# OrdinalDateBasic
expect parseDateFromStr "2024023" == (19_723 + 22) * secondsPerDay * nanosPerSecond |> Num.toI128 |> fromNanosSinceEpoch |> Ok
expect parseDateFromStr "1970001" == 0 |> Num.toI128 |> fromNanosSinceEpoch |> Ok
expect parseDateFromStr "1968001" == -731 * secondsPerDay * nanosPerSecond |> Num.toI128 |> fromNanosSinceEpoch |> Ok
expect parseDateFromStr "2024000" == Err InvalidDateFormat
expect parseDateFromStr "2024367" == Err InvalidDateFormat
expect parseDateFromStr "2024a23" == Err InvalidDateFormat

# WeekDateReducedExtended
expect parseDateFromStr "2024-W04" == (19_723 + 21) * secondsPerDay * nanosPerSecond |> Num.toI128 |> fromNanosSinceEpoch |> Ok
expect parseDateFromStr "1970-W01" == 0 |> Num.toI128 |> fromNanosSinceEpoch |> Ok
expect parseDateFromStr "1968-W01" == -731 * secondsPerDay * nanosPerSecond |> Num.toI128 |> fromNanosSinceEpoch |> Ok
expect parseDateFromStr "2024-W53" == Err InvalidDateFormat
expect parseDateFromStr "2024-W00" == Err InvalidDateFormat
expect parseDateFromStr "2024-Ww1" == Err InvalidDateFormat

# WeekDateBasic
expect parseDateFromStr "2024W042" == (19_723 + 22) * secondsPerDay * nanosPerSecond |> Num.toI128 |> fromNanosSinceEpoch |> Ok
expect parseDateFromStr "1970W011" == 0 |> Num.toI128 |> fromNanosSinceEpoch |> Ok
expect parseDateFromStr "1968W011" == -731 * secondsPerDay * nanosPerSecond |> Num.toI128 |> fromNanosSinceEpoch |> Ok
expect parseDateFromStr "2024W001" == Err InvalidDateFormat
expect parseDateFromStr "2024W531" == Err InvalidDateFormat
expect parseDateFromStr "2024W010" == Err InvalidDateFormat
expect parseDateFromStr "2024W018" == Err InvalidDateFormat
expect parseDateFromStr "2024W0a2" == Err InvalidDateFormat

# OrdinalDateExtended
expect parseDateFromStr "2024-023" == (19_723 + 22) * secondsPerDay * nanosPerSecond |> Num.toI128 |> fromNanosSinceEpoch |> Ok
expect parseDateFromStr "1970-001" == 0 |> Num.toI128 |> fromNanosSinceEpoch |> Ok
expect parseDateFromStr "1968-001" == -731 * secondsPerDay * nanosPerSecond |> Num.toI128 |> fromNanosSinceEpoch |> Ok
expect parseDateFromStr "2024-000" == Err InvalidDateFormat
expect parseDateFromStr "2024-367" == Err InvalidDateFormat
expect parseDateFromStr "2024-0a3" == Err InvalidDateFormat

# CalendarDateBasic
expect parseDateFromStr "20240123" == (19_723 + 22) * secondsPerDay * nanosPerSecond |> Num.toI128 |> fromNanosSinceEpoch |> Ok
expect parseDateFromStr "19700101" == 0 |> Num.toI128 |> fromNanosSinceEpoch |> Ok
expect parseDateFromStr "19680101" == -731 * secondsPerDay * nanosPerSecond |> Num.toI128 |> fromNanosSinceEpoch |> Ok
expect parseDateFromStr "20240100" == Err InvalidDateFormat
expect parseDateFromStr "20240132" == Err InvalidDateFormat
expect parseDateFromStr "20240001" == Err InvalidDateFormat
expect parseDateFromStr "20241301" == Err InvalidDateFormat
expect parseDateFromStr "2024a123" == Err InvalidDateFormat

# WeekDateExtended
expect parseDateFromStr "2024-W04-2" == (19_723 + 22) * secondsPerDay * nanosPerSecond |> Num.toI128 |> fromNanosSinceEpoch |> Ok
expect parseDateFromStr "1970-W01-1" == 0 |> Num.toI128 |> fromNanosSinceEpoch |> Ok
expect parseDateFromStr "1968-W01-1" == -731 * secondsPerDay * nanosPerSecond |> Num.toI128 |> fromNanosSinceEpoch |> Ok
expect parseDateFromStr "2024-W53-1" == Err InvalidDateFormat
expect parseDateFromStr "2024-W00-1" == Err InvalidDateFormat
expect parseDateFromStr "2024-W01-0" == Err InvalidDateFormat
expect parseDateFromStr "2024-W01-8" == Err InvalidDateFormat
expect parseDateFromStr "2024-Ww1-1" == Err InvalidDateFormat

# CalendarDateExtended
expect parseDateFromStr "2024-01-23" == (19_723 + 22) * secondsPerDay * nanosPerSecond |> Num.toI128 |> fromNanosSinceEpoch |> Ok
expect parseDateFromStr "1970-01-01" == 0 |> Num.toI128 |> fromNanosSinceEpoch |> Ok
expect parseDateFromStr "1968-01-01" == -731 * secondsPerDay * nanosPerSecond |> Num.toI128 |> fromNanosSinceEpoch |> Ok
expect parseDateFromStr "2024-01-00" == Err InvalidDateFormat
expect parseDateFromStr "2024-01-32" == Err InvalidDateFormat
expect parseDateFromStr "2024-00-01" == Err InvalidDateFormat
expect parseDateFromStr "2024-13-01" == Err InvalidDateFormat
expect parseDateFromStr "2024-0a-01" == Err InvalidDateFormat

# <---- parseTime ---->
# LocalTimeHour
expect parseTimeFromStr "11" == (11 * 60 * 60 * nanosPerSecond) |> Num.toU64 |> fromNanosSinceMidnight |> Ok
expect parseTimeFromStr "00Z" == 0 |> Num.toU64 |> fromNanosSinceMidnight |> Ok
expect parseTimeFromStr "T00" == 0 |> Num.toU64 |> fromNanosSinceMidnight |> Ok
expect parseTimeFromStr "T00Z" == 0 |> Num.toU64 |> fromNanosSinceMidnight |> Ok
expect parseTimeFromStr "T23" == (23 * 60 * 60 * nanosPerSecond) |> Num.toU64 |> fromNanosSinceMidnight |> Ok
expect parseTimeFromStr "T24" == (24 * 60 * 60 * nanosPerSecond) |> Num.toU64 |> fromNanosSinceMidnight |> Ok
expect parseTimeFromStr "T25" == Err InvalidTimeFormat
expect parseTimeFromStr "T0Z" == Err InvalidTimeFormat

# LocalTimeMinuteBasic
expect parseTimeFromStr "1111" == (11 * 60 * 60 * nanosPerSecond + 11 * 60 * nanosPerSecond) |> Num.toU64 |> fromNanosSinceMidnight |> Ok
expect parseTimeFromStr "0000Z" == 0 |> Num.toU64 |> fromNanosSinceMidnight |> Ok
expect parseTimeFromStr "T0000" == 0 |> Num.toU64 |> fromNanosSinceMidnight |> Ok
expect parseTimeFromStr "T0000Z" == 0 |> Num.toU64 |> fromNanosSinceMidnight |> Ok
expect parseTimeFromStr "T2359" == (23 * 60 * 60 * nanosPerSecond + 59 * 60 * nanosPerSecond) |> Num.toU64 |> fromNanosSinceMidnight |> Ok
expect parseTimeFromStr "T2400" == (24 * 60 * 60 * nanosPerSecond) |> Num.toU64 |> fromNanosSinceMidnight |> Ok
expect parseTimeFromStr "T2401" == Err InvalidTimeFormat
expect parseTimeFromStr "T000Z" == Err InvalidTimeFormat

# LocalTimeMinuteExtended
expect parseTimeFromStr "11:11" == (11 * 60 * 60 * nanosPerSecond + 11 * 60 * nanosPerSecond) |> Num.toU64 |> fromNanosSinceMidnight |> Ok
expect parseTimeFromStr "00:00Z" == 0 |> Num.toU64 |> fromNanosSinceMidnight |> Ok
expect parseTimeFromStr "T00:00" == 0 |> Num.toU64 |> fromNanosSinceMidnight |> Ok
expect parseTimeFromStr "T00:00Z" == 0 |> Num.toU64 |> fromNanosSinceMidnight |> Ok
expect parseTimeFromStr "T23:59" == (23 * 60 * 60 * nanosPerSecond + 59 * 60 * nanosPerSecond) |> Num.toU64 |> fromNanosSinceMidnight |> Ok
expect parseTimeFromStr "T24:00" == (24 * 60 * 60 * nanosPerSecond) |> Num.toU64 |> fromNanosSinceMidnight |> Ok
expect parseTimeFromStr "T24:01" == Err InvalidTimeFormat
expect parseTimeFromStr "T00:0Z" == Err InvalidTimeFormat

# LocalTimeBasic
expect parseTimeFromStr "111111" == (11 * 60 * 60 * nanosPerSecond + 11 * 60 * nanosPerSecond + 11 * nanosPerSecond) |> Num.toU64 |> fromNanosSinceMidnight |> Ok
expect parseTimeFromStr "000000Z" == 0 |> Num.toU64 |> fromNanosSinceMidnight |> Ok
expect parseTimeFromStr "T000000" == 0 |> Num.toU64 |> fromNanosSinceMidnight |> Ok
expect parseTimeFromStr "T000000Z" == 0 |> Num.toU64 |> fromNanosSinceMidnight |> Ok
expect parseTimeFromStr "T235959" == (23 * 60 * 60 * nanosPerSecond + 59 * 60 * nanosPerSecond + 59 * nanosPerSecond) |> Num.toU64 |> fromNanosSinceMidnight |> Ok
expect parseTimeFromStr "T240000" == (24 * 60 * 60 * nanosPerSecond) |> Num.toU64 |> fromNanosSinceMidnight |> Ok
expect parseTimeFromStr "T240001" == Err InvalidTimeFormat
expect parseTimeFromStr "T00000Z" == Err InvalidTimeFormat

# LocalTimeExtended
expect parseTimeFromStr "11:11:11" == (11 * 60 * 60 * nanosPerSecond + 11 * 60 * nanosPerSecond + 11 * nanosPerSecond) |> Num.toU64 |> fromNanosSinceMidnight |> Ok
expect parseTimeFromStr "00:00:00Z" == 0 |> Num.toU64 |> fromNanosSinceMidnight |> Ok
expect parseTimeFromStr "T00:00:00" == 0 |> Num.toU64 |> fromNanosSinceMidnight |> Ok
expect parseTimeFromStr "T00:00:00Z" == 0 |> Num.toU64 |> fromNanosSinceMidnight |> Ok
expect parseTimeFromStr "T23:59:59" == (23 * 60 * 60 * nanosPerSecond + 59 * 60 * nanosPerSecond + 59 * nanosPerSecond) |> Num.toU64 |> fromNanosSinceMidnight |> Ok
expect parseTimeFromStr "T24:00:00" == (24 * 60 * 60 * nanosPerSecond) |> Num.toU64 |> fromNanosSinceMidnight |> Ok
expect parseTimeFromStr "T24:00:01" == Err InvalidTimeFormat
expect parseTimeFromStr "T00:00:0Z" == Err InvalidTimeFormat


# <==== Utils.roc ====>
# <---- splitListAtIndices ---->
expect splitListAtIndices [1,2] [0,1,2] == [[1], [2]]
expect splitListAtIndices [1,2] [0] == [[1,2]]
expect splitListAtIndices [1,2] [1] == [[1], [2]]

# <---- validateUtf8SingleBytes ---->
expect validateUtf8SingleBytes [0b01111111]
expect !(validateUtf8SingleBytes [0b10000000, 0b00000001])
expect !("🔥" |> Str.toUtf8 |> validateUtf8SingleBytes)

# <---- utf8ToInt ---->
expect ['0','1','2','3','4','5','6','7','8','9'] |> utf8ToInt == Ok 123456789
expect utf8ToInt ['@'] == Err InvalidBytes
expect utf8ToInt ['/'] == Err InvalidBytes

# <---- utf8ToFrac ---->
expect
    when utf8ToFrac ['1', '2', '.', '3', '4', '5'] is
        Ok n -> n > 12.34499 && n < 12.34501
        _ -> Bool.false
expect
    when utf8ToFrac ['1', '2', ',', '3', '4', '5'] is
        Ok n -> n > 12.34499 && n < 12.34501
        _ -> Bool.false
expect
    when utf8ToFrac ['.', '1', '2', '3'] is
        Ok n -> n > 0.12299 && n < 0.12301
        _ -> Bool.false
expect
    when utf8ToFrac ['1', '2', '3'] is
        Ok n -> n > 122.99 && n < 123.01
        _ -> Bool.false
expect
    when utf8ToFrac ['1', '2', '3', '.'] is
        Ok n -> n > 122.99 && n < 123.01
        _ -> Bool.false
expect
    num = utf8ToFrac ['1', '2', 'Z']
    when num is
        Err InvalidBytes -> Bool.true
        _ -> Bool.false

# <---- numDaysSinceEpoch ---->
# expect numDaysSinceEpoch {year: 2024} == 19723 # Removed due to compiler bug with optional record fields
expect numDaysSinceEpoch {year: 1970, month: 12, day: 31} == 365 - 1
expect numDaysSinceEpoch {year: 1971, month: 1, day: 2} == 365 + 1
expect numDaysSinceEpoch {year: 2024, month: 1, day: 1} == 19723
expect numDaysSinceEpoch {year: 2024, month: 2, day: 1} == 19723 + 31
expect numDaysSinceEpoch {year: 2024, month: 12, day: 31} == 19723 + 366 - 1
expect numDaysSinceEpoch {year: 1969, month: 12, day: 31} == -1
expect numDaysSinceEpoch {year: 1969, month: 12, day: 30} == -2
expect numDaysSinceEpoch {year: 1969, month: 1, day: 1} == -365
expect numDaysSinceEpoch {year: 1968, month: 1, day: 1} == -365 - 366

# <---- numDaysSinceEpochToYear ---->
expect numDaysSinceEpochToYear 1968 == -365 - 366
expect numDaysSinceEpochToYear 1970 == 0
expect numDaysSinceEpochToYear 1971 == 365
expect numDaysSinceEpochToYear 1972 == 365 + 365
expect numDaysSinceEpochToYear 1973 == 365 + 365 + 366
expect numDaysSinceEpochToYear 2024 == 19723

# <---- calendarWeekToDaysInYear ---->
expect calendarWeekToDaysInYear 1 1965 == 3
expect calendarWeekToDaysInYear 1 1964 == 0
expect calendarWeekToDaysInYear 1 1970  == 0
expect calendarWeekToDaysInYear 1 1971 == 3
expect calendarWeekToDaysInYear 1 1972 == 2
expect calendarWeekToDaysInYear 1 1973 == 0
expect calendarWeekToDaysInYear 2 2024 == 7

