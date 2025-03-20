## The DateTime module provides the `DateTime` type as well as functions for working with combined date and time values.
##
## These functions include functions for creating `DateTime` objects from various numeric values, converting `DateTime`s to and from ISO 8601 strings, and performing arithmetic operations on `DateTime`s.
module [
    DateTime,
    add_days,
    add_duration,
    add_hours,
    add_minutes,
    add_months,
    add_nanoseconds,
    add_seconds,
    add_years,
    after,
    before,
    compare,
    equal,
    from_iso_str,
    from_iso_u8,
    from_nanos_since_epoch,
    from_yd,
    from_ymd,
    from_yw,
    from_ywd,
    from_ymdhms,
    from_ymdhmsn,
    sub,
    to_iso_str,
    to_iso_u8,
    to_nanos_since_epoch,
    unix_epoch,
]

import Const
import Date
import Date exposing [Date]
import Duration
import Duration exposing [Duration]
import Time
import Time exposing [Time]
import rtils.ListUtils exposing [split_with_delims]

## ```
## DateTime : { date : Date, time: Time }
## ```
DateTime : { date : Date, time : Time }

## Add days to a `DateTime` object.
add_days : DateTime, Int * -> DateTime
add_days = |date_time, days| { date: Date.add_days(date_time.date, days), time: date_time.time }

## Add a `Duration` object to a `DateTime` object.
add_duration : DateTime, Duration -> DateTime
add_duration = |date_time, duration|
    duration_nanos = Duration.to_nanoseconds(duration)
    date_nanos = Date.to_nanos_since_epoch(date_time.date) |> Num.to_i128
    time_nanos = Time.to_nanos_since_midnight(date_time.time) |> Num.to_i128
    duration_nanos + date_nanos + time_nanos |> from_nanos_since_epoch

## Add minutes to a `DateTime` object.
add_minutes : DateTime, Int * -> DateTime
add_minutes = |date_time, minutes| add_nanoseconds(date_time, (Num.to_i64(minutes) * Const.nanos_per_minute))

## Add months to a `DateTime` object.
add_months : DateTime, Int * -> DateTime
add_months = |date_time, months| { date: Date.add_months(date_time.date, months), time: date_time.time }

## Add hours to a `DateTime` object.
add_hours : DateTime, Int * -> DateTime
add_hours = |date_time, hours| add_nanoseconds(date_time, (Num.to_i64(hours) * Const.nanos_per_hour))

## Add nanoseconds to a `DateTime` object.
add_nanoseconds : DateTime, Int * -> DateTime
add_nanoseconds = |date_time, nanos|
    # new_time = Time.add_nanoseconds(date_time.time, nanos)
    time_nanos = Time.to_nanos_since_midnight(date_time.time) + Num.to_i64(nanos)
    days =
        if time_nanos >= 0 then
            time_nanos // Const.nanos_per_day |> Num.to_i64
        else
            (time_nanos // Const.nanos_per_day)
            |> Num.add((if time_nanos % Const.nanos_per_day < 0 then -1 else 0))
            |> Num.to_i64
    { date: Date.add_days(date_time.date, days), time: Time.from_nanos_since_midnight(time_nanos) |> Time.normalize }

## Add seconds to a `DateTime` object.
add_seconds : DateTime, Int * -> DateTime
add_seconds = |date_time, seconds| add_nanoseconds(date_time, (Num.to_i64(seconds) * Const.nanos_per_second))

## Add years to a `DateTime` object.
add_years : DateTime, Int * -> DateTime
add_years = |date_time, years| { date: Date.add_years(date_time.date, years), time: date_time.time }

## Determine if the first `DateTime` occurs after the second `DateTime`.
after : DateTime, DateTime -> Bool
after = |a, b| compare a b == GT

## Determine if the first `DateTime` occurs before the second `DateTime`.
before : DateTime, DateTime -> Bool
before = |a, b| compare a b == LT

## Compare two `DateTime` objects.
## If the first occurs before the second, it returns LT.
## If the first and the second are equal, it returns EQ.
## If the first occurs after the second, it returns GT.
compare : DateTime, DateTime -> [LT, EQ, GT]
compare = |a, b|
    Date.compare a.date b.date
    |> |result| if result != EQ then result else Time.compare a.time b.time

## Determine if the first `DateTime` equals the second `DateTime`.
equal : DateTime, DateTime -> Bool
equal = |a, b| compare a b == EQ

## Convert an ISO 8601 string to a `DateTime` object.
from_iso_str : Str -> Result DateTime [InvalidDateTimeFormat]
from_iso_str = |str| Str.to_utf8(str) |> from_iso_u8

## Convert an ISO 8601 list of UTF-8 bytes to a `DateTime` object.
from_iso_u8 : List U8 -> Result DateTime [InvalidDateTimeFormat]
from_iso_u8 = |bytes|
    when split_with_delims(bytes, |b| b == 'T') is
        [date_bytes, ['T'], time_bytes] ->
            # TODO: currently cannot support timezone offsets which exceed or precede the current day
            when (Date.from_iso_u8(date_bytes), Time.from_iso_u8(time_bytes)) is
                (Ok(date), Ok(time)) ->
                    { date, time } |> normalize |> Ok

                (_, _) -> Err(InvalidDateTimeFormat)

        [date_bytes] ->
            when Date.from_iso_u8(date_bytes) is
                Ok(date) -> { date, time: Time.from_hms(0, 0, 0) } |> Ok
                Err(_) -> Err(InvalidDateTimeFormat)

        _ -> Err(InvalidDateTimeFormat)

## Convert the number of nanoseconds since the Unix epoch to a `DateTime` object.
from_nanos_since_epoch : Int * -> DateTime
from_nanos_since_epoch = |nanos|
    time_nanos = (
        if nanos < 0 and Num.to_i128(nanos) % Const.nanos_per_day != 0 then
            nanos % Const.nanos_per_day + Const.nanos_per_day
        else
            nanos % Const.nanos_per_day
    )
    date_nanos = nanos - time_nanos
    date = date_nanos |> Date.from_nanos_since_epoch
    time = time_nanos |> Num.to_i64 |> Time.from_nanos_since_midnight
    { date, time }

## Create a `DateTime` object from the year and day of the year.
from_yd : Int *, Int * -> DateTime
from_yd = |year, day| { date: Date.from_yd(year, day), time: Time.midnight }

## Create a `DateTime` object from the year, month, and day.
from_ymd : Int *, Int *, Int * -> DateTime
from_ymd = |year, month, day| { date: Date.from_ymd(year, month, day), time: Time.midnight }

## Create a `DateTime` object from the year and week.
from_yw : Int *, Int * -> DateTime
from_yw = |year, week| { date: Date.from_yw(year, week), time: Time.midnight }

## Create a `DateTime` object from the year, week, and day of the week.
from_ywd : Int *, Int *, Int * -> DateTime
from_ywd = |year, week, day| { date: Date.from_ywd(year, week, day), time: Time.midnight }

## Create a `DateTime` object from the year, month, day, hour, minute, and second.
from_ymdhms : Int *, Int *, Int *, Int *, Int *, Int * -> DateTime
from_ymdhms = |year, month, day, hour, minute, second|
    { date: Date.from_ymd(year, month, day), time: Time.from_hms(hour, minute, second) }

## Create a `DateTime` object from the year, month, day, hour, minute, second, and nanosecond.
from_ymdhmsn : Int *, Int *, Int *, Int *, Int *, Int *, Int * -> DateTime
from_ymdhmsn = |year, month, day, hour, minute, second, nanosecond|
    { date: Date.from_ymd(year, month, day), time: Time.from_hmsn(hour, minute, second, nanosecond) }

## Normalize a `DateTime` object.
normalize : DateTime -> DateTime
normalize = |date_time|
    {
        date: date_time.date,
        time: Time.from_hmsn(0, date_time.time.minute, date_time.time.second, date_time.time.nanosecond),
    }
    |> add_hours(date_time.time.hour)

## Subtract two `DateTime` objects to get the `Duration` between them.
sub : DateTime, DateTime -> Duration
sub = |a, b|
    a_nanos = to_nanos_since_epoch(a)
    b_nanos = to_nanos_since_epoch(b)
    a_nanos |> Num.sub_saturated(b_nanos) |> Duration.from_nanoseconds

## Convert a `DateTime` object to an ISO 8601 string.
to_iso_str : DateTime -> Str
to_iso_str = |date_time|
    Date.to_iso_str(date_time.date) |> Str.concat("T") |> Str.concat(Time.to_iso_str(date_time.time))

## Convert a `DateTime` object to an ISO 8601 list of UTF-8 bytes.
to_iso_u8 : DateTime -> List U8
to_iso_u8 = |date_time|
    Date.to_iso_u8(date_time.date) |> List.concat(['T']) |> List.concat(Time.to_iso_u8(date_time.time))

## Convert a `DateTime` object to the number of nanoseconds since the Unix epoch.
to_nanos_since_epoch : DateTime -> I128
to_nanos_since_epoch = |date_time|
    date_nanos = Date.to_nanos_since_epoch(date_time.date)
    time_nanos = Time.to_nanos_since_midnight(date_time.time) |> Num.to_i128
    date_nanos + time_nanos

## `DateTime` object representing the Unix epoch (1970-01-01T00:00:00).
unix_epoch : DateTime
unix_epoch = { date: Date.unix_epoch, time: Time.midnight }

# <==== TESTS ====>
# <---- add_nanoseconds ---->
expect add_nanoseconds(from_ymdhmsn(1970, 1, 1, 0, 0, 0, 0), 1) == from_ymdhmsn(1970, 1, 1, 0, 0, 0, 1)
expect add_nanoseconds(from_ymdhmsn(1970, 1, 1, 0, 0, 0, 0), Const.nanos_per_second) == from_ymdhmsn(1970, 1, 1, 0, 0, 1, 0)
expect add_nanoseconds(from_ymdhmsn(1970, 1, 1, 0, 0, 0, 0), Const.nanos_per_day) == from_ymdhmsn(1970, 1, 2, 0, 0, 0, 0)
expect add_nanoseconds(from_ymdhmsn(1970, 1, 1, 0, 0, 0, 0), -1) == from_ymdhmsn(1969, 12, 31, 23, 59, 59, (Const.nanos_per_second - 1))
expect add_nanoseconds(from_ymdhmsn(1970, 1, 1, 0, 0, 0, 0), -Const.nanos_per_day) == from_ymdhmsn(1969, 12, 31, 0, 0, 0, 0)
expect add_nanoseconds(from_ymdhmsn(1970, 1, 1, 0, 0, 0, 0), ((-Const.nanos_per_day) - 1)) == from_ymdhmsn(1969, 12, 30, 23, 59, 59, (Const.nanos_per_second - 1))

# <---- add_duration ---->
expect add_duration(unix_epoch, Duration.from_nanoseconds(-1)) == from_ymdhmsn(1969, 12, 31, 23, 59, 59, (Const.nanos_per_second - 1))
expect add_duration(unix_epoch, Duration.from_days(365)) == from_ymdhmsn(1971, 1, 1, 0, 0, 0, 0)

# <--- after --->
expect
    a = from_nanos_since_epoch 0
    b = from_nanos_since_epoch 0
    !(a |> after b)
expect
    a = from_nanos_since_epoch 0
    b = from_nanos_since_epoch 1
    !(a |> after b)
expect
    a = from_nanos_since_epoch 1
    b = from_nanos_since_epoch 0
    a |> after b

# <--- before --->
expect
    a = from_nanos_since_epoch 0
    b = from_nanos_since_epoch 0
    !(a |> before b)
expect
    a = from_nanos_since_epoch 0
    b = from_nanos_since_epoch 1
    a |> before b
expect
    a = from_nanos_since_epoch 1
    b = from_nanos_since_epoch 0
    !(a |> before b)

# <--- equal --->
expect
    a = from_nanos_since_epoch 0
    b = from_nanos_since_epoch 0
    a |> equal b
expect
    a = from_nanos_since_epoch 0
    b = from_nanos_since_epoch 1
    !(a |> equal b)
expect
    a = from_nanos_since_epoch 1
    b = from_nanos_since_epoch 0
    !(a |> equal b)

# <--- from_nanos_since_epoch --->
expect from_nanos_since_epoch((364 * 24 * Const.nanos_per_hour + 12 * Const.nanos_per_hour + 34 * Const.nanos_per_minute + 56 * Const.nanos_per_second + 5)) == from_ymdhmsn(1970, 12, 31, 12, 34, 56, 5)
expect from_nanos_since_epoch(-1) == from_ymdhmsn(1969, 12, 31, 23, 59, 59, (Const.nanos_per_second - 1))

# <--- normalize --->
expect normalize(from_ymdhmsn(1970, 1, 2, -12, 1, 2, 3)) == from_ymdhmsn(1970, 1, 1, 12, 1, 2, 3)
expect normalize(from_ymdhmsn(1970, 1, 1, 12, 1, 2, 3)) == from_ymdhmsn(1970, 1, 1, 12, 1, 2, 3)
expect normalize(from_ymdhmsn(1970, 1, 1, 36, 1, 2, 3)) == from_ymdhmsn(1970, 1, 2, 12, 1, 2, 3)

# <--- sub --->
expect sub(from_ymd(1970, 1, 1), from_ymdhmsn(1970, 1, 1, 0, 0, 0, 1)) == Duration.from_nanoseconds(-1)
expect sub(from_ymdhmsn(1970, 1, 1, 1, 1, 1, 1), from_yd(1968, 1)) == Duration.from_nanoseconds(Const.nanos_per_day * 731 + Const.nanos_per_hour + Const.nanos_per_minute + Const.nanos_per_second + 1)

# <---- to_iso_str ---->
expect to_iso_str(unix_epoch) == "1970-01-01T00:00:00"
expect to_iso_str(from_ymdhmsn(1970, 1, 1, 0, 0, 0, (Const.nanos_per_second // 2))) == "1970-01-01T00:00:00,5"

# <---- to_iso_u8 ---->
expect to_iso_u8(unix_epoch) == Str.to_utf8("1970-01-01T00:00:00")

# <--- to_nanos_since_epoch --->
expect to_nanos_since_epoch(from_ymdhmsn(1970, 12, 31, 12, 34, 56, 5)) == 364 * Const.nanos_per_day + 12 * Const.nanos_per_hour + 34 * Const.nanos_per_minute + 56 * Const.nanos_per_second + 5
