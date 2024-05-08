module [
    addDateTimeAndDuration,
    addDays,
    addDurationAndDateTime,
    addHours,
    addMinutes,
    addMonths,
    addNanoseconds,
    addSeconds,
    addYears,
    DateTime,
    fromIsoStr,
    fromIsoU8,
    fromNanosSinceEpoch,
    fromYd,
    fromYmd,
    fromYw,
    fromYwd,
    fromYmdhms,
    fromYmdhmsn,
    toIsoStr,
    toIsoU8,
    toNanosSinceEpoch,
    unixEpoch,
]

import Const
import Date
import Date exposing [Date]
import Duration
import Duration exposing [Duration]
import Time
import Time exposing [Time]
import Utils exposing [
    splitUtf8AndKeepDelimiters,
]

DateTime : { date : Date, time : Time }

unixEpoch : DateTime
unixEpoch = { date: Date.unixEpoch, time: Time.midnight }

normalize : DateTime -> DateTime
normalize = \dateTime ->
    addHours { 
        date: dateTime.date, 
        time: Time.fromHmsn 0 dateTime.time.minute dateTime.time.second dateTime.time.nanosecond,
    } dateTime.time.hour

expect normalize (fromYmdhmsn 1970 1 2 -12 1 2 3) == fromYmdhmsn 1970 1 1 12 1 2 3
expect normalize (fromYmdhmsn 1970 1 1 12 1 2 3) == fromYmdhmsn 1970 1 1 12 1 2 3
expect normalize (fromYmdhmsn 1970 1 1 36 1 2 3) == fromYmdhmsn 1970 1 2 12 1 2 3

fromYd : Int *, Int * -> DateTime
fromYd = \year, day -> { date: Date.fromYd year day, time: Time.midnight }

fromYmd : Int *, Int *, Int * -> DateTime
fromYmd = \year, month, day -> { date: Date.fromYmd year month day, time: Time.midnight }

fromYwd : Int *, Int *, Int * -> DateTime
fromYwd = \year, week, day -> { date: Date.fromYwd year week day, time: Time.midnight }

fromYw : Int *, Int * -> DateTime
fromYw = \year, week -> { date: Date.fromYw year week, time: Time.midnight }

fromYmdhms : Int *, Int *, Int *, Int *, Int *, Int * -> DateTime
fromYmdhms = \year, month, day, hour, minute, second ->
    { date: Date.fromYmd year month day, time: Time.fromHms hour minute second }

fromYmdhmsn : Int *, Int *, Int *, Int *, Int *, Int *, Int * -> DateTime
fromYmdhmsn = \year, month, day, hour, minute, second, nanosecond ->
    { date: Date.fromYmd year month day, time: Time.fromHmsn hour minute second nanosecond }

toNanosSinceEpoch : DateTime -> I128
toNanosSinceEpoch = \dateTime -> 
    dateNanos = Date.toNanosSinceEpoch dateTime.date
    timeNanos = Time.toNanosSinceMidnight dateTime.time |> Num.toI128
    dateNanos + timeNanos

fromNanosSinceEpoch : Int * -> DateTime
fromNanosSinceEpoch = \nanos -> 
    timeNanos = if nanos < 0 && Num.toI128 nanos % Const.nanosPerDay != 0 then
        nanos % Const.nanosPerDay + Const.nanosPerDay else nanos % Const.nanosPerDay
    dateNanos = nanos - timeNanos
    date = dateNanos |> Date.fromNanosSinceEpoch
    time = timeNanos |> Num.toI64 |> Time.fromNanosSinceMidnight
    { date, time }

addNanoseconds : DateTime, Int * -> DateTime
addNanoseconds = \dateTime, nanos ->
    timeNanos = Time.toNanosSinceMidnight dateTime.time + Num.toI64 nanos
    days = if timeNanos >= 0 
        then timeNanos // Const.nanosPerDay |> Num.toI64
        else timeNanos // Const.nanosPerDay |> Num.add (if timeNanos % Const.nanosPerDay < 0 then -1 else 0) |> Num.toI64
    { date:  Date.addDays dateTime.date days, time: Time.fromNanosSinceMidnight timeNanos |> Time.normalize }

addSeconds : DateTime, Int * -> DateTime
addSeconds = \dateTime, seconds -> addNanoseconds dateTime (Num.toI64 seconds * Const.nanosPerSecond)

addMinutes : DateTime, Int * -> DateTime
addMinutes = \dateTime, minutes -> addNanoseconds dateTime (Num.toI64 minutes * Const.nanosPerMinute)

addHours : DateTime, Int * -> DateTime
addHours = \dateTime, hours -> addNanoseconds dateTime (Num.toI64 hours * Const.nanosPerHour)

addDays : DateTime, Int * -> DateTime
addDays = \dateTime, days -> { date: Date.addDays dateTime.date days, time: dateTime.time }

addMonths : DateTime, Int * -> DateTime
addMonths = \dateTime, months -> { date: Date.addMonths dateTime.date months, time: dateTime.time }

addYears : DateTime, Int * -> DateTime
addYears = \dateTime, years -> { date: Date.addYears dateTime.date years, time: dateTime.time }

addDurationAndDateTime : Duration, DateTime -> DateTime
addDurationAndDateTime = \duration, dateTime ->
    durationNanos = Duration.toNanoseconds duration
    dateNanos = Date.toNanosSinceEpoch dateTime.date |> Num.toI128
    timeNanos = Time.toNanosSinceMidnight dateTime.time |> Num.toI128
    durationNanos + dateNanos + timeNanos |> fromNanosSinceEpoch

addDateTimeAndDuration : DateTime, Duration -> DateTime
addDateTimeAndDuration = \dateTime, duration -> addDurationAndDateTime duration dateTime

toIsoStr : DateTime -> Str
toIsoStr = \dateTime -> 
    Date.toIsoStr dateTime.date |> Str.concat "T" |> Str.concat (Time.toIsoStr dateTime.time)

toIsoU8 : DateTime -> List U8
toIsoU8 = \dateTime -> 
    Date.toIsoU8 dateTime.date |> List.concat ['T'] |> List.concat (Time.toIsoU8 dateTime.time)

fromIsoStr : Str -> Result DateTime [InvalidDateTimeFormat]
fromIsoStr = \str -> Str.toUtf8 str |> fromIsoU8

fromIsoU8 : List U8 -> Result DateTime [InvalidDateTimeFormat]
fromIsoU8 = \bytes ->
    when splitUtf8AndKeepDelimiters bytes ['T'] is
        [dateBytes, ['T'], timeBytes] ->
            # TODO: currently cannot support timezone offsets which exceed or precede the current day
            when (Date.fromIsoU8 dateBytes, Time.fromIsoU8 timeBytes) is
                (Ok date, Ok time) -> 
                    { date, time } |> normalize |> Ok
                (_, _) -> Err InvalidDateTimeFormat
        [dateBytes] -> 
            when (Date.fromIsoU8 dateBytes) is
                Ok date -> { date, time: Time.fromHms 0 0 0 } |> Ok
                Err _ -> Err InvalidDateTimeFormat
        _ -> Err InvalidDateTimeFormat

# <==== TESTS ====>
# <---- toIsoStr ---->
expect toIsoStr unixEpoch == "1970-01-01T00:00:00"
expect toIsoStr (fromYmdhmsn 1970 1 1 0 0 0 (Const.nanosPerSecond // 2)) == "1970-01-01T00:00:00,5"

# <---- toIsoU8 ---->
expect toIsoU8 unixEpoch == Str.toUtf8 "1970-01-01T00:00:00"

# <---- addNanoseconds ---->
expect addNanoseconds (fromYmdhmsn 1970 1 1 0 0 0 0) 1 == fromYmdhmsn 1970 1 1 0 0 0 1
expect addNanoseconds (fromYmdhmsn 1970 1 1 0 0 0 0) Const.nanosPerSecond == fromYmdhmsn 1970 1 1 0 0 1 0
expect addNanoseconds (fromYmdhmsn 1970 1 1 0 0 0 0) Const.nanosPerDay == fromYmdhmsn 1970 1 2 0 0 0 0
expect addNanoseconds (fromYmdhmsn 1970 1 1 0 0 0 0) -1 == fromYmdhmsn 1969 12 31 23 59 59 (Const.nanosPerSecond - 1)
expect addNanoseconds (fromYmdhmsn 1970 1 1 0 0 0 0) -Const.nanosPerDay == fromYmdhmsn 1969 12 31 0 0 0 0
expect addNanoseconds (fromYmdhmsn 1970 1 1 0 0 0 0) (-Const.nanosPerDay - 1) == fromYmdhmsn 1969 12 30 23 59 59 (Const.nanosPerSecond - 1)

# <---- addDateTimeAndDuration ---->
expect 
    import Unsafe exposing [unwrap]
    addDateTimeAndDuration unixEpoch (Duration.fromNanoseconds -1 |> unwrap "will not overflow") == fromYmdhmsn 1969 12 31 23 59 59 (Const.nanosPerSecond - 1)
expect
    import Unsafe exposing [unwrap]
    addDateTimeAndDuration unixEpoch (Duration.fromDays 365 |> unwrap "will not overflow") == fromYmdhmsn 1971 1 1 0 0 0 0

# <--- fromNanosSinceEpoch --->
expect fromNanosSinceEpoch (364 * 24 * Const.nanosPerHour + 12 * Const.nanosPerHour + 34 * Const.nanosPerMinute + 56 * Const.nanosPerSecond + 5) == fromYmdhmsn 1970 12 31 12 34 56 5
expect fromNanosSinceEpoch (-1) == fromYmdhmsn 1969 12 31 23 59 59 (Const.nanosPerSecond - 1)

# <--- toNanosSinceEpoch --->
expect toNanosSinceEpoch (fromYmdhmsn 1970 12 31 12 34 56 5)  == 364 * Const.nanosPerDay + 12 * Const.nanosPerHour + 34 * Const.nanosPerMinute + 56 * Const.nanosPerSecond + 5
