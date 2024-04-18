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

fromHms : U8, U8, U8 -> Time
fromHms = \hour, minute, second -> { hour, minute, second, nanosecond: 0 }

fromHmsn : U8, U8, U8, U32 -> Time
fromHmsn = \hour, minute, second, nanosecond -> { hour, minute, second, nanosecond }

toUtcTime : Time -> UtcTime
toUtcTime = \time ->
    hNanos = time.hour |> Num.toI64 |> Num.mul Const.nanosPerHour |> Num.toI64
    mNanos = time.minute |> Num.toI64 |> Num.mul Const.nanosPerMinute |> Num.toI64
    sNanos = time.second |> Num.toI64 |> Num.mul Const.nanosPerSecond |> Num.toI64
    nanos = time.nanosecond |> Num.toI64
    fromNanosSinceMidnight (hNanos + mNanos + sNanos + nanos)

expect
    utc = toUtcTime (fromHms 12 34 56)
    fromUtcTime utc == fromHms 12 34 56

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