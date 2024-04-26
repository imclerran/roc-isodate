interface Time
    exposes [
        addDurationAndTime,
        addHours,
        addMinutes,
        addNanoseconds,
        addSeconds,
        addTimeAndDuration,
        fromHms,
        fromHmsn,
        fromIsoStr,
        fromIsoU8,
        fromNanosSinceMidnight,
        fromUtcTime,
        midnight,
        normalize,
        Time,
        toNanosSinceMidnight,
        toUtcTime,
    ]
    imports [
        Const,
        Const.{
            nanosPerHour,
            nanosPerMinute,
            nanosPerSecond,
        },
        Duration,
        Duration.{ Duration },
        UtcTime,
        UtcTime.{ UtcTime },
        Utils.{
            splitListAtIndices,
            splitUtf8AndKeepDelimiters,
            utf8ToFrac,
            utf8ToIntSigned,
            validateUtf8SingleBytes,
        },
        Unsafe.{ unwrap }, # for unit testing only
    ]

# TODO: update Time constructors and functions to allow negative times

Time : { hour : I8, minute : U8, second : U8, nanosecond : U32 }

midnight : Time
midnight = { hour: 0, minute: 0, second: 0, nanosecond: 0 }

normalize : Time -> Time
normalize = \time -> 
    hNormalized = time.hour |> Num.rem Const.hoursPerDay |> Num.add Const.hoursPerDay |> Num.rem Const.hoursPerDay
    fromHmsn hNormalized time.minute time.second time.nanosecond

expect Time.normalize (fromHms -1 0 0) == fromHms 23 0 0
expect Time.normalize (fromHms 24 0 0) == fromHms 0 0 0
expect Time.normalize (fromHms 25 0 0) == fromHms 1 0 0

fromHms : Int *, Int *, Int * -> Time
fromHms = \hour, minute, second -> { hour: Num.toI8 hour, minute: Num.toU8 minute, second: Num.toU8 second, nanosecond: 0u32 }

fromHmsn : Int *, Int *, Int *, Int * -> Time
fromHmsn = \hour, minute, second, nanosecond -> 
    { hour: Num.toI8 hour, minute: Num.toU8 minute, second: Num.toU8 second, nanosecond: Num.toU32 nanosecond }

toUtcTime : Time -> UtcTime
toUtcTime = \time ->
    hNanos = time.hour |> Num.toI64 |> Num.mul Const.nanosPerHour |> Num.toI64
    mNanos = time.minute |> Num.toI64 |> Num.mul Const.nanosPerMinute |> Num.toI64
    sNanos = time.second |> Num.toI64 |> Num.mul Const.nanosPerSecond |> Num.toI64
    nanos = time.nanosecond |> Num.toI64
    UtcTime.fromNanosSinceMidnight (hNanos + mNanos + sNanos + nanos)

expect
    utc = toUtcTime (fromHmsn 12 34 56 5)
    utc == UtcTime.fromNanosSinceMidnight (12 * Const.nanosPerHour + 34 * Const.nanosPerMinute + 56 * Const.nanosPerSecond + 5)

expect
    utc = toUtcTime (fromHmsn -1 0 0 0)
    utc == UtcTime.fromNanosSinceMidnight (-1 * Const.nanosPerHour) &&
    UtcTime.toNanosSinceMidnight utc == -1 * Const.nanosPerHour

# TODO: update fromUtcTime to handle negative times correctly
fromUtcTime : UtcTime -> Time
fromUtcTime = \utcTime ->
    fromNanosSinceMidnight (UtcTime.toNanosSinceMidnight utcTime)

toNanosSinceMidnight : Time -> I64
toNanosSinceMidnight = \time -> UtcTime.toNanosSinceMidnight (toUtcTime time)

fromNanosSinceMidnight : Int * -> Time
fromNanosSinceMidnight = \nanos -> 
    nanos1 = nanos |> Num.rem Const.nanosPerDay |> Num.add Const.nanosPerDay |> Num.rem Const.nanosPerDay |> Num.toU64
    nanos2 = nanos1 % nanosPerHour
    minute = nanos2 // nanosPerMinute |> Num.toU8
    nanos3 = nanos2 % nanosPerMinute
    second = nanos3 // nanosPerSecond |> Num.toU8
    nanosecond = nanos3 % nanosPerSecond |> Num.toU32
    hour = (nanos - Num.intCast (Num.toI64 minute * nanosPerMinute + Num.toI64 second * nanosPerSecond + Num.toI64 nanosecond)) // nanosPerHour|> Num.toI8 #% Const.hoursPerDay |> Num.toI8
    { hour, minute, second, nanosecond }

addNanoseconds : Time, Int * -> Time
addNanoseconds = \time, nanos ->
    toNanosSinceMidnight time + Num.toI64 nanos |> fromNanosSinceMidnight

addSeconds : Time, Int * -> Time
addSeconds = \time, seconds -> addNanoseconds time (seconds * Const.nanosPerSecond)

addMinutes : Time, Int * -> Time
addMinutes = \time, minutes -> addNanoseconds time (minutes * Const.nanosPerMinute)

addHours : Time, Int * -> Time
addHours = \time, hours -> addNanoseconds time (hours * Const.nanosPerHour)

addDurationAndTime : Duration, Time -> Time
addDurationAndTime = \duration, time -> 
    durationNanos = Duration.toNanoseconds duration
    timeNanos = toNanosSinceMidnight time |> Num.toI128
    (durationNanos + timeNanos) |> fromNanosSinceMidnight

addTimeAndDuration : Time, Duration -> Time
addTimeAndDuration = \time, duration -> addDurationAndTime duration time

stripTandZ : List U8 -> List U8
stripTandZ = \bytes ->
    when bytes is
        ['T', .. as tail] -> stripTandZ tail
        [.. as head, 'Z'] -> head
        _ -> bytes

fromIsoStr: Str -> Result Time [InvalidTimeFormat]
fromIsoStr = \str -> Str.toUtf8 str |> fromIsoU8
        
fromIsoU8 : List U8 -> Result Time [InvalidTimeFormat]
fromIsoU8 = \bytes ->
    if validateUtf8SingleBytes bytes then
        strippedBytes = stripTandZ bytes
        when (splitUtf8AndKeepDelimiters strippedBytes ['.', ',', '+', '-'], List.last bytes) is
            # time.fractionaltime+timeoffset / time,fractionaltime-timeoffset
            ([timeBytes, [byte1], fractionalBytes, [byte2], offsetBytes], Ok lastByte) if lastByte != 'Z' -> 
                timeRes = parseFractionalTime timeBytes (List.join [[byte1], fractionalBytes])
                offsetRes = parseTimeOffset (List.join [[byte2], offsetBytes])
                combineTimeAndOffsetResults timeRes offsetRes
            # time+timeoffset / time-timeoffset
            ([timeBytes, [byte1], offsetBytes], Ok lastByte) if (byte1 == '+' || byte1 == '-') && lastByte != 'Z' -> 
                timeRes = parseWholeTime timeBytes
                offsetRes = parseTimeOffset (List.join [[byte1], offsetBytes])
                combineTimeAndOffsetResults timeRes offsetRes
            # time.fractionaltime / time,fractionaltime
            ([timeBytes, [byte1], fractionalBytes], _) if byte1 == ',' || byte1 == '.' -> 
                parseFractionalTime timeBytes (List.join [[byte1], fractionalBytes])
            # time
            ([timeBytes], _) -> parseWholeTime timeBytes
            _ -> Err InvalidTimeFormat
    else
        Err InvalidTimeFormat

combineTimeAndOffsetResults = \timeRes, offsetRes ->
    when (timeRes, offsetRes) is
        (Ok time, Ok offset) -> 
            Time.addTimeAndDuration time offset |> Ok
        (_, _) -> Err InvalidTimeFormat

parseWholeTime : List U8 -> Result Time [InvalidTimeFormat]
parseWholeTime = \bytes ->
    when bytes is
        [_,_] -> parseLocalTimeHour bytes # hh
        [_,_,_,_] -> parseLocalTimeMinuteBasic bytes # hhmm
        [_,_,':',_,_] -> parseLocalTimeMinuteExtended bytes # hh:mm
        [_,_,_,_,_,_] -> parseLocalTimeBasic bytes # hhmmss
        [_,_,':',_,_,':',_,_] -> parseLocalTimeExtended bytes # hh:mm:ss
        _ -> Err InvalidTimeFormat

parseFractionalTime : List U8, List U8 -> Result Time [InvalidTimeFormat]
parseFractionalTime = \wholeBytes, fractionalBytes ->
    combineDurationResAndTime = \durationRes, time ->
        when durationRes is
            Ok duration -> Time.addTimeAndDuration time duration |> Ok
            Err _ -> Err InvalidTimeFormat
    when (wholeBytes, utf8ToFrac fractionalBytes) is
        ([_,_], Ok frac) -> # hh
            time <- parseLocalTimeHour wholeBytes |> Result.try
            frac * Const.nanosPerHour |> Num.round |> Duration.fromNanoseconds |> combineDurationResAndTime time
        ([_,_,_,_], Ok frac) -> # hhmm
            time <- parseLocalTimeMinuteBasic wholeBytes |> Result.try
            frac * Const.nanosPerMinute |> Num.round |> Duration.fromNanoseconds |> combineDurationResAndTime time
        ([_,_,':',_,_], Ok frac) -> # hh:mm
            time <- parseLocalTimeMinuteExtended wholeBytes |> Result.try 
            frac * Const.nanosPerMinute |> Num.round |> Duration.fromNanoseconds |> combineDurationResAndTime time
        ([_,_,_,_,_,_], Ok frac) -> # hhmmss
            time <- parseLocalTimeBasic wholeBytes |> Result.try
            frac * Const.nanosPerSecond |> Num.round |> Duration.fromNanoseconds |> combineDurationResAndTime time
        ([_,_,':',_,_,':',_,_], Ok frac) -> # hh:mm:ss
            time <- parseLocalTimeExtended wholeBytes |> Result.try
            frac * Const.nanosPerSecond |> Num.round |> Duration.fromNanoseconds |> combineDurationResAndTime time
        _ -> Err InvalidTimeFormat

parseTimeOffset : List U8 -> Result Duration [InvalidTimeFormat]
parseTimeOffset = \bytes ->
    when bytes is
        ['-',h1,h2] -> 
            parseTimeOffsetHelp h1 h2 '0' '0' 1
        ['+',h1,h2] -> 
            parseTimeOffsetHelp h1 h2 '0' '0' -1
        ['-',h1,h2,m1,m2] -> 
            parseTimeOffsetHelp h1 h2 m1 m2 1
        ['+',h1,h2,m1,m2] ->
            parseTimeOffsetHelp h1 h2 m1 m2 -1
        ['-',h1,h2,':',m1,m2] ->
            parseTimeOffsetHelp h1 h2 m1 m2 1
        ['+',h1,h2,':',m1,m2] ->
            parseTimeOffsetHelp h1 h2 m1 m2 -1
        _ -> Err InvalidTimeFormat

parseTimeOffsetHelp : U8, U8, U8, U8, I64 -> Result Duration [InvalidTimeFormat]
parseTimeOffsetHelp = \h1, h2, m1, m2, sign ->
    isValidOffset = \offset -> if offset >= -14 * Const.nanosPerHour && offset <= 12 * Const.nanosPerHour then Valid else Invalid
    when (utf8ToIntSigned [h1,h2], utf8ToIntSigned [m1,m2]) is
        (Ok hour, Ok minute) ->
            offsetNanos = sign * (hour * Const.nanosPerHour + minute * Const.nanosPerMinute)
            when isValidOffset offsetNanos is
                Valid -> Duration.fromNanoseconds offsetNanos |>Result.mapErr \_ -> InvalidTimeFormat
                Invalid -> Err InvalidTimeFormat
        (_, _) -> Err InvalidTimeFormat
    
parseLocalTimeHour : List U8 -> Result Time [InvalidTimeFormat]
parseLocalTimeHour = \bytes ->
    when utf8ToIntSigned bytes is
        Ok hour if hour >= 0 && hour <= 24 ->
            Time.fromHms hour 0 0 |> Ok
        Ok _ -> Err InvalidTimeFormat
        Err _ -> Err InvalidTimeFormat

parseLocalTimeMinuteBasic : List U8 -> Result Time [InvalidTimeFormat]
parseLocalTimeMinuteBasic = \bytes ->
    when splitListAtIndices bytes [2] is
        [hourBytes, minuteBytes] -> 
            when (utf8ToIntSigned hourBytes, utf8ToIntSigned minuteBytes) is
            (Ok hour, Ok minute) if hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59 ->
                Time.fromHms hour minute 0 |> Ok
            (Ok 24, Ok 0) -> 
                Time.fromHms 24 0 0 |> Ok
            (_, _) -> Err InvalidTimeFormat
        _ -> Err InvalidTimeFormat

parseLocalTimeMinuteExtended : List U8 -> Result Time [InvalidTimeFormat]
parseLocalTimeMinuteExtended = \bytes ->
    when splitListAtIndices bytes [2,3] is
        [hourBytes, _, minuteBytes] -> 
            when (utf8ToIntSigned hourBytes, utf8ToIntSigned minuteBytes) is
            (Ok hour, Ok minute) if hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59 ->
                Time.fromHms hour minute 0 |> Ok
            (Ok 24, Ok 0) ->
                Time.fromHms 24 0 0 |> Ok
            (_, _) -> Err InvalidTimeFormat
        _ -> Err InvalidTimeFormat

parseLocalTimeBasic : List U8 -> Result Time [InvalidTimeFormat]
parseLocalTimeBasic = \bytes ->
    when splitListAtIndices bytes [2,4] is
        [hourBytes, minuteBytes, secondBytes] -> 
            when (utf8ToIntSigned hourBytes, utf8ToIntSigned minuteBytes, utf8ToIntSigned secondBytes) is
            (Ok h, Ok m, Ok s) if h >= 0 && h <= 23 && m >= 0 && m <= 59 && s >= 0 && s <= 59 ->
                Time.fromHms h m s |> Ok
            (Ok 24, Ok 0, Ok 0) ->
                Time.fromHms 24 0 0 |> Ok
            (_, _, _) -> Err InvalidTimeFormat
        _ -> Err InvalidTimeFormat

parseLocalTimeExtended : List U8 -> Result Time [InvalidTimeFormat]
parseLocalTimeExtended = \bytes ->
    when splitListAtIndices bytes [2,3,5,6] is
        [hourBytes, _, minuteBytes, _, secondBytes] -> 
            when (utf8ToIntSigned hourBytes, utf8ToIntSigned minuteBytes, utf8ToIntSigned secondBytes) is
            (Ok h, Ok m, Ok s) if h >= 0 && h <= 23 && m >= 0 && m <= 59 && s >= 0 && s <= 59 ->
                Time.fromHms h m s |> Ok
            (Ok 24, Ok 0, Ok 0) ->
                Time.fromHms 24 0 0 |> Ok
            (_, _, _) -> Err InvalidTimeFormat
        _ -> Err InvalidTimeFormat


# <===== TESTS ====>
# <---- addNanoseconds ---->
expect addNanoseconds (fromHmsn 12 34 56 5) Const.nanosPerSecond == fromHmsn 12 34 57 5
expect addNanoseconds (fromHmsn 12 34 56 5) -Const.nanosPerSecond == fromHmsn 12 34 55 5

# <---- addSeconds ---->
expect addSeconds (fromHms 12 34 56) 59 == fromHms 12 35 55
expect addSeconds (fromHms 12 34 56) -59 == fromHms 12 33 57

# <---- addMinutes ---->
expect addMinutes (fromHms 12 34 56) 59 == fromHms 13 33 56
expect addMinutes (fromHms 12 34 56) -59 == fromHms 11 35 56

# <---- addHours ---->
expect addHours (fromHms 12 34 56) 1 == fromHms 13 34 56
expect addHours (fromHms 12 34 56) -1 == fromHms 11 34 56
expect addHours (fromHms 12 34 56) 12 == fromHms 24 34 56

# <---- addTimeAndDuration ---->
expect addTimeAndDuration (fromHms 0 0 0) (Duration.fromHours 1 |> unwrap "will not overflow") == fromHms 1 0 0

# <---- fromNanosSinceMidnight ---->
expect fromNanosSinceMidnight -123 == fromHmsn -1 59 59 999_999_877
expect fromNanosSinceMidnight 0 == midnight
expect fromNanosSinceMidnight (24 * Const.nanosPerHour) == fromHms 24 0 0
expect fromNanosSinceMidnight (25 * nanosPerHour) == fromHms 25 0 0
expect fromNanosSinceMidnight (12 * nanosPerHour + 34 * nanosPerMinute + 56 * nanosPerSecond + 5) == fromHmsn 12 34 56 5

# <---- fromUtcTime ---->
expect fromUtcTime (UtcTime.fromNanosSinceMidnight -123) == fromHmsn -1 59 59 999_999_877
expect fromUtcTime (UtcTime.fromNanosSinceMidnight 0) == midnight
expect fromUtcTime (UtcTime.fromNanosSinceMidnight (24 * Const.nanosPerHour)) == fromHms 24 0 0
expect fromUtcTime (UtcTime.fromNanosSinceMidnight (25 * Const.nanosPerHour)) == fromHms 25 0 0
expect toUtcTime { hour: 12, minute: 34, second: 56, nanosecond: 5 } == UtcTime.fromNanosSinceMidnight (12 * nanosPerHour + 34 * nanosPerMinute + 56 * nanosPerSecond + 5 )