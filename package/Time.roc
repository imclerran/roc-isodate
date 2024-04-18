interface Time
    exposes [
        fromHms,
        fromHmsn,
        fromUtcTime,
        midnight,
        Time,
        toUtcTime,
    ]
    imports [
        Const,
        UtcTime,
        UtcTime.{
            UtcTime,
            fromNanosSinceMidnight,
            toNanosSinceMidnight,
        }
    ]

Time : { hour : U8, minute : U8, second : U8, nanosecond : U32 }

midnight : Time
midnight = { hour: 0, minute: 0, second: 0, nanosecond: 0 }

fromHms : Int *, Int *, Int * -> Time
fromHms = \hour, minute, second -> { hour: Num.toU8 hour, minute: Num.toU8 minute, second: Num.toU8 second, nanosecond: 0u32 }

fromHmsn : Int *, Int *, Int *, Int * -> Time
fromHmsn = \hour, minute, second, nanosecond -> 
    { hour: Num.toU8 hour, minute: Num.toU8 minute, second: Num.toU8 second, nanosecond: Num.toU32 nanosecond }
    #{ hour, minute, second, nanosecond }

toUtcTime : Time -> UtcTime
toUtcTime = \time ->
    hNanos = time.hour |> Num.toI64 |> Num.mul Const.nanosPerHour |> Num.toI64
    mNanos = time.minute |> Num.toI64 |> Num.mul Const.nanosPerMinute |> Num.toI64
    sNanos = time.second |> Num.toI64 |> Num.mul Const.nanosPerSecond |> Num.toI64
    nanos = time.nanosecond |> Num.toI64
    fromNanosSinceMidnight (hNanos + mNanos + sNanos + nanos)

expect
    utc = toUtcTime (fromHmsn 12 34 56 5)
    utc == fromNanosSinceMidnight (12 * Const.nanosPerHour + 34 * Const.nanosPerMinute + 56 * Const.nanosPerSecond + 5)

fromUtcTime : UtcTime -> Time
fromUtcTime = \utcTime ->
    nanos1 = toNanosSinceMidnight utcTime |> Num.toU64
    hour = nanos1 // Const.nanosPerHour |> Num.toU8
    nanos2 = nanos1 % Const.nanosPerHour
    minute = nanos2 // Const.nanosPerMinute |> Num.toU8
    nanos3 = nanos2 % Const.nanosPerMinute
    second = nanos3 // Const.nanosPerSecond |> Num.toU8
    nanosecond = nanos3 % Const.nanosPerSecond |> Num.toU32
    { hour, minute, second, nanosecond }

expect
    utcTime = toUtcTime { hour: 12, minute: 34, second: 56, nanosecond: 5 }
    utcTime == fromNanosSinceMidnight (12 * Const.nanosPerHour + 34 * Const.nanosPerMinute + 56 * Const.nanosPerSecond + 5 )