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
        Time,
        Time.{ Time },
        Utils.{
            splitListAtIndices,
            splitUtf8AndKeepDelimiters,
            utf8ToFrac,
            utf8ToInt,
            utf8ToIntSigned,
            validateUtf8SingleBytes,
        },
        Unsafe.{ unwrap },
    ]

# <==== Date.roc ====>
# <---- parseDate ---->
# parseCalendarDateCentury
# 1
expect Date.fromIsoStr "20" == Date.fromYmd 2000 1 1 |> Ok
expect Date.fromIsoStr "20" |> unwrap "Date.fromIsoStr '20'" |> Date.toNanosSinceEpoch == (10_957) * secondsPerDay * nanosPerSecond 
# 2
expect Date.fromIsoStr "19" == Date.fromYmd 1900 1 1 |> Ok
expect Date.fromIsoStr "19" |> unwrap "Date.fromIsoStr '19'" |> Date.toNanosSinceEpoch == -25_567 * secondsPerDay * nanosPerSecond
# 3
expect Date.fromIsoStr "ab" == Err InvalidDateFormat

# parseCalendarDateYear
# 4
expect Date.fromIsoStr "2024" == Date.fromYmd 2024 1 1 |> Ok
expect Date.fromIsoStr "2024" |> unwrap "Date.fromIsoStr '2024'" |> Date.toNanosSinceEpoch == (19_723) * secondsPerDay * nanosPerSecond
# 5
expect Date.fromIsoStr "1970" == Date.fromYmd 1970 1 1 |> Ok
expect Date.fromIsoStr "1970" |> unwrap "Date.fromIsoStr '1970'" |> Date.toNanosSinceEpoch == 0
# 6
expect Date.fromIsoStr "1968" == Date.fromYmd 1968 1 1 |> Ok
expect Date.fromIsoStr "1968" |> unwrap "Date.fromIsoStr '1968'" |> Date.toNanosSinceEpoch == -731 * secondsPerDay * nanosPerSecond
# 7
expect Date.fromIsoStr "202f" == Err InvalidDateFormat

# parseWeekDateReducedBasic
# 8
expect Date.fromIsoStr "2024W04" == Date.fromYmd 2024 1 22 |> Ok
expect Date.fromIsoStr "2024W04" |> unwrap "Date.fromIsoStr '2024W04'" |> Date.toNanosSinceEpoch == (19_723 + 21) * secondsPerDay * nanosPerSecond
# 9
expect Date.fromIsoStr "1970W01" == Date.fromYmd 1970 1 1 |> Ok
expect Date.fromIsoStr "1970W01" |> unwrap "Date.fromIsoStr '1970W01'" |> Date.toNanosSinceEpoch == 0
# 10
expect Date.fromIsoStr "1968W01" == Date.fromYmd 1968 1 1 |> Ok
expect Date.fromIsoStr "1968W01" |> unwrap "Date.fromIsoStr '1968W01'" |> Date.toNanosSinceEpoch == -731 * secondsPerDay * nanosPerSecond
# 11
expect Date.fromIsoStr "2024W53" == Err InvalidDateFormat
# 12
expect Date.fromIsoStr "2024W00" == Err InvalidDateFormat
# 13
expect Date.fromIsoStr "2024Www" == Err InvalidDateFormat

# parseCalendarDateMonth
# 14
expect Date.fromIsoStr "2024-02" == Date.fromYmd 2024 2 1 |> Ok
expect Date.fromIsoStr "2024-02" |> unwrap "Date.fromIsoStr '2024-02'" |> Date.toNanosSinceEpoch == (19_723 + 31) * secondsPerDay * nanosPerSecond 
# 15
expect Date.fromIsoStr "1970-01" == Date.fromYmd 1970 1 1 |> Ok
expect Date.fromIsoStr "1970-01" |> unwrap "Date.fromIsoStr '1970-01'" |> Date.toNanosSinceEpoch == 0
# 16
expect Date.fromIsoStr "1968-01" == Date.fromYmd 1968 1 1 |> Ok
expect Date.fromIsoStr "1968-01" |> unwrap "Date.fromIsoStr '1968-01'" |> Date.toNanosSinceEpoch == -731 * secondsPerDay * nanosPerSecond
# 17
expect Date.fromIsoStr "2024-13" == Err InvalidDateFormat
# 18
expect Date.fromIsoStr "2024-00" == Err InvalidDateFormat
# 19
expect Date.fromIsoStr "2024-0a" == Err InvalidDateFormat


# parseOrdinalDateBasic
# 20
expect Date.fromIsoStr "2024023" == Date.fromYmd 2024 1 23 |> Ok
expect Date.fromIsoStr "2024023" |> unwrap "Date.fromIsoStr '2024023'" |> Date.toNanosSinceEpoch == (19_723 + 22) * secondsPerDay * nanosPerSecond
# 21
expect Date.fromIsoStr "1970001" == Date.fromYmd 1970 1 1 |> Ok
expect Date.fromIsoStr "1970001" |> unwrap "Date.fromIsoStr '1970001'" |> Date.toNanosSinceEpoch == 0
# 22
expect Date.fromIsoStr "1968001" == Date.fromYmd 1968 1 1 |> Ok
expect Date.fromIsoStr "1968001" |> unwrap "Date.fromIsoStr '1968001'" |> Date.toNanosSinceEpoch == -731 * secondsPerDay * nanosPerSecond
# 23
expect Date.fromIsoStr "2024000" == Err InvalidDateFormat
# 24
expect Date.fromIsoStr "2024367" == Err InvalidDateFormat
# 25
expect Date.fromIsoStr "2024a23" == Err InvalidDateFormat

# parseWeekDateReducedExtended
# 26
expect Date.fromIsoStr "2024-W04" == Date.fromYmd 2024 1 22 |> Ok
expect Date.fromIsoStr "2024-W04" |> unwrap "Date.fromIsoStr '2024-W04'" |> Date.toNanosSinceEpoch == (19_723 + 21) * secondsPerDay * nanosPerSecond
# 27
expect Date.fromIsoStr "1970-W01" == Date.fromYmd 1970 1 1 |> Ok
expect Date.fromIsoStr "1970-W01" |> unwrap "Date.fromIsoStr '1970-W01'" |> Date.toNanosSinceEpoch == 0
# 28
expect Date.fromIsoStr "1968-W01" == Date.fromYmd 1968 1 1 |> Ok
expect Date.fromIsoStr "1968-W01" |> unwrap "Date.fromIsoStr '1968-W01'" |> Date.toNanosSinceEpoch == -731 * secondsPerDay * nanosPerSecond
# 29
expect Date.fromIsoStr "2024-W53" == Err InvalidDateFormat
# 30
expect Date.fromIsoStr "2024-W00" == Err InvalidDateFormat
# 31
expect Date.fromIsoStr "2024-Ww1" == Err InvalidDateFormat

# parseWeekDateBasic
# 32
expect Date.fromIsoStr "2024W042" == Date.fromYmd 2024 1 23 |> Ok
expect Date.fromIsoStr "2024W042" |> unwrap "Date.fromIsoStr '2024W042'" |> Date.toNanosSinceEpoch == (19_723 + 22) * secondsPerDay * nanosPerSecond
# 33
expect Date.fromIsoStr "1970W011" == Date.fromYmd 1970 1 1 |> Ok
expect Date.fromIsoStr "1970W011" |> unwrap "Date.fromIsoStr '1970W011'" |> Date.toNanosSinceEpoch == 0
# 34
expect Date.fromIsoStr "1970W524" == Date.fromYmd 1970 12 31 |> Ok
expect Date.fromIsoStr "1970W524" |> unwrap "Date.fromIsoStr '1970W524'" |> Date.toNanosSinceEpoch == 364 * secondsPerDay * nanosPerSecond
# 35
expect Date.fromIsoStr "1970W525" == Date.fromYmd 1971 1 1 |> Ok
expect Date.fromIsoStr "1970W525" |> unwrap "Date.fromIsoStr '1970W525'" |> Date.toNanosSinceEpoch == 365 * secondsPerDay * nanosPerSecond
# 36
expect Date.fromIsoStr "1968W011" == Date.fromYmd 1968 1 1 |> Ok
expect Date.fromIsoStr "1968W011" |> unwrap "Date.fromIsoStr '1968W011'" |> Date.toNanosSinceEpoch == -731 * secondsPerDay * nanosPerSecond
# 37
expect Date.fromIsoStr "2024W001" == Err InvalidDateFormat
# 38
expect Date.fromIsoStr "2024W531" == Err InvalidDateFormat
# 39
expect Date.fromIsoStr "2024W010" == Err InvalidDateFormat
# 40
expect Date.fromIsoStr "2024W018" == Err InvalidDateFormat
# 41
expect Date.fromIsoStr "2024W0a2" == Err InvalidDateFormat

# parseOrdinalDateExtended
# 42
expect Date.fromIsoStr "2024-023" == Date.fromYmd 2024 1 23 |> Ok
expect Date.fromIsoStr "2024-023" |> unwrap "Date.fromIsoStr '2024-023'" |> Date.toNanosSinceEpoch == (19_723 + 22) * secondsPerDay * nanosPerSecond
# 43
expect Date.fromIsoStr "1970-001" == Date.fromYmd 1970 1 1 |> Ok
expect Date.fromIsoStr "1970-001" |> unwrap "Date.fromIsoStr '1970-001'" |> Date.toNanosSinceEpoch == 0
# 44
expect Date.fromIsoStr "1968-001" == Date.fromYmd 1968 1 1 |> Ok
expect Date.fromIsoStr "1968-001" |> unwrap "Date.fromIsoStr '1968-001'" |> Date.toNanosSinceEpoch == -731 * secondsPerDay * nanosPerSecond
# 45
expect Date.fromIsoStr "2024-000" == Err InvalidDateFormat
# 46
expect Date.fromIsoStr "2024-367" == Err InvalidDateFormat
# 47
expect Date.fromIsoStr "2024-0a3" == Err InvalidDateFormat

# parseCalendarDateBasic
# 48
expect Date.fromIsoStr "20240123" == Date.fromYmd 2024 1 23 |> Ok
expect Date.fromIsoStr "20240123" |> unwrap "Date.fromIsoStr '20240123'" |> Date.toNanosSinceEpoch == (19_723 + 22) * secondsPerDay * nanosPerSecond
# 49
expect Date.fromIsoStr "19700101" == Date.fromYmd 1970 1 1 |> Ok
expect Date.fromIsoStr "19700101" |> unwrap "Date.fromIsoStr '19700101'" |> Date.toNanosSinceEpoch == 0
# 50
expect Date.fromIsoStr "19680101" == Date.fromYmd 1968 1 1 |> Ok
expect Date.fromIsoStr "19680101" |> unwrap "Date.fromIsoStr '19680101'" |> Date.toNanosSinceEpoch == -731 * secondsPerDay * nanosPerSecond
# 51
expect Date.fromIsoStr "20240100" == Err InvalidDateFormat
# 52
expect Date.fromIsoStr "20240132" == Err InvalidDateFormat
# 53
expect Date.fromIsoStr "20240001" == Err InvalidDateFormat
# 54
expect Date.fromIsoStr "20241301" == Err InvalidDateFormat
# 55
expect Date.fromIsoStr "2024a123" == Err InvalidDateFormat

# parseWeekDateExtended
# 56
expect Date.fromIsoStr "2024-W04-2" == Date.fromYmd 2024 1 23 |> Ok
expect Date.fromIsoStr "2024-W04-2" |> unwrap "Date.fromIsoStr '2024-W04-2'" |> Date.toNanosSinceEpoch == (19_723 + 22) * secondsPerDay * nanosPerSecond
# 57
expect Date.fromIsoStr "1970-W01-1" == Date.fromYmd 1970 1 1 |> Ok
expect Date.fromIsoStr "1970-W01-1" |> unwrap "Date.fromIsoStr '1970-W01-1'" |> Date.toNanosSinceEpoch == 0
# 58
expect Date.fromIsoStr "1968-W01-1" == Date.fromYmd 1968 1 1 |> Ok
expect Date.fromIsoStr "1968-W01-1" |> unwrap "Date.fromIsoStr '1968-W01-1'" |> Date.toNanosSinceEpoch == -731 * secondsPerDay * nanosPerSecond
# 59
expect Date.fromIsoStr "2024-W53-1" == Err InvalidDateFormat
# 60
expect Date.fromIsoStr "2024-W00-1" == Err InvalidDateFormat
# 61
expect Date.fromIsoStr "2024-W01-0" == Err InvalidDateFormat
# 62
expect Date.fromIsoStr "2024-W01-8" == Err InvalidDateFormat
# 63
expect Date.fromIsoStr "2024-Ww1-1" == Err InvalidDateFormat

# parseCalendarDateExtended
# 64
expect Date.fromIsoStr "2024-01-23" == Date.fromYmd 2024 1 23 |> Ok
expect Date.fromIsoStr "2024-01-23" |> unwrap "Date.fromIsoStr '2024-01-23'" |> Date.toNanosSinceEpoch == (19_723 + 22) * secondsPerDay * nanosPerSecond
# 65
expect Date.fromIsoStr "1970-01-01" == Date.fromYmd 1970 1 1 |> Ok
expect Date.fromIsoStr "1970-01-01" |> unwrap "Date.fromIsoStr '1970-01-01'" |> Date.toNanosSinceEpoch == 0
# 66
expect Date.fromIsoStr "1968-01-01" == Date.fromYmd 1968 1 1 |> Ok
expect Date.fromIsoStr "1968-01-01" |> unwrap "Date.fromIsoStr '1968-01-01'" |> Date.toNanosSinceEpoch == -731 * secondsPerDay * nanosPerSecond
# 67
expect Date.fromIsoStr "2024-01-00" == Err InvalidDateFormat
# 68
expect Date.fromIsoStr "2024-01-32" == Err InvalidDateFormat
# 69
expect Date.fromIsoStr "2024-00-01" == Err InvalidDateFormat
# 70
expect Date.fromIsoStr "2024-13-01" == Err InvalidDateFormat
# 71
expect Date.fromIsoStr "2024-0a-01" == Err InvalidDateFormat

# <==== Time.roc ====>
# <---- parseTime ---->
# parseLocalTimeHour
# 72
expect Time.fromIsoStr "11" == Time.fromHms 11 0 0 |> Ok
expect Time.fromIsoStr "11" |> unwrap "Time.fromIsoStr '11'" |> Time.toNanosSinceMidnight== (11 * nanosPerHour)
# 73
expect Time.fromIsoStr "00Z" == Time.fromHms 0 0 0 |> Ok
expect Time.fromIsoStr "00Z" |> unwrap "Time.fromIsoStr '00Z'" |> Time.toNanosSinceMidnight== 0
# 74
expect Time.fromIsoStr "T00" == Time.fromHms 0 0 0 |> Ok
expect Time.fromIsoStr "T00" |> unwrap "Time.fromIsoStr 'T00'" |> Time.toNanosSinceMidnight== 0
# 75
expect Time.fromIsoStr "T00Z" == Time.fromHms 0 0 0 |> Ok
expect Time.fromIsoStr "T00Z" |> unwrap "Time.fromIsoStr 'T00Z'" |> Time.toNanosSinceMidnight== 0
# 76
expect Time.fromIsoStr "T23" == Time.fromHms 23 0 0 |> Ok
expect Time.fromIsoStr "T23" |> unwrap "Time.fromIsoStr 'T23'" |> Time.toNanosSinceMidnight== (23 * nanosPerHour)
# 77
expect Time.fromIsoStr "T24" == Time.fromHms 24 0 0 |> Ok
expect Time.fromIsoStr "T24" |> unwrap "Time.fromIsoStr 'T24'" |> Time.toNanosSinceMidnight== (24 * nanosPerHour)
# 78
expect Time.fromIsoStr "T25" == Err InvalidTimeFormat
# 79
expect Time.fromIsoStr "T0Z" == Err InvalidTimeFormat

# parseLocalTimeMinuteBasic
# 80
expect Time.fromIsoStr "1111" == Time.fromHms 11 11 0 |> Ok
expect Time.fromIsoStr "1111" |> unwrap "Time.fromIsoStr '1111'" |> Time.toNanosSinceMidnight== (11 * nanosPerHour + 11 * nanosPerMinute)
# 81
expect Time.fromIsoStr "0000Z" == Time.fromHms 0 0 0 |> Ok
expect Time.fromIsoStr "0000Z" |> unwrap "Time.fromIsoStr '0000Z'" |> Time.toNanosSinceMidnight== 0
# 82
expect Time.fromIsoStr "T0000" == Time.fromHms 0 0 0 |> Ok
expect Time.fromIsoStr "T0000" |> unwrap "Time.fromIsoStr 'T0000'" |> Time.toNanosSinceMidnight== 0
# 83
expect Time.fromIsoStr "T0000Z" == Time.fromHms 0 0 0 |> Ok
expect Time.fromIsoStr "T0000Z" |> unwrap "Time.fromIsoStr 'T0000Z'" |> Time.toNanosSinceMidnight== 0
# 84
expect Time.fromIsoStr "T2359" == Time.fromHms 23 59 0 |> Ok
expect Time.fromIsoStr "T2359" |> unwrap "Time.fromIsoStr 'T2359'" |> Time.toNanosSinceMidnight== (23 * nanosPerHour + 59 * nanosPerMinute)
# 85
expect Time.fromIsoStr "T2400" == Time.fromHms 24 0 0 |> Ok
expect Time.fromIsoStr "T2400" |> unwrap "Time.fromIsoStr 'T2400'" |> Time.toNanosSinceMidnight== (24 * nanosPerHour)
# 86
expect Time.fromIsoStr "T2401" == Err InvalidTimeFormat
# 87
expect Time.fromIsoStr "T000Z" == Err InvalidTimeFormat

# parseLocalTimeMinuteExtended
# 88
expect Time.fromIsoStr "11:11" == Time.fromHms 11 11 0 |> Ok
expect Time.fromIsoStr "11:11" |> unwrap "Time.fromIsoStr '11:11'" |> Time.toNanosSinceMidnight== (11 * nanosPerHour + 11 * nanosPerMinute)
# 89
expect Time.fromIsoStr "00:00Z" == Time.midnight |> Ok
expect Time.fromIsoStr "00:00Z" |> unwrap "Time.fromIsoStr '00:00Z'" |> Time.toNanosSinceMidnight== 0
# 90
expect Time.fromIsoStr "T00:00" == Time.midnight |> Ok
expect Time.fromIsoStr "T00:00" |> unwrap "Time.fromIsoStr 'T00:00'" |> Time.toNanosSinceMidnight== 0
# 91
expect Time.fromIsoStr "T00:00Z" == Time.midnight |> Ok
expect Time.fromIsoStr "T00:00Z" |> unwrap "Time.fromIsoStr 'T00:00Z'" |> Time.toNanosSinceMidnight== 0
# 92
expect Time.fromIsoStr "T23:59" == Time.fromHms 23 59 0 |> Ok
expect Time.fromIsoStr "T23:59" |> unwrap "Time.fromIsoStr 'T23:59'" |> Time.toNanosSinceMidnight== (23 * nanosPerHour + 59 * nanosPerMinute)
# 93
expect Time.fromIsoStr "T24:00" == Time.fromHms 24 0 0 |> Ok
expect Time.fromIsoStr "T24:00" |> unwrap "Time.fromIsoStr 'T24:00'" |> Time.toNanosSinceMidnight== (24 * nanosPerHour)
# 94
expect Time.fromIsoStr "T24:01" == Err InvalidTimeFormat
# 95
expect Time.fromIsoStr "T00:0Z" == Err InvalidTimeFormat

# parseLocalTimeBasic
# 96
expect Time.fromIsoStr "111111" == Time.fromHms 11 11 11 |> Ok
expect Time.fromIsoStr "111111" |> unwrap "Time.fromIsoStr '111111'" |> Time.toNanosSinceMidnight== (11 * nanosPerHour + 11 * nanosPerMinute + 11 * nanosPerSecond)
# 97
expect Time.fromIsoStr "000000Z" == Time.midnight |> Ok
expect Time.fromIsoStr "000000Z" |> unwrap "Time.fromIsoStr '000000Z'" |> Time.toNanosSinceMidnight== 0
# 98
expect Time.fromIsoStr "T000000" == Time.midnight |> Ok
expect Time.fromIsoStr "T000000" |> unwrap "Time.fromIsoStr 'T000000'" |> Time.toNanosSinceMidnight== 0
# 99
expect Time.fromIsoStr "T000000Z" == Time.midnight |> Ok
expect Time.fromIsoStr "T000000Z" |> unwrap "Time.fromIsoStr 'T000000Z'" |> Time.toNanosSinceMidnight== 0
# 100
expect Time.fromIsoStr "T235959" == Time.fromHms 23 59 59 |> Ok
expect Time.fromIsoStr "T235959" |> unwrap "Time.fromIsoStr 'T235959'" |> Time.toNanosSinceMidnight== (23 * nanosPerHour + 59 * nanosPerMinute + 59 * nanosPerSecond)
# 101
expect Time.fromIsoStr "T240000" == Time.fromHms 24 0 0 |> Ok
expect Time.fromIsoStr "T240000" |> unwrap "Time.fromIsoStr 'T240000'" |> Time.toNanosSinceMidnight== (24 * nanosPerHour)
# 102
expect Time.fromIsoStr "T240001" == Err InvalidTimeFormat
# 103
expect Time.fromIsoStr "T00000Z" == Err InvalidTimeFormat

# parseLocalTimeExtended
# 104
expect Time.fromIsoStr "11:11:11" == Time.fromHms 11 11 11 |> Ok
expect Time.fromIsoStr "11:11:11" |> unwrap "Time.fromIsoStr '11:11:11'" |> Time.toNanosSinceMidnight== (11 * nanosPerHour + 11 * nanosPerMinute + 11 * nanosPerSecond)
# 105
expect Time.fromIsoStr "00:00:00Z" == Time.midnight |> Ok
expect Time.fromIsoStr "00:00:00Z" |> unwrap "Time.fromIsoStr '00:00:00Z'" |> Time.toNanosSinceMidnight== 0
# 106
expect Time.fromIsoStr "T00:00:00" == Time.midnight |> Ok
expect Time.fromIsoStr "T00:00:00" |> unwrap "Time.fromIsoStr 'T00:00:00'" |> Time.toNanosSinceMidnight== 0
# 107
expect Time.fromIsoStr "T00:00:00Z" == Time.midnight |> Ok
expect Time.fromIsoStr "T00:00:00Z" |> unwrap "Time.fromIsoStr 'T00:00:00Z'" |> Time.toNanosSinceMidnight== 0
# 108
expect Time.fromIsoStr "T23:59:59" == Time.fromHms 23 59 59 |> Ok
expect Time.fromIsoStr "T23:59:59" |> unwrap "Time.fromIsoStr 'T23:59:59'" |> Time.toNanosSinceMidnight== (23 * nanosPerHour + 59 * nanosPerMinute + 59 * nanosPerSecond)
# 109
expect Time.fromIsoStr "T24:00:00" == Time.fromHms 24 0 0 |> Ok
expect Time.fromIsoStr "T24:00:00" |> unwrap "Time.fromIsoStr 'T24:00:00'" |> Time.toNanosSinceMidnight== (24 * nanosPerHour)
# 110
expect Time.fromIsoStr "T24:00:01" == Err InvalidTimeFormat
# 111
expect Time.fromIsoStr "T00:00:0Z" == Err InvalidTimeFormat

# parseFractionalTime
# 112
expect Time.fromIsoStr "12.500" == Time.fromHms 12 30 0 |> Ok
expect Time.fromIsoStr "12.500" |> unwrap "Time.fromIsoStr '12.500'" |> Time.toNanosSinceMidnight== (12 * nanosPerHour + 30 * nanosPerMinute)
# 113
expect Time.fromIsoStr "12,500" == Time.fromHms 12 30 0 |> Ok
expect Time.fromIsoStr "12,500" |> unwrap "Time.fromIsoStr '12,500'" |> Time.toNanosSinceMidnight== (12 * nanosPerHour + 30 * nanosPerMinute)
# 114
expect Time.fromIsoStr "1200.500" == Time.fromHms 12 0 30 |> Ok
expect Time.fromIsoStr "1200.500" |> unwrap "Time.fromIsoStr '1200.500'" |> Time.toNanosSinceMidnight== (12 * nanosPerHour + 30 * nanosPerSecond)
# 115
expect Time.fromIsoStr "12:00,500" == Time.fromHms 12 0 30 |> Ok
expect Time.fromIsoStr "12:00,500" |> unwrap "Time.fromIsoStr '12:00,500'" |> Time.toNanosSinceMidnight== (12 * nanosPerHour + 30 * nanosPerSecond)
# 116
expect Time.fromIsoStr "12:00:00,123" == Time.fromHmsn 12 0 0 123_000_000 |> Ok
expect Time.fromIsoStr "12:00:00,123" |> unwrap "Time.fromIsoStr '12:00:00,123'" |> Time.toNanosSinceMidnight== (12 * nanosPerHour + 123_000_000)

# parseTime w/ offset
# 117
expect Time.fromIsoStr "12:00:00+01" == Time.fromHms 11 0 0 |> Ok
expect Time.fromIsoStr "12:00:00+01" |> unwrap "Time.fromIsoStr '12:00:00+01'" |> Time.toNanosSinceMidnight== (11 * nanosPerHour)
# 118
expect Time.fromIsoStr "12:00:00-01" == Time.fromHms 13 0 0 |> Ok
expect Time.fromIsoStr "12:00:00-01" |> unwrap "Time.fromIsoStr '12:00:00-01'" |> Time.toNanosSinceMidnight== (13 * nanosPerHour)
# 119
expect Time.fromIsoStr "12:00:00+0100" == Time.fromHms 11 0 0 |> Ok
expect Time.fromIsoStr "12:00:00+0100" |> unwrap "Time.fromIsoStr '12:00:00+0100'" |> Time.toNanosSinceMidnight== (11 * nanosPerHour)
# 120
expect Time.fromIsoStr "12:00:00-0100" == Time.fromHms 13 0 0 |> Ok
expect Time.fromIsoStr "12:00:00-0100" |> unwrap "Time.fromIsoStr '12:00:00-0100'" |> Time.toNanosSinceMidnight== (13 * nanosPerHour)
# 121
expect Time.fromIsoStr "12:00:00+01:00" == Time.fromHms 11 0 0 |> Ok
expect Time.fromIsoStr "12:00:00+01:00" |> unwrap "Time.fromIsoStr '12:00:00+01:00'" |> Time.toNanosSinceMidnight== (11 * nanosPerHour)
# 122
expect Time.fromIsoStr "12:00:00-01:00" == Time.fromHms 13 0 0 |> Ok
expect Time.fromIsoStr "12:00:00-01:00" |> unwrap "Time.fromIsoStr '12:00:00-01:00'" |> Time.toNanosSinceMidnight== (13 * nanosPerHour)
# 123
expect Time.fromIsoStr "12:00:00+01:30" == Time.fromHms 10 30 0 |> Ok
expect Time.fromIsoStr "12:00:00+01:30" |> unwrap "Time.fromIsoStr '12:00:00+01:30'" |> Time.toNanosSinceMidnight== (10 * nanosPerHour + 30 * nanosPerMinute)
# 124
expect Time.fromIsoStr "12:00:00-01:30" == Time.fromHms 13 30 0 |> Ok
expect Time.fromIsoStr "12:00:00-01:30" |> unwrap "Time.fromIsoStr '12:00:00-01:30'" |> Time.toNanosSinceMidnight== (13 * nanosPerHour + 30 * nanosPerMinute)
# 125
expect Time.fromIsoStr "12.50+0030" == Time.fromHms 12 0 0 |> Ok
expect Time.fromIsoStr "12.50+0030" |> unwrap "Time.fromIsoStr '12.50+0030'" |> Time.toNanosSinceMidnight== (12 * nanosPerHour)
# 126
expect Time.fromIsoStr "0000+1400" == Time.fromHms -14 0 0 |> Ok
expect Time.fromIsoStr "0000+1400" |> unwrap "Time.fromIsoStr '0000+1400'" |> Time.toNanosSinceMidnight== (-14 * nanosPerHour)
# 127
expect Time.fromIsoStr "T24-1200" == Time.fromHms 36 0 0 |> Ok
expect Time.fromIsoStr "T24-1200" |> unwrap "Time.fromIsoStr 'T24-1200'" |> Time.toNanosSinceMidnight== (36 * nanosPerHour)
# 128
expect Time.fromIsoStr "1200+1401" == Err InvalidTimeFormat
# 129
expect Time.fromIsoStr "1200-1201" == Err InvalidTimeFormat
# 130
expect Time.fromIsoStr "T24+1200Z" == Err InvalidTimeFormat

# <==== DateTime.roc ====>
# parseDateTime
# 131
expect DateTime.fromIsoStr "20240223T120000Z" == DateTime.fromYmdhms 2024 2 23 12 0 0 |> Ok
expect DateTime.fromIsoStr "20240223T120000Z" |> unwrap "DateTime.fromIsoStr '20240223T120000Z'" |> DateTime.toNanosSinceEpoch == 19_776 * secondsPerDay * nanosPerSecond + 12 * nanosPerHour
# 132
expect DateTime.fromIsoStr "2024-02-23T12:00:00+00:00" == DateTime.fromYmdhms 2024 2 23 12 0 0 |> Ok
expect DateTime.fromIsoStr "2024-02-23T12:00:00+00:00" |> unwrap "DateTime.fromIsoStr '2024-02-23T12:00:00+00:00'" |> DateTime.toNanosSinceEpoch == 19_776 * secondsPerDay * nanosPerSecond + 12 * nanosPerHour
# 133
expect DateTime.fromIsoStr "2024-02-23T00:00:00+14" == DateTime.fromYmdhms 2024 2 22 10 0 0 |> Ok
expect DateTime.fromIsoStr "2024-02-23T00:00:00+14" |> unwrap "DateTime.fromIsoStr '2024-02-23T00:00:00+14'" |> DateTime.toNanosSinceEpoch == 19_776 * nanosPerDay - 14 * nanosPerHour
# 134
expect DateTime.fromIsoStr "2024-02-23T23:59:59-12" == DateTime.fromYmdhms 2024 2 24 11 59 59 |> Ok
expect DateTime.fromIsoStr "2024-02-23T23:59:59-12" |> unwrap "DateTime.fromIsoStr '2024-02-23T23:59:59-12'" |> DateTime.toNanosSinceEpoch == 19_776 * Const.nanosPerDay + (Const.nanosPerDay - 1 * nanosPerSecond) + 12 * nanosPerHour
# 135
expect DateTime.fromIsoStr "2024-02-23T12:00:00+01:30" == DateTime.fromYmdhms 2024 2 23 10 30 0 |> Ok
expect DateTime.fromIsoStr "2024-02-23T12:00:00+01:30" |> unwrap "DateTime.fromIsoStr '2024-02-23T12:00:00+01:30'" |> DateTime.toNanosSinceEpoch == 19_776 * Const.nanosPerDay + 10 * nanosPerHour + 30 * nanosPerMinute


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
