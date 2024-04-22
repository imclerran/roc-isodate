interface AbsoluteDuration
    exposes [
        addDateAndDuration,
        addDateTimeAndDuration,
        addDurationAndDate,
        addDurationAndDateTime,
        addDurationAndTime,
        addTimeAndDuration,
        addDurations,
        Duration,
        fromDays,
        fromHours,
        fromMinutes,
        fromNanoseconds,
        fromSeconds,
        toDays,
        toHours,
        toMinutes,
        toNanoseconds,
        toSeconds,
    ]
    imports [
        Const,
        Date,
        Date.{ Date },
        DateTime,
        DateTime.{ DateTime },
        Time,
        Time.{ Time },
        Unsafe.{ unwrap }, # for unit tests only
    ]

AbsoluteDuration : { days: I64, hours: I8, minutes: I8, seconds : I8, nanoseconds : I32 }

fromNanoseconds : Int * -> Result Duration [DurationOverflow]
fromNanoseconds = \nanos -> 
    if (nanos // Const.nanosPerDay |> Num.toI128) > (Num.maxI64 |> Num.toI128)
    then Err DurationOverflow
    else Ok {
        days: nanos // (Const.nanosPerDay) |> Num.toI64,
        hours: (nanos % (Const.nanosPerDay)) // Const.nanosPerHour |> Num.toI8,
        minutes: (nanos % Const.nanosPerHour) // Const.nanosPerMinute |> Num.toI8,
        seconds: (nanos % Const.nanosPerMinute) // Const.nanosPerSecond |> Num.toI8,
        nanoseconds: nanos % Const.nanosPerSecond |> Num.toI32
    }

toNanoseconds : Duration -> I128
toNanoseconds = \duration -> 
    (Num.toI128 duration.nanoseconds) + 
    (Num.toI128 duration.seconds) * Const.nanosPerSecond + 
    (Num.toI128 duration.minutes) * Const.nanosPerMinute + 
    (Num.toI128 duration.hours) * Const.nanosPerHour + 
    (Num.toI128 duration.days) * (Const.nanosPerHour * 24)

# TODO convert all from functions to use Result
fromSeconds: Int * -> Result Duration [DurationOverflow]
fromSeconds = \seconds -> 
    if (seconds // Const.secondsPerDay |> Num.toI128) > (Num.maxI64 |> Num.toI128)
    then Err DurationOverflow
    else Ok {
        days: seconds // (Const.secondsPerDay) |> Num.toI64,
        hours: (seconds % (Const.secondsPerDay)) // Const.secondsPerHour |> Num.toI8,
        minutes: (seconds % Const.secondsPerHour) // Const.secondsPerMinute |> Num.toI8,
        seconds: seconds % Const.secondsPerMinute |> Num.toI8,
        nanoseconds: 0
    }

toSeconds : Duration -> I128
toSeconds = \duration -> 
    (Num.toI128 duration.seconds) + 
    (Num.toI128 duration.minutes) * Const.secondsPerMinute + 
    (Num.toI128 duration.hours) * Const.secondsPerHour + 
    (Num.toI128 duration.days) * (Const.secondsPerHour * 24)

fromMinutes: Int * -> Result Duration [DurationOverflow]
fromMinutes = \minutes -> 
    if (minutes // Const.minutesPerDay |> Num.toI128) > (Num.maxI64 |> Num.toI128)
    then Err DurationOverflow
    else Ok {
        days: minutes // (Const.minutesPerDay) |> Num.toI64,
        hours: (minutes % (Const.minutesPerDay)) // Const.minutesPerHour |> Num.toI8,
        minutes: minutes % Const.minutesPerHour |> Num.toI8,
        seconds: 0,
        nanoseconds: 0
    }

toMinutes : Duration -> I128
toMinutes = \duration -> 
    (Num.toI128 duration.minutes) + 
    (Num.toI128 duration.hours) * Const.minutesPerHour + 
    (Num.toI128 duration.days) * (Const.minutesPerHour * 24)

fromHours: Int * -> Result Duration [DurationOverflow]
fromHours = \hours -> 
    if (hours // 24 |> Num.toI128) > (Num.maxI64 |> Num.toI128)
    then Err DurationOverflow
    else Ok {
        days: hours // 24 |> Num.toI64,
        hours: hours % 24 |> Num.toI8,
        minutes: 0,
        seconds: 0,
        nanoseconds: 0
    }

toHours : Duration -> I128
toHours = \duration -> 
    (Num.toI128 duration.hours) + 
    (Num.toI128 duration.days) * 24

fromDays: Int * -> Result Duration [DurationOverflow]
fromDays = \days -> 
    if days |> Num.toI128 > Num.maxI64 |> Num.toI128
    then Err DurationOverflow
    else Ok {
        days: days |> Num.toI64,
        hours: 0,
        minutes: 0,
        seconds: 0,
        nanoseconds: 0
    }

toDays : Duration -> I64
toDays = \duration -> duration.days

addDurations : Duration, Duration -> Result Duration [DurationOverflow]
addDurations = \d1, d2 -> 
    nanos1 = toNanoseconds d1
    nanos2 = toNanoseconds d2
    fromNanoseconds (nanos1 + nanos2)

expect
    days = Num.maxI64
    duration = fromDays days |> unwrap "will not overflow"
    duration |> toDays == days

expect
    d1 = fromDays (Num.maxI64 // 2) |> unwrap "will not overflow"
    d2 = fromDays (Num.maxI64 // 2) |> unwrap "will not overflow"
    d3 = fromDays ((Num.maxI64 // 2) * 2) |> unwrap "will not overflow"
    addDurations d1 d2 == Ok d3

expect 
    
    d1 = fromDays Num.minI64 |> unwrap "will not overflow"
    d2 = fromDays Num.maxI64 |> unwrap "will not overflow"
    d3 = fromDays -1 |> unwrap "will not overflow"
    addDurations d1 d2 == Ok d3

expect
    duration = fromDays Num.maxI64 |> unwrap "will not overflow"
    addDurations duration duration == Err DurationOverflow

addDurationAndTime : Duration, Time -> Time
addDurationAndTime = \duration, time -> addTimeAndDuration time duration

addTimeAndDuration : Time, Duration -> Time
addTimeAndDuration = \time, duration -> 
    durationNanos = toNanoseconds duration
    timeNanos = Time.toNanosSinceMidnight time |> Num.toI128
    (durationNanos + timeNanos) % Const.nanosPerDay |> Time.fromNanosSinceMidnight

expect
    time = Time.fromHms 0 0 0
    duration = fromHours 1 |> unwrap "will not overflow"
    addTimeAndDuration time duration == Time.fromHms 1 0 0

expect
    time = Time.fromHmsn 23 59 59 999_999_999
    duration = fromNanoseconds 2 |> unwrap "will not overflow"
    addTimeAndDuration time duration == Time.fromHmsn 0 0 0 1

addDurationAndDate : Duration, Date -> Date
addDurationAndDate = \duration, date -> addDateAndDuration date duration

addDateAndDuration : Date, Duration -> Date
addDateAndDuration = \date, duration -> 
    durationNanos = toNanoseconds duration
    dateNanos = Date.toNanosSinceEpoch date |> Num.toI128
    durationNanos + dateNanos |> Date.fromNanosSinceEpoch

addDurationAndDateTime : Duration, DateTime -> DateTime

addDateTimeAndDuration : DateTime, Duration -> DateTime
addDateTimeAndDuration = \dateTime, duration ->
    durationNanos = toNanoseconds duration
    dateNanos = Date.toNanosSinceEpoch dateTime.date |> Num.toI128
    timeNanos = Time.toNanosSinceMidnight dateTime.time |> Num.toI128
    durationNanos + dateNanos + timeNanos |> DateTime.fromNanosSinceEpoch