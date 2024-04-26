interface Tests
    exposes []
    imports [
        Const.{
            nanosPerDay,
            nanosPerHour,
            nanosPerMinute,
            nanosPerSecond,
            secondsPerDay,
        },
        Date,
        Date.{ Date },
        DateTime,
        DateTime.{ DateTime },
        IsoToUtc.{
            parseDateFromStr,
            parseDateTimeFromStr,
            parseTimeFromStr,
        },
        Time,
        Time.{ Time },
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
            splitUtf8AndKeepDelimiters,
            utf8ToFrac,
            utf8ToInt,
            utf8ToIntSigned,
            validateUtf8SingleBytes,
            ymdToDaysInYear,
        },
        Unsafe.{ unwrap },
    ]

# <==== IsoToUtc.roc ====>
# <---- parseDate ---->
# parseCalendarDateCentury
# 1
expect parseDateFromStr "20" == (10_957) * secondsPerDay * nanosPerSecond |> Num.toI128 |> Utc.fromNanosSinceEpoch |> Ok
expect Date.fromIsoStr "20" == Date.fromYmd 2000 1 1 |> Ok
expect Date.fromIsoStr "20" |> unwrap "Date.fromIsoStr '20'" |> Date.toUtc == (10_957) * secondsPerDay * nanosPerSecond |> Num.toI128 |> Utc.fromNanosSinceEpoch
# 2
expect parseDateFromStr "19" == -25_567 * secondsPerDay * nanosPerSecond |> Num.toI128 |> fromNanosSinceEpoch |> Ok
expect Date.fromIsoStr "19" == Date.fromYmd 1900 1 1 |> Ok
expect Date.fromIsoStr "19" |> unwrap "Date.fromIsoStr '19'" |> Date.toUtc == -25_567 * secondsPerDay * nanosPerSecond |> Num.toI128 |> Utc.fromNanosSinceEpoch
# 3
expect parseDateFromStr "ab" == Err InvalidDateFormat
expect Date.fromIsoStr "ab" == Err InvalidDateFormat

# parseCalendarDateYear
# 4
expect parseDateFromStr "2024" == (19_723) * secondsPerDay * nanosPerSecond |> Num.toI128 |> Utc.fromNanosSinceEpoch |> Ok
expect Date.fromIsoStr "2024" == Date.fromYmd 2024 1 1 |> Ok
expect Date.fromIsoStr "2024" |> unwrap "Date.fromIsoStr '2024'" |> Date.toUtc == (19_723) * secondsPerDay * nanosPerSecond |> Num.toI128 |> Utc.fromNanosSinceEpoch
# 5
expect parseDateFromStr "1970" == 0 |> Num.toI128 |> fromNanosSinceEpoch |> Ok
expect Date.fromIsoStr "1970" == Date.fromYmd 1970 1 1 |> Ok
expect Date.fromIsoStr "1970" |> unwrap "Date.fromIsoStr '1970'" |> Date.toUtc == 0 |> Num.toI128 |> Utc.fromNanosSinceEpoch
# 6
expect parseDateFromStr "1968" == -731 * secondsPerDay * nanosPerSecond |> Num.toI128 |> fromNanosSinceEpoch |> Ok
expect Date.fromIsoStr "1968" == Date.fromYmd 1968 1 1 |> Ok
expect Date.fromIsoStr "1968" |> unwrap "Date.fromIsoStr '1968'" |> Date.toUtc == -731 * secondsPerDay * nanosPerSecond |> Num.toI128 |> Utc.fromNanosSinceEpoch
# 7
expect parseDateFromStr "202f" == Err InvalidDateFormat
expect Date.fromIsoStr "202f" == Err InvalidDateFormat

# parseWeekDateReducedBasic
# 8
expect parseDateFromStr "2024W04" == (19_723 + 21) * secondsPerDay * nanosPerSecond |> Num.toI128 |> fromNanosSinceEpoch |> Ok
expect Date.fromIsoStr "2024W04" == Date.fromYmd 2024 1 22 |> Ok
expect Date.fromIsoStr "2024W04" |> unwrap "Date.fromIsoStr '2024W04'" |> Date.toUtc == (19_723 + 21) * secondsPerDay * nanosPerSecond |> Num.toI128 |> Utc.fromNanosSinceEpoch
# 9
expect parseDateFromStr "1970W01" == 0 |> Num.toI128 |> fromNanosSinceEpoch |> Ok
expect Date.fromIsoStr "1970W01" == Date.fromYmd 1970 1 1 |> Ok
expect Date.fromIsoStr "1970W01" |> unwrap "Date.fromIsoStr '1970W01'" |> Date.toUtc == 0 |> Num.toI128 |> Utc.fromNanosSinceEpoch
# 10
expect parseDateFromStr "1968W01" == -731 * secondsPerDay * nanosPerSecond |> Num.toI128 |> fromNanosSinceEpoch |> Ok
expect Date.fromIsoStr "1968W01" == Date.fromYmd 1968 1 1 |> Ok
expect Date.fromIsoStr "1968W01" |> unwrap "Date.fromIsoStr '1968W01'" |> Date.toUtc == -731 * secondsPerDay * nanosPerSecond |> Num.toI128 |> Utc.fromNanosSinceEpoch
# 11
expect parseDateFromStr "2024W53" == Err InvalidDateFormat
expect Date.fromIsoStr "2024W53" == Err InvalidDateFormat
# 12
expect parseDateFromStr "2024W00" == Err InvalidDateFormat
expect Date.fromIsoStr "2024W00" == Err InvalidDateFormat
# 13
expect parseDateFromStr "2024Www" == Err InvalidDateFormat
expect Date.fromIsoStr "2024Www" == Err InvalidDateFormat

# parseCalendarDateMonth
# 14
expect parseDateFromStr "2024-02" == (19_723 + 31) * secondsPerDay * nanosPerSecond |> Num.toI128 |> fromNanosSinceEpoch |> Ok
expect Date.fromIsoStr "2024-02" == Date.fromYmd 2024 2 1 |> Ok
expect Date.fromIsoStr "2024-02" |> unwrap "Date.fromIsoStr '2024-02'" |> Date.toUtc == (19_723 + 31) * secondsPerDay * nanosPerSecond |> Num.toI128 |> Utc.fromNanosSinceEpoch
# 15
expect parseDateFromStr "1970-01" == 0 |> Num.toI128 |> fromNanosSinceEpoch |> Ok
expect Date.fromIsoStr "1970-01" == Date.fromYmd 1970 1 1 |> Ok
expect Date.fromIsoStr "1970-01" |> unwrap "Date.fromIsoStr '1970-01'" |> Date.toUtc == 0 |> Num.toI128 |> Utc.fromNanosSinceEpoch
# 16
expect parseDateFromStr "1968-01" == -731 * secondsPerDay * nanosPerSecond |> Num.toI128 |> fromNanosSinceEpoch |> Ok
expect Date.fromIsoStr "1968-01" == Date.fromYmd 1968 1 1 |> Ok
expect Date.fromIsoStr "1968-01" |> unwrap "Date.fromIsoStr '1968-01'" |> Date.toUtc == -731 * secondsPerDay * nanosPerSecond |> Num.toI128 |> Utc.fromNanosSinceEpoch
# 17
expect parseDateFromStr "2024-13" == Err InvalidDateFormat
expect Date.fromIsoStr "2024-13" == Err InvalidDateFormat
# 18
expect parseDateFromStr "2024-00" == Err InvalidDateFormat
expect Date.fromIsoStr "2024-00" == Err InvalidDateFormat
# 19
expect parseDateFromStr "2024-0a" == Err InvalidDateFormat
expect Date.fromIsoStr "2024-0a" == Err InvalidDateFormat


# parseOrdinalDateBasic
# 20
expect parseDateFromStr "2024023" == (19_723 + 22) * secondsPerDay * nanosPerSecond |> Num.toI128 |> fromNanosSinceEpoch |> Ok
expect Date.fromIsoStr "2024023" == Date.fromYmd 2024 1 23 |> Ok
expect Date.fromIsoStr "2024023" |> unwrap "Date.fromIsoStr '2024023'" |> Date.toUtc == (19_723 + 22) * secondsPerDay * nanosPerSecond |> Num.toI128 |> Utc.fromNanosSinceEpoch
# 21
expect parseDateFromStr "1970001" == 0 |> Num.toI128 |> fromNanosSinceEpoch |> Ok
expect Date.fromIsoStr "1970001" == Date.fromYmd 1970 1 1 |> Ok
expect Date.fromIsoStr "1970001" |> unwrap "Date.fromIsoStr '1970001'" |> Date.toUtc == 0 |> Num.toI128 |> Utc.fromNanosSinceEpoch
# 22
expect parseDateFromStr "1968001" == -731 * secondsPerDay * nanosPerSecond |> Num.toI128 |> fromNanosSinceEpoch |> Ok
expect Date.fromIsoStr "1968001" == Date.fromYmd 1968 1 1 |> Ok
expect Date.fromIsoStr "1968001" |> unwrap "Date.fromIsoStr '1968001'" |> Date.toUtc == -731 * secondsPerDay * nanosPerSecond |> Num.toI128 |> Utc.fromNanosSinceEpoch
# 23
expect parseDateFromStr "2024000" == Err InvalidDateFormat
expect Date.fromIsoStr "2024000" == Err InvalidDateFormat
# 24
expect parseDateFromStr "2024367" == Err InvalidDateFormat
expect Date.fromIsoStr "2024367" == Err InvalidDateFormat
# 25
expect parseDateFromStr "2024a23" == Err InvalidDateFormat
expect Date.fromIsoStr "2024a23" == Err InvalidDateFormat

# parseWeekDateReducedExtended
# 26
expect parseDateFromStr "2024-W04" == (19_723 + 21) * secondsPerDay * nanosPerSecond |> Num.toI128 |> fromNanosSinceEpoch |> Ok
expect Date.fromIsoStr "2024-W04" == Date.fromYmd 2024 1 22 |> Ok
expect Date.fromIsoStr "2024-W04" |> unwrap "Date.fromIsoStr '2024-W04'" |> Date.toUtc == (19_723 + 21) * secondsPerDay * nanosPerSecond |> Num.toI128 |> Utc.fromNanosSinceEpoch
# 27
expect parseDateFromStr "1970-W01" == 0 |> Num.toI128 |> fromNanosSinceEpoch |> Ok
expect Date.fromIsoStr "1970-W01" == Date.fromYmd 1970 1 1 |> Ok
expect Date.fromIsoStr "1970-W01" |> unwrap "Date.fromIsoStr '1970-W01'" |> Date.toUtc == 0 |> Num.toI128 |> Utc.fromNanosSinceEpoch
# 28
expect parseDateFromStr "1968-W01" == -731 * secondsPerDay * nanosPerSecond |> Num.toI128 |> fromNanosSinceEpoch |> Ok
expect Date.fromIsoStr "1968-W01" == Date.fromYmd 1968 1 1 |> Ok
expect Date.fromIsoStr "1968-W01" |> unwrap "Date.fromIsoStr '1968-W01'" |> Date.toUtc == -731 * secondsPerDay * nanosPerSecond |> Num.toI128 |> Utc.fromNanosSinceEpoch
# 29
expect parseDateFromStr "2024-W53" == Err InvalidDateFormat
expect Date.fromIsoStr "2024-W53" == Err InvalidDateFormat
# 30
expect parseDateFromStr "2024-W00" == Err InvalidDateFormat
expect Date.fromIsoStr "2024-W00" == Err InvalidDateFormat
# 31
expect parseDateFromStr "2024-Ww1" == Err InvalidDateFormat
expect Date.fromIsoStr "2024-Ww1" == Err InvalidDateFormat

# parseWeekDateBasic
# 32
expect parseDateFromStr "2024W042" == (19_723 + 22) * secondsPerDay * nanosPerSecond |> Num.toI128 |> fromNanosSinceEpoch |> Ok
expect Date.fromIsoStr "2024W042" == Date.fromYmd 2024 1 23 |> Ok
expect Date.fromIsoStr "2024W042" |> unwrap "Date.fromIsoStr '2024W042'" |> Date.toUtc == (19_723 + 22) * secondsPerDay * nanosPerSecond |> Num.toI128 |> Utc.fromNanosSinceEpoch
# 33
expect parseDateFromStr "1970W011" == 0 |> Num.toI128 |> fromNanosSinceEpoch |> Ok
expect Date.fromIsoStr "1970W011" == Date.fromYmd 1970 1 1 |> Ok
expect Date.fromIsoStr "1970W011" |> unwrap "Date.fromIsoStr '1970W011'" |> Date.toUtc == 0 |> Num.toI128 |> Utc.fromNanosSinceEpoch
# 34
expect parseDateFromStr "1970W524" == 364 * secondsPerDay * nanosPerSecond |> Num.toI128 |> fromNanosSinceEpoch |> Ok
expect Date.fromIsoStr "1970W524" == Date.fromYmd 1970 12 31 |> Ok
expect Date.fromIsoStr "1970W524" |> unwrap "Date.fromIsoStr '1970W524'" |> Date.toUtc == 364 * secondsPerDay * nanosPerSecond |> Num.toI128 |> Utc.fromNanosSinceEpoch
# 35
expect parseDateFromStr "1970W525" == parseDateFromStr "19710101"
expect Date.fromIsoStr "1970W525" == Date.fromYmd 1971 1 1 |> Ok
expect Date.fromIsoStr "1970W525" |> unwrap "Date.fromIsoStr '1970W525'" |> Date.toUtc == 365 * secondsPerDay * nanosPerSecond |> Num.toI128 |> Utc.fromNanosSinceEpoch
# 36
expect parseDateFromStr "1968W011" == -731 * secondsPerDay * nanosPerSecond |> Num.toI128 |> fromNanosSinceEpoch |> Ok
expect Date.fromIsoStr "1968W011" == Date.fromYmd 1968 1 1 |> Ok
expect Date.fromIsoStr "1968W011" |> unwrap "Date.fromIsoStr '1968W011'" |> Date.toUtc == -731 * secondsPerDay * nanosPerSecond |> Num.toI128 |> Utc.fromNanosSinceEpoch
# 37
expect parseDateFromStr "2024W001" == Err InvalidDateFormat
expect Date.fromIsoStr "2024W001" == Err InvalidDateFormat
# 38
expect parseDateFromStr "2024W531" == Err InvalidDateFormat
expect Date.fromIsoStr "2024W531" == Err InvalidDateFormat
# 39
expect parseDateFromStr "2024W010" == Err InvalidDateFormat
expect Date.fromIsoStr "2024W010" == Err InvalidDateFormat
# 40
expect parseDateFromStr "2024W018" == Err InvalidDateFormat
expect Date.fromIsoStr "2024W018" == Err InvalidDateFormat
# 41
expect parseDateFromStr "2024W0a2" == Err InvalidDateFormat
expect Date.fromIsoStr "2024W0a2" == Err InvalidDateFormat

# parseOrdinalDateExtended
# 42
expect parseDateFromStr "2024-023" == (19_723 + 22) * secondsPerDay * nanosPerSecond |> Num.toI128 |> fromNanosSinceEpoch |> Ok
expect Date.fromIsoStr "2024-023" == Date.fromYmd 2024 1 23 |> Ok
expect Date.fromIsoStr "2024-023" |> unwrap "Date.fromIsoStr '2024-023'" |> Date.toUtc == (19_723 + 22) * secondsPerDay * nanosPerSecond |> Num.toI128 |> Utc.fromNanosSinceEpoch
# 43
expect parseDateFromStr "1970-001" == 0 |> Num.toI128 |> fromNanosSinceEpoch |> Ok
expect Date.fromIsoStr "1970-001" == Date.fromYmd 1970 1 1 |> Ok
expect Date.fromIsoStr "1970-001" |> unwrap "Date.fromIsoStr '1970-001'" |> Date.toUtc == 0 |> Num.toI128 |> Utc.fromNanosSinceEpoch
# 44
expect parseDateFromStr "1968-001" == -731 * secondsPerDay * nanosPerSecond |> Num.toI128 |> fromNanosSinceEpoch |> Ok
expect Date.fromIsoStr "1968-001" == Date.fromYmd 1968 1 1 |> Ok
expect Date.fromIsoStr "1968-001" |> unwrap "Date.fromIsoStr '1968-001'" |> Date.toUtc == -731 * secondsPerDay * nanosPerSecond |> Num.toI128 |> Utc.fromNanosSinceEpoch
# 45
expect parseDateFromStr "2024-000" == Err InvalidDateFormat
expect Date.fromIsoStr "2024-000" == Err InvalidDateFormat
# 46
expect parseDateFromStr "2024-367" == Err InvalidDateFormat
expect Date.fromIsoStr "2024-367" == Err InvalidDateFormat
# 47
expect parseDateFromStr "2024-0a3" == Err InvalidDateFormat
expect Date.fromIsoStr "2024-0a3" == Err InvalidDateFormat

# parseCalendarDateBasic
# 48
expect parseDateFromStr "20240123" == (19_723 + 22) * secondsPerDay * nanosPerSecond |> Num.toI128 |> fromNanosSinceEpoch |> Ok
expect Date.fromIsoStr "20240123" == Date.fromYmd 2024 1 23 |> Ok
expect Date.fromIsoStr "20240123" |> unwrap "Date.fromIsoStr '20240123'" |> Date.toUtc == (19_723 + 22) * secondsPerDay * nanosPerSecond |> Num.toI128 |> Utc.fromNanosSinceEpoch
# 49
expect parseDateFromStr "19700101" == 0 |> Num.toI128 |> fromNanosSinceEpoch |> Ok
expect Date.fromIsoStr "19700101" == Date.fromYmd 1970 1 1 |> Ok
expect Date.fromIsoStr "19700101" |> unwrap "Date.fromIsoStr '19700101'" |> Date.toUtc == 0 |> Num.toI128 |> Utc.fromNanosSinceEpoch
# 50
expect parseDateFromStr "19680101" == -731 * secondsPerDay * nanosPerSecond |> Num.toI128 |> fromNanosSinceEpoch |> Ok
expect Date.fromIsoStr "19680101" == Date.fromYmd 1968 1 1 |> Ok
expect Date.fromIsoStr "19680101" |> unwrap "Date.fromIsoStr '19680101'" |> Date.toUtc == -731 * secondsPerDay * nanosPerSecond |> Num.toI128 |> Utc.fromNanosSinceEpoch
# 51
expect parseDateFromStr "20240100" == Err InvalidDateFormat
expect Date.fromIsoStr "20240100" == Err InvalidDateFormat
# 52
expect parseDateFromStr "20240132" == Err InvalidDateFormat
expect Date.fromIsoStr "20240132" == Err InvalidDateFormat
# 53
expect parseDateFromStr "20240001" == Err InvalidDateFormat
expect Date.fromIsoStr "20240001" == Err InvalidDateFormat
# 54
expect parseDateFromStr "20241301" == Err InvalidDateFormat
expect Date.fromIsoStr "20241301" == Err InvalidDateFormat
# 55
expect parseDateFromStr "2024a123" == Err InvalidDateFormat
expect Date.fromIsoStr "2024a123" == Err InvalidDateFormat

# parseWeekDateExtended
# 56
expect parseDateFromStr "2024-W04-2" == (19_723 + 22) * secondsPerDay * nanosPerSecond |> Num.toI128 |> fromNanosSinceEpoch |> Ok
expect Date.fromIsoStr "2024-W04-2" == Date.fromYmd 2024 1 23 |> Ok
expect Date.fromIsoStr "2024-W04-2" |> unwrap "Date.fromIsoStr '2024-W04-2'" |> Date.toUtc == (19_723 + 22) * secondsPerDay * nanosPerSecond |> Num.toI128 |> Utc.fromNanosSinceEpoch
# 57
expect parseDateFromStr "1970-W01-1" == 0 |> Num.toI128 |> fromNanosSinceEpoch |> Ok
expect Date.fromIsoStr "1970-W01-1" == Date.fromYmd 1970 1 1 |> Ok
expect Date.fromIsoStr "1970-W01-1" |> unwrap "Date.fromIsoStr '1970-W01-1'" |> Date.toUtc == 0 |> Num.toI128 |> Utc.fromNanosSinceEpoch
# 58
expect parseDateFromStr "1968-W01-1" == -731 * secondsPerDay * nanosPerSecond |> Num.toI128 |> fromNanosSinceEpoch |> Ok
expect Date.fromIsoStr "1968-W01-1" == Date.fromYmd 1968 1 1 |> Ok
expect Date.fromIsoStr "1968-W01-1" |> unwrap "Date.fromIsoStr '1968-W01-1'" |> Date.toUtc == -731 * secondsPerDay * nanosPerSecond |> Num.toI128 |> Utc.fromNanosSinceEpoch
# 59
expect parseDateFromStr "2024-W53-1" == Err InvalidDateFormat
expect Date.fromIsoStr "2024-W53-1" == Err InvalidDateFormat
# 60
expect parseDateFromStr "2024-W00-1" == Err InvalidDateFormat
expect Date.fromIsoStr "2024-W00-1" == Err InvalidDateFormat
# 61
expect parseDateFromStr "2024-W01-0" == Err InvalidDateFormat
expect Date.fromIsoStr "2024-W01-0" == Err InvalidDateFormat
# 62
expect parseDateFromStr "2024-W01-8" == Err InvalidDateFormat
expect Date.fromIsoStr "2024-W01-8" == Err InvalidDateFormat
# 63
expect parseDateFromStr "2024-Ww1-1" == Err InvalidDateFormat
expect Date.fromIsoStr "2024-Ww1-1" == Err InvalidDateFormat

# parseCalendarDateExtended
# 64
expect parseDateFromStr "2024-01-23" == (19_723 + 22) * secondsPerDay * nanosPerSecond |> Num.toI128 |> fromNanosSinceEpoch |> Ok
expect Date.fromIsoStr "2024-01-23" == Date.fromYmd 2024 1 23 |> Ok
expect Date.fromIsoStr "2024-01-23" |> unwrap "Date.fromIsoStr '2024-01-23'" |> Date.toUtc == (19_723 + 22) * secondsPerDay * nanosPerSecond |> Num.toI128 |> Utc.fromNanosSinceEpoch
# 65
expect parseDateFromStr "1970-01-01" == 0 |> Num.toI128 |> fromNanosSinceEpoch |> Ok
expect Date.fromIsoStr "1970-01-01" == Date.fromYmd 1970 1 1 |> Ok
expect Date.fromIsoStr "1970-01-01" |> unwrap "Date.fromIsoStr '1970-01-01'" |> Date.toUtc == 0 |> Num.toI128 |> Utc.fromNanosSinceEpoch
# 66
expect parseDateFromStr "1968-01-01" == -731 * secondsPerDay * nanosPerSecond |> Num.toI128 |> fromNanosSinceEpoch |> Ok
expect Date.fromIsoStr "1968-01-01" == Date.fromYmd 1968 1 1 |> Ok
expect Date.fromIsoStr "1968-01-01" |> unwrap "Date.fromIsoStr '1968-01-01'" |> Date.toUtc == -731 * secondsPerDay * nanosPerSecond |> Num.toI128 |> Utc.fromNanosSinceEpoch
# 67
expect parseDateFromStr "2024-01-00" == Err InvalidDateFormat
expect Date.fromIsoStr "2024-01-00" == Err InvalidDateFormat
# 68
expect parseDateFromStr "2024-01-32" == Err InvalidDateFormat
expect Date.fromIsoStr "2024-01-32" == Err InvalidDateFormat
# 69
expect parseDateFromStr "2024-00-01" == Err InvalidDateFormat
expect Date.fromIsoStr "2024-00-01" == Err InvalidDateFormat
# 70
expect parseDateFromStr "2024-13-01" == Err InvalidDateFormat
expect Date.fromIsoStr "2024-13-01" == Err InvalidDateFormat
# 71
expect parseDateFromStr "2024-0a-01" == Err InvalidDateFormat
expect Date.fromIsoStr "2024-0a-01" == Err InvalidDateFormat

# <---- parseTime ---->
# parseLocalTimeHour
# 72
expect parseTimeFromStr "11" == (11 * nanosPerHour) |> Num.toI64 |> fromNanosSinceMidnight |> Ok
expect Time.fromIsoStr "11" == Time.fromHms 11 0 0 |> Ok
expect Time.fromIsoStr "11" |> unwrap "Time.fromIsoStr '11'" |> Time.toUtcTime == (11 * nanosPerHour) |> Num.toI64 |> UtcTime.fromNanosSinceMidnight
# 73
expect parseTimeFromStr "00Z" == 0 |> Num.toI64 |> fromNanosSinceMidnight |> Ok
expect Time.fromIsoStr "00Z" == Time.fromHms 0 0 0 |> Ok
expect Time.fromIsoStr "00Z" |> unwrap "Time.fromIsoStr '00Z'" |> Time.toUtcTime == 0 |> Num.toI64 |> UtcTime.fromNanosSinceMidnight
# 74
expect parseTimeFromStr "T00" == 0 |> Num.toI64 |> fromNanosSinceMidnight |> Ok
expect Time.fromIsoStr "T00" == Time.fromHms 0 0 0 |> Ok
expect Time.fromIsoStr "T00" |> unwrap "Time.fromIsoStr 'T00'" |> Time.toUtcTime == 0 |> Num.toI64 |> UtcTime.fromNanosSinceMidnight
# 75
expect parseTimeFromStr "T00Z" == 0 |> Num.toI64 |> fromNanosSinceMidnight |> Ok
expect Time.fromIsoStr "T00Z" == Time.fromHms 0 0 0 |> Ok
expect Time.fromIsoStr "T00Z" |> unwrap "Time.fromIsoStr 'T00Z'" |> Time.toUtcTime == 0 |> Num.toI64 |> UtcTime.fromNanosSinceMidnight
# 76
expect parseTimeFromStr "T23" == (23 * nanosPerHour) |> Num.toI64 |> fromNanosSinceMidnight |> Ok
expect Time.fromIsoStr "T23" == Time.fromHms 23 0 0 |> Ok
expect Time.fromIsoStr "T23" |> unwrap "Time.fromIsoStr 'T23'" |> Time.toUtcTime == (23 * nanosPerHour) |> Num.toI64 |> UtcTime.fromNanosSinceMidnight
# 77
expect parseTimeFromStr "T24" == (24 * nanosPerHour) |> Num.toI64 |> fromNanosSinceMidnight |> Ok
expect Time.fromIsoStr "T24" == Time.fromHms 24 0 0 |> Ok
expect Time.fromIsoStr "T24" |> unwrap "Time.fromIsoStr 'T24'" |> Time.toUtcTime == (24 * nanosPerHour) |> Num.toI64 |> UtcTime.fromNanosSinceMidnight
# 78
expect parseTimeFromStr "T25" == Err InvalidTimeFormat
expect Time.fromIsoStr "T25" == Err InvalidTimeFormat
# 79
expect parseTimeFromStr "T0Z" == Err InvalidTimeFormat
expect Time.fromIsoStr "T0Z" == Err InvalidTimeFormat

# parseLocalTimeMinuteBasic
# 80
expect parseTimeFromStr "1111" == (11 * nanosPerHour + 11 * nanosPerMinute) |> Num.toI64 |> fromNanosSinceMidnight |> Ok
expect Time.fromIsoStr "1111" == Time.fromHms 11 11 0 |> Ok
expect Time.fromIsoStr "1111" |> unwrap "Time.fromIsoStr '1111'" |> Time.toUtcTime == (11 * nanosPerHour + 11 * nanosPerMinute) |> Num.toI64 |> UtcTime.fromNanosSinceMidnight
# 81
expect parseTimeFromStr "0000Z" == 0 |> Num.toI64 |> fromNanosSinceMidnight |> Ok
expect Time.fromIsoStr "0000Z" == Time.fromHms 0 0 0 |> Ok
expect Time.fromIsoStr "0000Z" |> unwrap "Time.fromIsoStr '0000Z'" |> Time.toUtcTime == 0 |> Num.toI64 |> UtcTime.fromNanosSinceMidnight
# 82
expect parseTimeFromStr "T0000" == 0 |> Num.toI64 |> fromNanosSinceMidnight |> Ok
expect Time.fromIsoStr "T0000" == Time.fromHms 0 0 0 |> Ok
expect Time.fromIsoStr "T0000" |> unwrap "Time.fromIsoStr 'T0000'" |> Time.toUtcTime == 0 |> Num.toI64 |> UtcTime.fromNanosSinceMidnight
# 83
expect parseTimeFromStr "T0000Z" == 0 |> Num.toI64 |> fromNanosSinceMidnight |> Ok
expect Time.fromIsoStr "T0000Z" == Time.fromHms 0 0 0 |> Ok
expect Time.fromIsoStr "T0000Z" |> unwrap "Time.fromIsoStr 'T0000Z'" |> Time.toUtcTime == 0 |> Num.toI64 |> UtcTime.fromNanosSinceMidnight
# 84
expect parseTimeFromStr "T2359" == (23 * nanosPerHour + 59 * nanosPerMinute) |> Num.toI64 |> fromNanosSinceMidnight |> Ok
expect Time.fromIsoStr "T2359" == Time.fromHms 23 59 0 |> Ok
expect Time.fromIsoStr "T2359" |> unwrap "Time.fromIsoStr 'T2359'" |> Time.toUtcTime == (23 * nanosPerHour + 59 * nanosPerMinute) |> Num.toI64 |> UtcTime.fromNanosSinceMidnight
# 85
expect parseTimeFromStr "T2400" == (24 * nanosPerHour) |> Num.toI64 |> fromNanosSinceMidnight |> Ok
expect Time.fromIsoStr "T2400" == Time.fromHms 24 0 0 |> Ok
expect Time.fromIsoStr "T2400" |> unwrap "Time.fromIsoStr 'T2400'" |> Time.toUtcTime == (24 * nanosPerHour) |> Num.toI64 |> UtcTime.fromNanosSinceMidnight
# 86
expect parseTimeFromStr "T2401" == Err InvalidTimeFormat
expect Time.fromIsoStr "T2401" == Err InvalidTimeFormat
# 87
expect parseTimeFromStr "T000Z" == Err InvalidTimeFormat
expect Time.fromIsoStr "T000Z" == Err InvalidTimeFormat

# parseLocalTimeMinuteExtended
# 88
expect parseTimeFromStr "11:11" == (11 * nanosPerHour + 11 * nanosPerMinute) |> Num.toI64 |> fromNanosSinceMidnight |> Ok
expect Time.fromIsoStr "11:11" == Time.fromHms 11 11 0 |> Ok
expect Time.fromIsoStr "11:11" |> unwrap "Time.fromIsoStr '11:11'" |> Time.toUtcTime == (11 * nanosPerHour + 11 * nanosPerMinute) |> Num.toI64 |> UtcTime.fromNanosSinceMidnight
# 89
expect parseTimeFromStr "00:00Z" == 0 |> Num.toI64 |> fromNanosSinceMidnight |> Ok
expect Time.fromIsoStr "00:00Z" == Time.midnight |> Ok
expect Time.fromIsoStr "00:00Z" |> unwrap "Time.fromIsoStr '00:00Z'" |> Time.toUtcTime == 0 |> Num.toI64 |> UtcTime.fromNanosSinceMidnight
# 90
expect parseTimeFromStr "T00:00" == 0 |> Num.toI64 |> fromNanosSinceMidnight |> Ok
expect Time.fromIsoStr "T00:00" == Time.midnight |> Ok
expect Time.fromIsoStr "T00:00" |> unwrap "Time.fromIsoStr 'T00:00'" |> Time.toUtcTime == 0 |> Num.toI64 |> UtcTime.fromNanosSinceMidnight
# 91
expect parseTimeFromStr "T00:00Z" == 0 |> Num.toI64 |> fromNanosSinceMidnight |> Ok
expect Time.fromIsoStr "T00:00Z" == Time.midnight |> Ok
expect Time.fromIsoStr "T00:00Z" |> unwrap "Time.fromIsoStr 'T00:00Z'" |> Time.toUtcTime == 0 |> Num.toI64 |> UtcTime.fromNanosSinceMidnight
# 92
expect parseTimeFromStr "T23:59" == (23 * nanosPerHour + 59 * nanosPerMinute) |> Num.toI64 |> fromNanosSinceMidnight |> Ok
expect Time.fromIsoStr "T23:59" == Time.fromHms 23 59 0 |> Ok
expect Time.fromIsoStr "T23:59" |> unwrap "Time.fromIsoStr 'T23:59'" |> Time.toUtcTime == (23 * nanosPerHour + 59 * nanosPerMinute) |> Num.toI64 |> UtcTime.fromNanosSinceMidnight
# 93
expect parseTimeFromStr "T24:00" == (24 * nanosPerHour) |> Num.toI64 |> fromNanosSinceMidnight |> Ok
expect Time.fromIsoStr "T24:00" == Time.fromHms 24 0 0 |> Ok
expect Time.fromIsoStr "T24:00" |> unwrap "Time.fromIsoStr 'T24:00'" |> Time.toUtcTime == (24 * nanosPerHour) |> Num.toI64 |> UtcTime.fromNanosSinceMidnight
# 94
expect parseTimeFromStr "T24:01" == Err InvalidTimeFormat
expect Time.fromIsoStr "T24:01" == Err InvalidTimeFormat
# 95
expect parseTimeFromStr "T00:0Z" == Err InvalidTimeFormat
expect Time.fromIsoStr "T00:0Z" == Err InvalidTimeFormat

# parseLocalTimeBasic
# 96
expect parseTimeFromStr "111111" == (11 * nanosPerHour + 11 * nanosPerMinute + 11 * nanosPerSecond) |> Num.toI64 |> fromNanosSinceMidnight |> Ok
expect Time.fromIsoStr "111111" == Time.fromHms 11 11 11 |> Ok
expect Time.fromIsoStr "111111" |> unwrap "Time.fromIsoStr '111111'" |> Time.toUtcTime == (11 * nanosPerHour + 11 * nanosPerMinute + 11 * nanosPerSecond) |> Num.toI64 |> UtcTime.fromNanosSinceMidnight
# 97
expect parseTimeFromStr "000000Z" == 0 |> Num.toI64 |> fromNanosSinceMidnight |> Ok
expect Time.fromIsoStr "000000Z" == Time.midnight |> Ok
expect Time.fromIsoStr "000000Z" |> unwrap "Time.fromIsoStr '000000Z'" |> Time.toUtcTime == 0 |> Num.toI64 |> UtcTime.fromNanosSinceMidnight
# 98
expect parseTimeFromStr "T000000" == 0 |> Num.toI64 |> fromNanosSinceMidnight |> Ok
expect Time.fromIsoStr "T000000" == Time.midnight |> Ok
expect Time.fromIsoStr "T000000" |> unwrap "Time.fromIsoStr 'T000000'" |> Time.toUtcTime == 0 |> Num.toI64 |> UtcTime.fromNanosSinceMidnight
# 99
expect parseTimeFromStr "T000000Z" == 0 |> Num.toI64 |> fromNanosSinceMidnight |> Ok
expect Time.fromIsoStr "T000000Z" == Time.midnight |> Ok
expect Time.fromIsoStr "T000000Z" |> unwrap "Time.fromIsoStr 'T000000Z'" |> Time.toUtcTime == 0 |> Num.toI64 |> UtcTime.fromNanosSinceMidnight
# 100
expect parseTimeFromStr "T235959" == (23 * nanosPerHour + 59 * nanosPerMinute + 59 * nanosPerSecond) |> Num.toI64 |> fromNanosSinceMidnight |> Ok
expect Time.fromIsoStr "T235959" == Time.fromHms 23 59 59 |> Ok
expect Time.fromIsoStr "T235959" |> unwrap "Time.fromIsoStr 'T235959'" |> Time.toUtcTime == (23 * nanosPerHour + 59 * nanosPerMinute + 59 * nanosPerSecond) |> Num.toI64 |> UtcTime.fromNanosSinceMidnight
# 101
expect parseTimeFromStr "T240000" == (24 * nanosPerHour) |> Num.toI64 |> fromNanosSinceMidnight |> Ok
expect Time.fromIsoStr "T240000" == Time.fromHms 24 0 0 |> Ok
expect Time.fromIsoStr "T240000" |> unwrap "Time.fromIsoStr 'T240000'" |> Time.toUtcTime == (24 * nanosPerHour) |> Num.toI64 |> UtcTime.fromNanosSinceMidnight
# 102
expect parseTimeFromStr "T240001" == Err InvalidTimeFormat
expect Time.fromIsoStr "T240001" == Err InvalidTimeFormat
# 103
expect parseTimeFromStr "T00000Z" == Err InvalidTimeFormat
expect Time.fromIsoStr "T00000Z" == Err InvalidTimeFormat

# parseLocalTimeExtended
# 104
expect parseTimeFromStr "11:11:11" == (11 * nanosPerHour + 11 * nanosPerMinute + 11 * nanosPerSecond) |> Num.toI64 |> fromNanosSinceMidnight |> Ok
expect Time.fromIsoStr "11:11:11" == Time.fromHms 11 11 11 |> Ok
expect Time.fromIsoStr "11:11:11" |> unwrap "Time.fromIsoStr '11:11:11'" |> Time.toUtcTime == (11 * nanosPerHour + 11 * nanosPerMinute + 11 * nanosPerSecond) |> Num.toI64 |> UtcTime.fromNanosSinceMidnight
# 105
expect parseTimeFromStr "00:00:00Z" == 0 |> Num.toI64 |> fromNanosSinceMidnight |> Ok
expect Time.fromIsoStr "00:00:00Z" == Time.midnight |> Ok
expect Time.fromIsoStr "00:00:00Z" |> unwrap "Time.fromIsoStr '00:00:00Z'" |> Time.toUtcTime == 0 |> Num.toI64 |> UtcTime.fromNanosSinceMidnight
# 106
expect parseTimeFromStr "T00:00:00" == 0 |> Num.toI64 |> fromNanosSinceMidnight |> Ok
expect Time.fromIsoStr "T00:00:00" == Time.midnight |> Ok
expect Time.fromIsoStr "T00:00:00" |> unwrap "Time.fromIsoStr 'T00:00:00'" |> Time.toUtcTime == 0 |> Num.toI64 |> UtcTime.fromNanosSinceMidnight
# 107
expect parseTimeFromStr "T00:00:00Z" == 0 |> Num.toI64 |> fromNanosSinceMidnight |> Ok
expect Time.fromIsoStr "T00:00:00Z" == Time.midnight |> Ok
expect Time.fromIsoStr "T00:00:00Z" |> unwrap "Time.fromIsoStr 'T00:00:00Z'" |> Time.toUtcTime == 0 |> Num.toI64 |> UtcTime.fromNanosSinceMidnight
# 108
expect parseTimeFromStr "T23:59:59" == (23 * nanosPerHour + 59 * nanosPerMinute + 59 * nanosPerSecond) |> Num.toI64 |> fromNanosSinceMidnight |> Ok
expect Time.fromIsoStr "T23:59:59" == Time.fromHms 23 59 59 |> Ok
expect Time.fromIsoStr "T23:59:59" |> unwrap "Time.fromIsoStr 'T23:59:59'" |> Time.toUtcTime == (23 * nanosPerHour + 59 * nanosPerMinute + 59 * nanosPerSecond) |> Num.toI64 |> UtcTime.fromNanosSinceMidnight
# 109
expect parseTimeFromStr "T24:00:00" == (24 * nanosPerHour) |> Num.toI64 |> fromNanosSinceMidnight |> Ok
expect Time.fromIsoStr "T24:00:00" == Time.fromHms 24 0 0 |> Ok
expect Time.fromIsoStr "T24:00:00" |> unwrap "Time.fromIsoStr 'T24:00:00'" |> Time.toUtcTime == (24 * nanosPerHour) |> Num.toI64 |> UtcTime.fromNanosSinceMidnight
# 110
expect parseTimeFromStr "T24:00:01" == Err InvalidTimeFormat
expect Time.fromIsoStr "T24:00:01" == Err InvalidTimeFormat
# 111
expect parseTimeFromStr "T00:00:0Z" == Err InvalidTimeFormat
expect Time.fromIsoStr "T00:00:0Z" == Err InvalidTimeFormat

# parseFractionalTime
# 112
expect parseTimeFromStr "12.500" == (12 * nanosPerHour + 30 * nanosPerMinute) |> Num.toI64 |> fromNanosSinceMidnight |> Ok
expect Time.fromIsoStr "12.500" == Time.fromHms 12 30 0 |> Ok
expect Time.fromIsoStr "12.500" |> unwrap "Time.fromIsoStr '12.500'" |> Time.toUtcTime == (12 * nanosPerHour + 30 * nanosPerMinute) |> Num.toI64 |> UtcTime.fromNanosSinceMidnight
# 113
expect parseTimeFromStr "12,500" == (12 * nanosPerHour + 30 * nanosPerMinute) |> Num.toI64 |> fromNanosSinceMidnight |> Ok
expect Time.fromIsoStr "12,500" == Time.fromHms 12 30 0 |> Ok
expect Time.fromIsoStr "12,500" |> unwrap "Time.fromIsoStr '12,500'" |> Time.toUtcTime == (12 * nanosPerHour + 30 * nanosPerMinute) |> Num.toI64 |> UtcTime.fromNanosSinceMidnight
# 114
expect parseTimeFromStr "1200.500" == (12 * nanosPerHour + 30 * nanosPerSecond) |> Num.toI64 |> fromNanosSinceMidnight |> Ok
expect Time.fromIsoStr "1200.500" == Time.fromHms 12 0 30 |> Ok
expect Time.fromIsoStr "1200.500" |> unwrap "Time.fromIsoStr '1200.500'" |> Time.toUtcTime == (12 * nanosPerHour + 30 * nanosPerSecond) |> Num.toI64 |> UtcTime.fromNanosSinceMidnight
# 115
expect parseTimeFromStr "12:00,500" == (12 * nanosPerHour + 30 * nanosPerSecond) |> Num.toI64 |> fromNanosSinceMidnight |> Ok
expect Time.fromIsoStr "12:00,500" == Time.fromHms 12 0 30 |> Ok
expect Time.fromIsoStr "12:00,500" |> unwrap "Time.fromIsoStr '12:00,500'" |> Time.toUtcTime == (12 * nanosPerHour + 30 * nanosPerSecond) |> Num.toI64 |> UtcTime.fromNanosSinceMidnight
# 116
expect parseTimeFromStr "12:00:00,123" == (12 * nanosPerHour + 123_000_000) |> Num.toI64 |> fromNanosSinceMidnight |> Ok
expect Time.fromIsoStr "12:00:00,123" == Time.fromHmsn 12 0 0 123_000_000 |> Ok
expect Time.fromIsoStr "12:00:00,123" |> unwrap "Time.fromIsoStr '12:00:00,123'" |> Time.toUtcTime == (12 * nanosPerHour + 123_000_000) |> Num.toI64 |> UtcTime.fromNanosSinceMidnight

# parseTime w/ offset
# 117
expect parseTimeFromStr "12:00:00+01" == (11 * nanosPerHour) |> Num.toI64 |> fromNanosSinceMidnight |> Ok
expect Time.fromIsoStr "12:00:00+01" == Time.fromHms 11 0 0 |> Ok
expect Time.fromIsoStr "12:00:00+01" |> unwrap "Time.fromIsoStr '12:00:00+01'" |> Time.toUtcTime == (11 * nanosPerHour) |> Num.toI64 |> UtcTime.fromNanosSinceMidnight
# 118
expect parseTimeFromStr "12:00:00-01" == (13 * nanosPerHour) |> Num.toI64 |> fromNanosSinceMidnight |> Ok
expect Time.fromIsoStr "12:00:00-01" == Time.fromHms 13 0 0 |> Ok
expect Time.fromIsoStr "12:00:00-01" |> unwrap "Time.fromIsoStr '12:00:00-01'" |> Time.toUtcTime == (13 * nanosPerHour) |> Num.toI64 |> UtcTime.fromNanosSinceMidnight
# 119
expect parseTimeFromStr "12:00:00+0100" == (11 * nanosPerHour) |> Num.toI64 |> fromNanosSinceMidnight |> Ok
expect Time.fromIsoStr "12:00:00+0100" == Time.fromHms 11 0 0 |> Ok
expect Time.fromIsoStr "12:00:00+0100" |> unwrap "Time.fromIsoStr '12:00:00+0100'" |> Time.toUtcTime == (11 * nanosPerHour) |> Num.toI64 |> UtcTime.fromNanosSinceMidnight
# 120
expect parseTimeFromStr "12:00:00-0100" == (13 * nanosPerHour) |> Num.toI64 |> fromNanosSinceMidnight |> Ok
expect Time.fromIsoStr "12:00:00-0100" == Time.fromHms 13 0 0 |> Ok
expect Time.fromIsoStr "12:00:00-0100" |> unwrap "Time.fromIsoStr '12:00:00-0100'" |> Time.toUtcTime == (13 * nanosPerHour) |> Num.toI64 |> UtcTime.fromNanosSinceMidnight
# 121
expect parseTimeFromStr "12:00:00+01:00" == (11 * nanosPerHour) |> Num.toI64 |> fromNanosSinceMidnight |> Ok
expect Time.fromIsoStr "12:00:00+01:00" == Time.fromHms 11 0 0 |> Ok
expect Time.fromIsoStr "12:00:00+01:00" |> unwrap "Time.fromIsoStr '12:00:00+01:00'" |> Time.toUtcTime == (11 * nanosPerHour) |> Num.toI64 |> UtcTime.fromNanosSinceMidnight
# 122
expect parseTimeFromStr "12:00:00-01:00" == (13 * nanosPerHour) |> Num.toI64 |> fromNanosSinceMidnight |> Ok
expect Time.fromIsoStr "12:00:00-01:00" == Time.fromHms 13 0 0 |> Ok
expect Time.fromIsoStr "12:00:00-01:00" |> unwrap "Time.fromIsoStr '12:00:00-01:00'" |> Time.toUtcTime == (13 * nanosPerHour) |> Num.toI64 |> UtcTime.fromNanosSinceMidnight
# 123
expect parseTimeFromStr "12:00:00+01:30" == (10 * nanosPerHour + 30 * nanosPerMinute) |> Num.toI64 |> fromNanosSinceMidnight |> Ok
expect Time.fromIsoStr "12:00:00+01:30" == Time.fromHms 10 30 0 |> Ok
expect Time.fromIsoStr "12:00:00+01:30" |> unwrap "Time.fromIsoStr '12:00:00+01:30'" |> Time.toUtcTime == (10 * nanosPerHour + 30 * nanosPerMinute) |> Num.toI64 |> UtcTime.fromNanosSinceMidnight
# 124
expect parseTimeFromStr "12:00:00-01:30" == (13 * nanosPerHour + 30 * nanosPerMinute) |> Num.toI64 |> fromNanosSinceMidnight |> Ok
expect Time.fromIsoStr "12:00:00-01:30" == Time.fromHms 13 30 0 |> Ok
expect Time.fromIsoStr "12:00:00-01:30" |> unwrap "Time.fromIsoStr '12:00:00-01:30'" |> Time.toUtcTime == (13 * nanosPerHour + 30 * nanosPerMinute) |> Num.toI64 |> UtcTime.fromNanosSinceMidnight
# 125
expect parseTimeFromStr "12.50+0030" == (12 * nanosPerHour) |> Num.toI64 |> fromNanosSinceMidnight |> Ok
expect Time.fromIsoStr "12.50+0030" == Time.fromHms 12 0 0 |> Ok
expect Time.fromIsoStr "12.50+0030" |> unwrap "Time.fromIsoStr '12.50+0030'" |> Time.toUtcTime == (12 * nanosPerHour) |> Num.toI64 |> UtcTime.fromNanosSinceMidnight
# 126
expect parseTimeFromStr "0000+1400" == (-14 * nanosPerHour) |> Num.toI64 |> fromNanosSinceMidnight |> Ok
expect Time.fromIsoStr "0000+1400" == Time.fromHms -14 0 0 |> Ok
expect Time.fromIsoStr "0000+1400" |> unwrap "Time.fromIsoStr '0000+1400'" |> Time.toUtcTime == (-14 * nanosPerHour) |> Num.toI64 |> UtcTime.fromNanosSinceMidnight
# 127
expect parseTimeFromStr "T24-1200" == (36 * nanosPerHour) |> Num.toI64 |> fromNanosSinceMidnight |> Ok
expect Time.fromIsoStr "T24-1200" == Time.fromHms 36 0 0 |> Ok
expect Time.fromIsoStr "T24-1200" |> unwrap "Time.fromIsoStr 'T24-1200'" |> Time.toUtcTime == (36 * nanosPerHour) |> Num.toI64 |> UtcTime.fromNanosSinceMidnight
# 128
expect parseTimeFromStr "1200+1401" == Err InvalidTimeFormat
expect Time.fromIsoStr "1200+1401" == Err InvalidTimeFormat
# 129
expect parseTimeFromStr "1200-1201" == Err InvalidTimeFormat
expect Time.fromIsoStr "1200-1201" == Err InvalidTimeFormat
# 130
expect parseTimeFromStr "T24+1200Z" == Err InvalidTimeFormat
expect Time.fromIsoStr "T24+1200Z" == Err InvalidTimeFormat

# parseDateTime
# 131
expect parseDateTimeFromStr "20240223T120000Z" == (19_776 * Const.nanosPerDay + 12 * nanosPerHour) |> Num.toI128 |> fromNanosSinceEpoch |> Ok
expect DateTime.fromIsoStr "20240223T120000Z" == DateTime.fromYmdhms 2024 2 23 12 0 0 |> Ok
expect DateTime.fromIsoStr "20240223T120000Z" |> unwrap "DateTime.fromIsoStr '20240223T120000Z'" |> DateTime.toUtc == Utc.fromNanosSinceEpoch (19_776 * secondsPerDay * nanosPerSecond + 12 * nanosPerHour)
# 132
expect parseDateTimeFromStr "2024-02-23T12:00:00+00:00" == (19_776 * Const.nanosPerDay + 12 * nanosPerHour) |> Num.toI128 |> fromNanosSinceEpoch |> Ok
expect DateTime.fromIsoStr "2024-02-23T12:00:00+00:00" == DateTime.fromYmdhms 2024 2 23 12 0 0 |> Ok
expect DateTime.fromIsoStr "2024-02-23T12:00:00+00:00" |> unwrap "DateTime.fromIsoStr '2024-02-23T12:00:00+00:00'" |> DateTime.toUtc == Utc.fromNanosSinceEpoch (19_776 * secondsPerDay * nanosPerSecond + 12 * nanosPerHour)
# 133
expect parseDateTimeFromStr "2024-02-23T00:00:00+14" == (19_776 * nanosPerDay - 14 * nanosPerHour) |> Num.toI128 |> fromNanosSinceEpoch |> Ok
expect DateTime.fromIsoStr "2024-02-23T00:00:00+14" == DateTime.fromYmdhms 2024 2 22 10 0 0 |> Ok
expect DateTime.fromIsoStr "2024-02-23T00:00:00+14" |> unwrap "DateTime.fromIsoStr '2024-02-23T00:00:00+14'" |> DateTime.toUtc == Utc.fromNanosSinceEpoch (19_776 * nanosPerDay - 14 * nanosPerHour)
# 134
expect parseDateTimeFromStr "2024-02-23T23:59:59-12" == (19_776 * Const.nanosPerDay + (Const.nanosPerDay - 1 * nanosPerSecond) + 12 * nanosPerHour) |> Num.toI128 |> fromNanosSinceEpoch |> Ok
expect DateTime.fromIsoStr "2024-02-23T23:59:59-12" == DateTime.fromYmdhms 2024 2 24 11 59 59 |> Ok
expect DateTime.fromIsoStr "2024-02-23T23:59:59-12" |> unwrap "DateTime.fromIsoStr '2024-02-23T23:59:59-12'" |> DateTime.toUtc == Utc.fromNanosSinceEpoch (19_776 * Const.nanosPerDay + (Const.nanosPerDay - 1 * nanosPerSecond) + 12 * nanosPerHour)


# <==== Utils.roc ====>
# <---- splitListAtIndices ---->
expect splitListAtIndices [1,2] [0,1,2] == [[1], [2]]
expect splitListAtIndices [1,2] [0] == [[1,2]]
expect splitListAtIndices [1,2] [1] == [[1], [2]]

# <---- splitUtf8AndKeepDelimiters ---->
expect splitUtf8AndKeepDelimiters [] [] == []
expect splitUtf8AndKeepDelimiters [] ['-', '+'] == []
expect splitUtf8AndKeepDelimiters ['1', '2', '3'] [] == [['1', '2', '3']]
expect splitUtf8AndKeepDelimiters ['1', '2', '3'] ['-', '+'] == [['1', '2', '3']]
expect splitUtf8AndKeepDelimiters ['0', '1', '+', '2', '3'] ['-', '+'] == [['0', '1'], ['+'], ['2', '3']]
expect splitUtf8AndKeepDelimiters ['+', '-', '0', '1', '2'] ['-', '+'] == [['+'], ['-'], ['0', '1', '2']]
expect splitUtf8AndKeepDelimiters ['+', '-'] ['-', '+'] == [['+'], ['-']]

# <---- validateUtf8SingleBytes ---->
expect validateUtf8SingleBytes [0b01111111]
expect !(validateUtf8SingleBytes [0b10000000, 0b00000001])
expect !("🔥" |> Str.toUtf8 |> validateUtf8SingleBytes)

# <---- utf8ToInt ---->
expect ['0','1','2','3','4','5','6','7','8','9'] |> utf8ToInt == Ok 123456789
expect utf8ToInt ['@'] == Err InvalidBytes
expect utf8ToInt ['/'] == Err InvalidBytes

# <---- utf8ToIntSigned ---->
expect ['-', '1'] |> utf8ToIntSigned == Ok -1
expect ['+', '1'] |> utf8ToIntSigned == Ok 1
expect ['1', '9'] |> utf8ToIntSigned == Ok 19


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
    when utf8ToFrac [',', '1', '2', '3'] is
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
expect
    num = utf8ToFrac ['T', '2', '3']
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

# <---- ymdToDaysInYear ---->
expect ymdToDaysInYear 1970 1 1 == 1
expect ymdToDaysInYear 1970 12 31 == 365
expect ymdToDaysInYear 1972 3 1 == 61
