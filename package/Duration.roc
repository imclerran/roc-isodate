## The duration modules provides the `Duration` type and associated functions for representing time durations and performing date/time arithmetic.
module [
    Duration,
    add,
    from_days,
    from_hours,
    from_minutes,
    from_nanoseconds,
    from_seconds,
    to_days,
    to_hours,
    to_minutes,
    to_nanoseconds,
    to_seconds,
]

import Const

## An object representing a time duration. Constructing a duration or performing math which would overflow the limits of the `Duration` will result in the value being saturated to the maximum or minimum value.
## ```
## Duration : {
##     days : I64,
##     hours : I8,
##     minutes : I8,
##     seconds : I8,
##     nanoseconds : I32
## }
## ```
Duration : { days : I64, hours : I8, minutes : I8, seconds : I8, nanoseconds : I32 }

## Create a `Duration` object from nanoseconds.
from_nanoseconds : Int * -> Duration
from_nanoseconds = |nanos| 
    nanos_saturated =
        if (Num.to_i128(nanos) // Const.nanos_per_day) > (Num.max_i64 |> Num.to_i128) then
            (Num.max_i64 |> Num.to_i128) * Const.nanos_per_day
        else if (Num.to_i128(nanos) // Const.nanos_per_day) < (Num.min_i64 |> Num.to_i128) then
            (Num.min_i64 |> Num.to_i128) * Const.nanos_per_day
        else
            nanos |> Num.to_i128
    {
        days: nanos_saturated // (Const.nanos_per_day) |> Num.to_i64,
        hours: (nanos_saturated % (Const.nanos_per_day)) // Const.nanos_per_hour |> Num.to_i8,
        minutes: (nanos_saturated % Const.nanos_per_hour) // Const.nanos_per_minute |> Num.to_i8,
        seconds: (nanos_saturated % Const.nanos_per_minute) // Const.nanos_per_second |> Num.to_i8,
        nanoseconds: nanos_saturated % Const.nanos_per_second |> Num.to_i32,
    }

## Convert a `Duration` object to nanoseconds.
to_nanoseconds : Duration -> I128
to_nanoseconds = |duration|
    (Num.to_i128(duration.nanoseconds))
    |> Num.add_saturated((Num.to_i128(duration.seconds)) |> Num.mul_saturated(Const.nanos_per_second))
    |> Num.add_saturated((Num.to_i128(duration.minutes)) |> Num.mul_saturated(Const.nanos_per_minute))
    |> Num.add_saturated((Num.to_i128(duration.hours)) |> Num.mul_saturated(Const.nanos_per_hour))
    |> Num.add_saturated((Num.to_i128(duration.days)) |> Num.mul_saturated(Const.nanos_per_day))

## Create a `Duration` object from seconds.
from_seconds : Int * -> Duration
from_seconds = |seconds| 
    seconds_saturated = 
        if (Num.to_i128(seconds) // (Const.seconds_per_day)) > (Num.max_i64 |> Num.to_i128) then
            (Num.max_i64 |> Num.to_i128) * (Const.seconds_per_day)
        else if (Num.to_i128(seconds) // (Const.seconds_per_day)) < (Num.min_i64 |> Num.to_i128) then
            (Num.min_i64 |> Num.to_i128) * (Const.seconds_per_day)
        else
            seconds |> Num.to_i128
    {
        days: seconds_saturated // (Const.seconds_per_day) |> Num.to_i64,
        hours: (seconds_saturated % (Const.seconds_per_day)) // Const.seconds_per_hour |> Num.to_i8,
        minutes: (seconds_saturated % Const.seconds_per_hour) // Const.seconds_per_minute |> Num.to_i8,
        seconds: seconds_saturated % Const.seconds_per_minute |> Num.to_i8,
        nanoseconds: 0,
    }

## Convert a `Duration` object to seconds (truncates nanoseconds).
to_seconds : Duration -> I64
to_seconds = |duration|
    (Num.to_i64(duration.seconds)) 
    |> Num.add_saturated((Num.to_i64(duration.minutes)) |> Num.mul_saturated(Const.seconds_per_minute))
    |> Num.add_saturated((Num.to_i64(duration.hours)) |> Num.mul_saturated(Const.seconds_per_hour))
    |> Num.add_saturated((duration.days) |> Num.mul_saturated(Const.seconds_per_day))

## Create a `Duration` object from minutes.
from_minutes : Int * -> Duration
from_minutes = |minutes| 
    minutes_saturated = 
        if (Num.to_i128(minutes) // (Const.minutes_per_day)) > (Num.max_i64 |> Num.to_i128) then
            (Num.max_i64 |> Num.to_i128) * (Const.minutes_per_day)
        else if (Num.to_i128(minutes) // (Const.minutes_per_day)) < (Num.min_i64 |> Num.to_i128) then
            (Num.min_i64 |> Num.to_i128) * (Const.minutes_per_day)
        else
            minutes |> Num.to_i128
    {
        days: minutes_saturated // (Const.minutes_per_day) |> Num.to_i64,
        hours: (minutes_saturated % (Const.minutes_per_day)) // Const.minutes_per_hour |> Num.to_i8,
        minutes: minutes_saturated % Const.minutes_per_hour |> Num.to_i8,
        seconds: 0,
        nanoseconds: 0,
    }

## Convert a `Duration` object to minutes (truncates seconds and lower).
to_minutes : Duration -> I64
to_minutes = |duration|
    (Num.to_i64(duration.minutes))
    |> Num.add_saturated((Num.to_i64(duration.hours)) |> Num.mul_saturated(Const.minutes_per_hour))
    |> Num.add_saturated((duration.days) |> Num.mul_saturated(Const.minutes_per_day))

## Create a `Duration` object from hours.
from_hours : Int * -> Duration
from_hours = |hours|
    hours_saturated = 
        if (Num.to_i128(hours) // (24)) > (Num.max_i64 |> Num.to_i128) then
            (Num.max_i64 |> Num.to_i128) * (24)
        else if (Num.to_i128(hours) // (24)) < (Num.min_i64 |> Num.to_i128) then
            (Num.min_i64 |> Num.to_i128) * (24)
        else
            hours |> Num.to_i128
    {
        days: hours_saturated // 24 |> Num.to_i64,
        hours: hours_saturated % 24 |> Num.to_i8,
        minutes: 0,
        seconds: 0,
        nanoseconds: 0,
    }

## Convert a `Duration` object to hours (truncates minutes and lower).
to_hours : Duration -> I64
to_hours = |duration|
    (Num.to_i64(duration.hours))
    |> Num.add_saturated((Num.to_i64(duration.days)) |> Num.mul_saturated(24))

## Create a `Duration` object from days.
from_days : Int * -> Duration
from_days = |days| 
    days_saturated = 
        if (Num.to_i128(days)) > (Num.max_i64 |> Num.to_i128) then
            Num.max_i64 |> Num.to_i128
        else if (Num.to_i128(days)) < (Num.min_i64 |> Num.to_i128) then
            Num.min_i64 |> Num.to_i128
        else
            days |> Num.to_i128
    {
        days: days_saturated |> Num.to_i64,
        hours: 0,
        minutes: 0,
        seconds: 0,
        nanoseconds: 0,
    }

## Convert a `Duration` object to days (truncates hours and lower).
to_days : Duration -> I64
to_days = |duration| duration.days

## Add two `Duration` objects.
add : Duration, Duration -> Duration
add = |d1, d2|
    nanos1 = to_nanoseconds(d1)
    nanos2 = to_nanoseconds(d2)
    nanos1 |> Num.add_saturated(nanos2) |> from_nanoseconds

expect
    days = Num.max_i64
    duration = from_days(days)
    duration |> to_days == days

expect
    d1 = from_days(Num.max_i64 // 2)
    d2 = from_days(Num.max_i64 // 2)
    d3 = from_days((Num.max_i64 // 2) * 2)
    add(d1, d2) == d3

expect
    d1 = from_days(Num.min_i64)
    d2 = from_days(Num.max_i64)
    add(d1, d2) == from_days(-1)

expect
    days = Num.max_i64
    duration = from_days(days)
    add(duration, duration) == from_days(days)

