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
        fromNanosSinceMidnight,
        fromUtcTime,
        midnight,
        Time,
        toNanosSinceMidnight,
        toUtcTime,
    ]
    imports [
        Const,
        Duration,
        Duration.{ Duration },
        UtcTime,
        UtcTime.{ UtcTime },
        Unsafe.{ unwrap }, # for unit testing only
    ]

Time : { hour : U8, minute : U8, second : U8, nanosecond : U32 }

midnight : Time
midnight = { hour: 0, minute: 0, second: 0, nanosecond: 0 }

fromHms : Int *, Int *, Int * -> Time
fromHms = \hour, minute, second -> { hour: Num.toU8 hour, minute: Num.toU8 minute, second: Num.toU8 second, nanosecond: 0u32 }

fromHmsn : Int *, Int *, Int *, Int * -> Time
fromHmsn = \hour, minute, second, nanosecond -> 
    { hour: Num.toU8 hour, minute: Num.toU8 minute, second: Num.toU8 second, nanosecond: Num.toU32 nanosecond }

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

fromUtcTime : UtcTime -> Time
fromUtcTime = \utcTime ->
    nanos1 = UtcTime.toNanosSinceMidnight utcTime |> Num.rem Const.nanosPerDay |> Num.add Const.nanosPerDay |> Num.rem Const.nanosPerDay |> Num.toU64
    hour = (nanos1 // Const.nanosPerHour) % Const.hoursPerDay |> Num.toU8
    nanos2 = nanos1 % Const.nanosPerHour
    minute = nanos2 // Const.nanosPerMinute |> Num.toU8
    nanos3 = nanos2 % Const.nanosPerMinute
    second = nanos3 // Const.nanosPerSecond |> Num.toU8
    nanosecond = nanos3 % Const.nanosPerSecond |> Num.toU32
    { hour, minute, second, nanosecond }

expect
    utcTime = toUtcTime { hour: 12, minute: 34, second: 56, nanosecond: 5 }
    utcTime == UtcTime.fromNanosSinceMidnight (12 * Const.nanosPerHour + 34 * Const.nanosPerMinute + 56 * Const.nanosPerSecond + 5 )


toNanosSinceMidnight : Time -> I64
toNanosSinceMidnight = \time -> UtcTime.toNanosSinceMidnight (toUtcTime time)

fromNanosSinceMidnight : Int * -> Time
fromNanosSinceMidnight = \nanos -> fromUtcTime (UtcTime.fromNanosSinceMidnight (Num.toI64 nanos))

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
    (durationNanos + timeNanos) % Const.nanosPerDay |> fromNanosSinceMidnight

addTimeAndDuration : Time, Duration -> Time
addTimeAndDuration = \time, duration -> addDurationAndTime duration time


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
expect addHours (fromHms 12 34 56) 12 == fromHms 0 34 56

# <---- addTimeAndDuration ---->
expect addTimeAndDuration (fromHms 0 0 0) (Duration.fromHours 1 |> unwrap "will not overflow") == fromHms 1 0 0

# <---- fromNanosSinceMidnight ---->
expect fromNanosSinceMidnight -123 == fromHmsn 23 59 59 999_999_877