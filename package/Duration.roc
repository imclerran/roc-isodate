## The duration modules provides the `Duration` type and associated functions for representing time durations and performing date/time arithmetic.
module [
    Duration,
    add,
    format,
    format_unsigned,
    from_days,
    from_hms,
    from_hmsn,
    from_hours,
    from_minutes,
    from_nanoseconds,
    from_seconds,
    sub,
    to_days,
    to_hours,
    to_minutes,
    to_nanoseconds,
    to_seconds,
]

import Const
import Utils

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

## Add two `Duration` objects.
add : Duration, Duration -> Duration
add = |d1, d2|
    nanos1 = to_nanoseconds(d1)
    nanos2 = to_nanoseconds(d2)
    nanos1 |> Num.add_saturated(nanos2) |> from_nanoseconds

## Format a `Time` object according to the given format string.
## The following placeholders are supported:
## - `{d}`: day (0-Num.max_i64)
## - `{hh}`: 2-digit hour (00-23)
## - `{h}`: hour (0-23)
## - `{mm}`: 2-digit minute (00-59)
## - `{m}`: minute (0-59)
## - `{ss}`: 2-digit second (00-59)
## - `{s}`: second (0-59)
## - `{f}` or `{f:}`: fractional part of the second
## - `{f:x}`: fractional part of the second with x digits
## - `{n}`: nanosecond (0-999,999,999)
format : Duration, Str -> Str
format = |d, fmt|
    fmt
    |> Str.replace_first("{d}", Num.to_str(d.days))
    |> Str.replace_first("{hh}", Utils.expand_int_with_zeros(d.hours, 2))
    |> Str.replace_first("{h}", Num.to_str(d.hours))
    |> Str.replace_first("{mm}", Utils.expand_int_with_zeros(d.minutes, 2))
    |> Str.replace_first("{m}", Num.to_str(d.minutes))
    |> Str.replace_first("{ss}", Utils.expand_int_with_zeros(d.seconds, 2))
    |> Str.replace_first("{s}", Num.to_str(d.seconds))
    |> Str.replace_first("{f}", Utils.nanos_to_frac_str(d.nanoseconds) |> Str.drop_prefix(","))
    |> Utils.replace_fx_format(d.nanoseconds)
    |> Str.replace_first("{n}", Num.to_str(d.nanoseconds))

## Format a `Time` object according to the given format string. Negative numbers will not include a minus sign.
## The following placeholders are supported:
## - `{d}`: day (0-Num.max_i64)
## - `{hh}`: 2-digit hour (00-23)
## - `{h}`: hour (0-23)
## - `{mm}`: 2-digit minute (00-59)
## - `{m}`: minute (0-59)
## - `{ss}`: 2-digit second (00-59)
## - `{s}`: second (0-59)
## - `{f}` or `{f:}`: fractional part of the second
## - `{f:x}`: fractional part of the second with x digits
## - `{n}`: nanosecond (0-999,999,999)
format_unsigned : Duration, Str -> Str
format_unsigned = |d, fmt|
    fmt
    |> Str.replace_first("{d}", Num.to_str(d.days))
    |> Str.replace_first("{hh}", Utils.expand_int_with_zeros(d.hours, 2))
    |> Str.replace_first("{h}", Num.to_str(d.hours))
    |> Str.replace_first("{mm}", Utils.expand_int_with_zeros(d.minutes, 2))
    |> Str.replace_first("{m}", Num.to_str(d.minutes))
    |> Str.replace_first("{ss}", Utils.expand_int_with_zeros(d.seconds, 2))
    |> Str.replace_first("{s}", Num.to_str(d.seconds))
    |> Str.replace_first("{f}", Utils.nanos_to_frac_str(d.nanoseconds) |> Str.drop_prefix(","))
    |> Utils.replace_fx_format(d.nanoseconds)
    |> Str.replace_first("{n}", Num.to_str(d.nanoseconds))
    |> Str.replace_each("-", "")

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

from_hms : Int *, Int *, Int * -> Duration
from_hms = |hours, minutes, seconds|
    from_hours(hours) |> add(from_minutes(minutes)) |> add(from_seconds(seconds))

from_hmsn : Int *, Int *, Int *, Int * -> Duration
from_hmsn = |hours, minutes, seconds, nanoseconds|
    from_hours(hours) |> add(from_minutes(minutes)) |> add(from_seconds(seconds)) |> add(from_nanoseconds(nanoseconds))

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

## Subtract two `Duration` objects.
sub : Duration, Duration -> Duration
sub = |d1, d2| 
    nanos1 = to_nanoseconds(d1)
    nanos2 = to_nanoseconds(d2)
    nanos1 |> Num.sub_saturated(nanos2) |> from_nanoseconds

## Convert a `Duration` object to days (truncates hours and lower).
to_days : Duration -> I64
to_days = |duration| duration.days

## Convert a `Duration` object to hours (truncates minutes and lower).
to_hours : Duration -> I64
to_hours = |duration|
    (Num.to_i64(duration.hours))
    |> Num.add_saturated((Num.to_i64(duration.days)) |> Num.mul_saturated(24))

## Convert a `Duration` object to minutes (truncates seconds and lower).
to_minutes : Duration -> I64
to_minutes = |duration|
    (Num.to_i64(duration.minutes))
    |> Num.add_saturated((Num.to_i64(duration.hours)) |> Num.mul_saturated(Const.minutes_per_hour))
    |> Num.add_saturated((duration.days) |> Num.mul_saturated(Const.minutes_per_day))

## Convert a `Duration` object to nanoseconds.
to_nanoseconds : Duration -> I128
to_nanoseconds = |duration|
    (Num.to_i128(duration.nanoseconds))
    |> Num.add_saturated((Num.to_i128(duration.seconds)) |> Num.mul_saturated(Const.nanos_per_second))
    |> Num.add_saturated((Num.to_i128(duration.minutes)) |> Num.mul_saturated(Const.nanos_per_minute))
    |> Num.add_saturated((Num.to_i128(duration.hours)) |> Num.mul_saturated(Const.nanos_per_hour))
    |> Num.add_saturated((Num.to_i128(duration.days)) |> Num.mul_saturated(Const.nanos_per_day))



## Convert a `Duration` object to seconds (truncates nanoseconds).
to_seconds : Duration -> I64
to_seconds = |duration|
    (Num.to_i64(duration.seconds)) 
    |> Num.add_saturated((Num.to_i64(duration.minutes)) |> Num.mul_saturated(Const.seconds_per_minute))
    |> Num.add_saturated((Num.to_i64(duration.hours)) |> Num.mul_saturated(Const.seconds_per_hour))
    |> Num.add_saturated((duration.days) |> Num.mul_saturated(Const.seconds_per_day))

# <==== TESTS ====>
# <---- add ---->
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

# <---- from_hmsn ---->
expect 
    res = from_hmsn(Num.max_i64, 0, 0, 0) 
    res == from_days(384307168202282325) |> add(from_hours(7))

expect
    res = from_hmsn(0, Num.max_i64, 0, 0)
    res == from_days(6405119470038038) |> add(from_hours(18)) |> add(from_minutes(7))

expect
    res = from_hmsn(0, 0, Num.max_i64, 0)
    res == from_days(106751991167300) |> add(from_hours(15)) |> add(from_minutes(30)) |> add(from_seconds(7))

expect
    res = from_hmsn(0, 0, 0, Num.max_i64)
    res == from_days(106751) |> add(from_hours(23)) |> add(from_minutes(47)) |> add(from_seconds(16)) |> add(from_nanoseconds(854775807))

expect
    res = from_hmsn(Num.max_i64, Num.max_i64, Num.max_i64, Num.max_i64)
    res == from_days(390819039663594414) |> add(from_hours(63)) |> add(from_minutes(84)) |> add(from_seconds(23)) |> add(from_nanoseconds(854775807))

# <---- sub ---->
expect 
    d = from_days(Num.max_i64)
    sub(d, d) == from_days(0)

expect
    d = from_days(Num.min_i64)
    sub(d, d) == from_days(0)

expect
    d1 = from_days(1)
    d2 = from_days(2)
    sub(d1, d2) == from_days(-1)


# <---- saturation test ---->
expect
    days_over = Num.max_i64 |> Num.to_i128 |> Num.add(1)
    duration = from_days(days_over)
    duration |> to_days == Num.max_i64

