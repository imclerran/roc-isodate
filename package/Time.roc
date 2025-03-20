## The Time module provides the `Time` type as well as functions for working with time values.
##
## These functions include functions for creating `Time` objects from various numeric values, converting `Time`s to and from ISO 8601 strings, and performing arithmetic operations on `Time`s.
module [
    Time,
    add_duration,
    add_hours,
    add_minutes,
    add_nanoseconds,
    add_seconds,
    after,
    before,
    compare,
    equal,
    from_hms,
    from_hmsn,
    from_iso_str,
    from_iso_u8,
    from_nanos_since_midnight,
    midnight,
    normalize,
    to_iso_str,
    to_iso_u8,
    to_nanos_since_midnight,
]

import Const
import Const exposing [
    nanos_per_hour,
    nanos_per_minute,
    nanos_per_second,
]
import Duration
import Duration exposing [Duration]
import Utils exposing [
    compare_values,
    expand_int_with_zeros,
    utf8_to_frac,
    utf8_to_int_signed,
    validate_utf8_single_bytes,
]
import rtils.ListUtils exposing [split_at_indices, split_with_delims]

## Object representing a time of day. Hours may be less than 0 or greater than 24.
## ```
## Time : {
##     hour : I8,
##     minute : U8,
##     second : U8,
##     nanosecond : U32
## }
## ```
Time : { hour : I8, minute : U8, second : U8, nanosecond : U32 }

## Add a `Duration` object to a `Time` object.
add_duration : Time, Duration -> Time
add_duration = |time, duration|
    duration_nanos = Duration.to_nanoseconds(duration)
    time_nanos = to_nanos_since_midnight(time) |> Num.to_i128
    (duration_nanos + time_nanos) |> from_nanos_since_midnight

## Add hours to a `Time` object.
add_hours : Time, Int * -> Time
add_hours = |time, hours| add_nanoseconds(time, (hours * Const.nanos_per_hour))

## Add minutes to a `Time` object.
add_minutes : Time, Int * -> Time
add_minutes = |time, minutes| add_nanoseconds(time, (minutes * Const.nanos_per_minute))

## Add nanoseconds to a `Time` object.
add_nanoseconds : Time, Int * -> Time
add_nanoseconds = |time, nanos|
    to_nanos_since_midnight(time) + Num.to_i64(nanos) |> from_nanos_since_midnight

## Add seconds to a `Time` object.
add_seconds : Time, Int * -> Time
add_seconds = |time, seconds| add_nanoseconds(time, (seconds * Const.nanos_per_second))

## Determine if the first `Time` occurs after the second `Time`.
after : Time, Time -> Bool
after = |a, b| compare a b == GT

## Determine if the first `Time` occurs before the second `Time`.
before : Time, Time -> Bool
before = |a, b| compare a b == LT

combine_time_and_offset_results = |time_res, offset_res|
    when (time_res, offset_res) is
        (Ok(time), Ok(offset)) ->
            Time.add_duration(time, offset) |> Ok

        (_, _) -> Err(InvalidTimeFormat)

## Compare two `Time` objects.
## If the first occurs before the second, it returns LT.
## If the first and the second are equal, it returns EQ.
## If the first occurs after the second, it returns GT.
compare : Time, Time -> [LT, EQ, GT]
compare = |a, b|
    compare_values a.hour b.hour
    |> |result| if result != EQ then result else compare_values a.minute b.minute
    |> |result| if result != EQ then result else compare_values a.second b.second
    |> |result| if result != EQ then result else compare_values a.nanosecond b.nanosecond

count_frac_width : U32, Int _ -> Int _
count_frac_width = |num, width|
    if num == 0 then
        0
    else if num % 10 == 0 then
        count_frac_width((num // 10), (width - 1))
    else
        width

## Determine if the first `Time` is equal to the second `Time`.
equal : Time, Time -> Bool
equal = |a, b| compare a b == EQ

## Create a `Time` object from the hour, minute, and second.
from_hms : Int *, Int *, Int * -> Time
from_hms = |hour, minute, second| { hour: Num.to_i8(hour), minute: Num.to_u8(minute), second: Num.to_u8(second), nanosecond: 0u32 }

## Create a `Time` object from the hour, minute, second, and nanosecond.
from_hmsn : Int *, Int *, Int *, Int * -> Time
from_hmsn = |hour, minute, second, nanosecond|
    { hour: Num.to_i8(hour), minute: Num.to_u8(minute), second: Num.to_u8(second), nanosecond: Num.to_u32(nanosecond) }

## Convert an ISO 8601 string to a `Time` object.
from_iso_str : Str -> Result Time [InvalidTimeFormat]
from_iso_str = |str| Str.to_utf8(str) |> from_iso_u8

## Convert an ISO 8601 list of UTF-8 bytes to a `Time` object.
from_iso_u8 : List U8 -> Result Time [InvalidTimeFormat]
from_iso_u8 = |bytes|
    if validate_utf8_single_bytes(bytes) then
        stripped_bytes = strip_t_and_z(bytes)
        when (split_with_delims(stripped_bytes, |b| List.contains(['.', ',', '+', '-'], b)), List.last(bytes)) is
            # time.fractionaltime+timeoffset / time,fractionaltime-timeoffset
            ([time_bytes, [byte1], fractional_bytes, [byte2], offset_bytes], Ok(last_byte)) if last_byte != 'Z' ->
                time_res = parse_fractional_time(time_bytes, List.join([[byte1], fractional_bytes]))
                offset_res = parse_time_offset(List.join([[byte2], offset_bytes]))
                combine_time_and_offset_results(time_res, offset_res)

            # time+timeoffset / time-timeoffset
            ([time_bytes, [byte1], offset_bytes], Ok(last_byte)) if (byte1 == '+' or byte1 == '-') and last_byte != 'Z' ->
                time_res = parse_whole_time(time_bytes)
                offset_res = parse_time_offset(List.join([[byte1], offset_bytes]))
                combine_time_and_offset_results(time_res, offset_res)

            # time.fractionaltime / time,fractionaltime
            ([time_bytes, [byte1], fractional_bytes], _) if byte1 == ',' or byte1 == '.' ->
                parse_fractional_time(time_bytes, List.join([[byte1], fractional_bytes]))

            # time
            ([time_bytes], _) -> parse_whole_time(time_bytes)
            _ -> Err(InvalidTimeFormat)
    else
        Err(InvalidTimeFormat)

## Convert nanoseconds since midnight to a `Time` object.
from_nanos_since_midnight : Int * -> Time
from_nanos_since_midnight = |nanos|
    nanos1 = nanos |> Num.rem(Const.nanos_per_day) |> Num.add(Const.nanos_per_day) |> Num.rem(Const.nanos_per_day) |> Num.to_u64
    nanos2 = nanos1 % nanos_per_hour
    minute = nanos2 // nanos_per_minute |> Num.to_u8
    nanos3 = nanos2 % nanos_per_minute
    second = nanos3 // nanos_per_second |> Num.to_u8
    nanosecond = nanos3 % nanos_per_second |> Num.to_u32
    hour = (nanos - Num.int_cast((Num.to_i64(minute) * nanos_per_minute + Num.to_i64(second) * nanos_per_second + Num.to_i64(nanosecond)))) // nanos_per_hour |> Num.to_i8 # % Const.hoursPerDay |> Num.toI8
    { hour, minute, second, nanosecond }

## `Time` object representing 00:00:00.
midnight : Time
midnight = { hour: 0, minute: 0, second: 0, nanosecond: 0 }

nanos_to_frac_str : U32 -> Str
nanos_to_frac_str = |nanos|
    length = count_frac_width(nanos, 9)
    untrimmed_str = (if nanos == 0 then "" else Str.concat(",", expand_int_with_zeros(nanos, length)))
    when untrimmed_str |> Str.to_utf8 |> List.take_first((length + 1)) |> Str.from_utf8 is
        Ok(str) -> str
        Err(_) -> untrimmed_str

## Normalize a `Time` object to ensure that the hour is between 0 and 23.
normalize : Time -> Time
normalize = |time|
    h_normalized = time.hour |> Num.rem(Const.hours_per_day) |> Num.add(Const.hours_per_day) |> Num.rem(Const.hours_per_day)
    from_hmsn(h_normalized, time.minute, time.second, time.nanosecond)

parse_whole_time : List U8 -> Result Time [InvalidTimeFormat]
parse_whole_time = |bytes|
    when bytes is
        [_, _] -> parse_local_time_hour(bytes) # hh
        [_, _, _, _] -> parse_local_time_minute_basic(bytes) # hhmm
        [_, _, ':', _, _] -> parse_local_time_minute_extended(bytes) # hh:mm
        [_, _, _, _, _, _] -> parse_local_time_basic(bytes) # hhmmss
        [_, _, ':', _, _, ':', _, _] -> parse_local_time_extended(bytes) # hh:mm:ss
        _ -> Err(InvalidTimeFormat)

parse_fractional_time : List U8, List U8 -> Result Time [InvalidTimeFormat]
parse_fractional_time = |whole_bytes, fractional_bytes|
    add_duration_and_time = |d, t| Time.add_duration(t, d)
    when (whole_bytes, utf8_to_frac(fractional_bytes)) is
        ([_, _], Ok(frac)) -> # hh
            time = parse_local_time_hour(whole_bytes)?
            frac * Const.nanos_per_hour |> Num.round |> Duration.from_nanoseconds |> add_duration_and_time(time) |> Ok

        ([_, _, _, _], Ok(frac)) -> # hhmm
            time = parse_local_time_minute_basic(whole_bytes)?
            frac * Const.nanos_per_minute |> Num.round |> Duration.from_nanoseconds |> add_duration_and_time(time) |> Ok

        ([_, _, ':', _, _], Ok(frac)) -> # hh:mm
            time = parse_local_time_minute_extended(whole_bytes)?
            frac * Const.nanos_per_minute |> Num.round |> Duration.from_nanoseconds |> add_duration_and_time(time) |> Ok

        ([_, _, _, _, _, _], Ok(frac)) -> # hhmmss
            time = parse_local_time_basic(whole_bytes)?
            frac * Const.nanos_per_second |> Num.round |> Duration.from_nanoseconds |> add_duration_and_time(time) |> Ok

        ([_, _, ':', _, _, ':', _, _], Ok(frac)) -> # hh:mm:ss
            time = parse_local_time_extended(whole_bytes)?
            frac * Const.nanos_per_second |> Num.round |> Duration.from_nanoseconds |> add_duration_and_time(time) |> Ok

        _ -> Err(InvalidTimeFormat)

parse_time_offset : List U8 -> Result Duration [InvalidTimeFormat]
parse_time_offset = |bytes|
    when bytes is
        ['-', h1, h2] ->
            parse_time_offset_help(h1, h2, '0', '0', 1)

        ['+', h1, h2] ->
            parse_time_offset_help(h1, h2, '0', '0', -1)

        ['-', h1, h2, m1, m2] ->
            parse_time_offset_help(h1, h2, m1, m2, 1)

        ['+', h1, h2, m1, m2] ->
            parse_time_offset_help(h1, h2, m1, m2, -1)

        ['-', h1, h2, ':', m1, m2] ->
            parse_time_offset_help(h1, h2, m1, m2, 1)

        ['+', h1, h2, ':', m1, m2] ->
            parse_time_offset_help(h1, h2, m1, m2, -1)

        _ -> Err(InvalidTimeFormat)

parse_time_offset_help : U8, U8, U8, U8, I64 -> Result Duration [InvalidTimeFormat]
parse_time_offset_help = |h1, h2, m1, m2, sign|
    is_valid_offset = |offset| if offset >= -14 * Const.nanos_per_hour and offset <= 12 * Const.nanos_per_hour then Valid else Invalid
    when (utf8_to_int_signed([h1, h2]), utf8_to_int_signed([m1, m2])) is
        (Ok(hour), Ok(minute)) ->
            offset_nanos = sign * (hour * Const.nanos_per_hour + minute * Const.nanos_per_minute)
            when is_valid_offset(offset_nanos) is
                Valid -> Duration.from_nanoseconds(offset_nanos) |> Ok
                Invalid -> Err(InvalidTimeFormat)

        (_, _) -> Err(InvalidTimeFormat)

parse_local_time_hour : List U8 -> Result Time [InvalidTimeFormat]
parse_local_time_hour = |bytes|
    when utf8_to_int_signed(bytes) is
        Ok(hour) if hour >= 0 and hour <= 24 ->
            Time.from_hms(hour, 0, 0) |> Ok

        Ok(_) -> Err(InvalidTimeFormat)
        Err(_) -> Err(InvalidTimeFormat)

parse_local_time_minute_basic : List U8 -> Result Time [InvalidTimeFormat]
parse_local_time_minute_basic = |bytes|
    when split_at_indices(bytes, [2]) is
        [hour_bytes, minute_bytes] ->
            when (utf8_to_int_signed(hour_bytes), utf8_to_int_signed(minute_bytes)) is
                (Ok(hour), Ok(minute)) if hour >= 0 and hour <= 23 and minute >= 0 and minute <= 59 ->
                    Time.from_hms(hour, minute, 0) |> Ok

                (Ok(24), Ok(0)) ->
                    Time.from_hms(24, 0, 0) |> Ok

                (_, _) -> Err(InvalidTimeFormat)

        _ -> Err(InvalidTimeFormat)

parse_local_time_minute_extended : List U8 -> Result Time [InvalidTimeFormat]
parse_local_time_minute_extended = |bytes|
    when split_at_indices(bytes, [2, 3]) is
        [hour_bytes, _, minute_bytes] ->
            when (utf8_to_int_signed(hour_bytes), utf8_to_int_signed(minute_bytes)) is
                (Ok(hour), Ok(minute)) if hour >= 0 and hour <= 23 and minute >= 0 and minute <= 59 ->
                    Time.from_hms(hour, minute, 0) |> Ok

                (Ok(24), Ok(0)) ->
                    Time.from_hms(24, 0, 0) |> Ok

                (_, _) -> Err(InvalidTimeFormat)

        _ -> Err(InvalidTimeFormat)

parse_local_time_basic : List U8 -> Result Time [InvalidTimeFormat]
parse_local_time_basic = |bytes|
    when split_at_indices(bytes, [2, 4]) is
        [hour_bytes, minute_bytes, second_bytes] ->
            when (utf8_to_int_signed(hour_bytes), utf8_to_int_signed(minute_bytes), utf8_to_int_signed(second_bytes)) is
                (Ok(h), Ok(m), Ok(s)) if h >= 0 and h <= 23 and m >= 0 and m <= 59 and s >= 0 and s <= 59 ->
                    Time.from_hms(h, m, s) |> Ok

                (Ok(24), Ok(0), Ok(0)) ->
                    Time.from_hms(24, 0, 0) |> Ok

                (_, _, _) -> Err(InvalidTimeFormat)

        _ -> Err(InvalidTimeFormat)

parse_local_time_extended : List U8 -> Result Time [InvalidTimeFormat]
parse_local_time_extended = |bytes|
    when split_at_indices(bytes, [2, 3, 5, 6]) is
        [hour_bytes, _, minute_bytes, _, second_bytes] ->
            when (utf8_to_int_signed(hour_bytes), utf8_to_int_signed(minute_bytes), utf8_to_int_signed(second_bytes)) is
                (Ok(h), Ok(m), Ok(s)) if h >= 0 and h <= 23 and m >= 0 and m <= 59 and s >= 0 and s <= 59 ->
                    Time.from_hms(h, m, s) |> Ok

                (Ok(24), Ok(0), Ok(0)) ->
                    Time.from_hms(24, 0, 0) |> Ok

                (_, _, _) -> Err(InvalidTimeFormat)

        _ -> Err(InvalidTimeFormat)

strip_t_and_z : List U8 -> List U8
strip_t_and_z = |bytes|
    when bytes is
        ['T', .. as tail] -> strip_t_and_z(tail)
        [.. as head, 'Z'] -> head
        _ -> bytes

## Subtract two `Time` objects to get the `Duration` between them.
sub : Time, Time -> Duration
sub = |a, b|
    a_nanos = to_nanos_since_midnight(a)
    b_nanos = to_nanos_since_midnight(b)
    duration_nanos = a_nanos - b_nanos
    Duration.from_nanoseconds(duration_nanos)

## Convert a `Time` object to an ISO 8601 string.
to_iso_str : Time -> Str
to_iso_str = |time|
    expand_int_with_zeros(time.hour, 2)
    |> Str.concat(":")
    |> Str.concat(expand_int_with_zeros(time.minute, 2))
    |> Str.concat(":")
    |> Str.concat(expand_int_with_zeros(time.second, 2))
    |> Str.concat(nanos_to_frac_str(time.nanosecond))

## Convert a `Time` object to an ISO 8601 list of UTF-8 bytes.
to_iso_u8 : Time -> List U8
to_iso_u8 = |time| to_iso_str(time) |> Str.to_utf8

## Convert a `Time` object to the number of nanoseconds since midnight.
to_nanos_since_midnight : Time -> I64
to_nanos_since_midnight = |time|
    h_nanos = time.hour |> Num.to_i64 |> Num.mul(Const.nanos_per_hour) |> Num.to_i64
    m_nanos = time.minute |> Num.to_i64 |> Num.mul(Const.nanos_per_minute) |> Num.to_i64
    s_nanos = time.second |> Num.to_i64 |> Num.mul(Const.nanos_per_second) |> Num.to_i64
    nanos = time.nanosecond |> Num.to_i64
    h_nanos + m_nanos + s_nanos + nanos

# <===== TESTS ====>
# <---- add_nanoseconds ---->
expect add_nanoseconds(from_hmsn(12, 34, 56, 5), Const.nanos_per_second) == from_hmsn(12, 34, 57, 5)
expect add_nanoseconds(from_hmsn(12, 34, 56, 5), -Const.nanos_per_second) == from_hmsn(12, 34, 55, 5)

# <---- add_seconds ---->
expect add_seconds(from_hms(12, 34, 56), 59) == from_hms(12, 35, 55)
expect add_seconds(from_hms(12, 34, 56), -59) == from_hms(12, 33, 57)

# <---- add_minutes ---->
expect add_minutes(from_hms(12, 34, 56), 59) == from_hms(13, 33, 56)
expect add_minutes(from_hms(12, 34, 56), -59) == from_hms(11, 35, 56)

# <---- add_hours ---->
expect add_hours(from_hms(12, 34, 56), 1) == from_hms(13, 34, 56)
expect add_hours(from_hms(12, 34, 56), -1) == from_hms(11, 34, 56)
expect add_hours(from_hms(12, 34, 56), 12) == from_hms(24, 34, 56)

# <---- add_duration ---->
expect 
    duration = Duration.from_hours(1)
    res = add_duration(from_hms(0, 0, 0), duration)
    res == from_hms(1, 0, 0)

# <---- from_nanos_since_midnight ---->
expect from_nanos_since_midnight(-123) == from_hmsn(-1, 59, 59, 999_999_877)
expect from_nanos_since_midnight(0) == midnight
expect from_nanos_since_midnight((24 * Const.nanos_per_hour)) == from_hms(24, 0, 0)
expect from_nanos_since_midnight((25 * nanos_per_hour)) == from_hms(25, 0, 0)
expect from_nanos_since_midnight((12 * nanos_per_hour + 34 * nanos_per_minute + 56 * nanos_per_second + 5)) == from_hmsn(12, 34, 56, 5)

# <---- normalize ---->
expect Time.normalize(from_hms(-1, 0, 0)) == from_hms(23, 0, 0)
expect Time.normalize(from_hms(24, 0, 0)) == from_hms(0, 0, 0)
expect Time.normalize(from_hms(25, 0, 0)) == from_hms(1, 0, 0)

# <---- to_iso_str ---->
expect to_iso_str(from_hmsn(12, 34, 56, 5)) == "12:34:56,000000005"
expect to_iso_str(midnight) == "00:00:00"
expect
    str = to_iso_str(from_hmsn(0, 0, 0, 500_000_000))
    str == "00:00:00,5"

# <---- from_nanos_since_midnight ---->
expect from_nanos_since_midnight(-123) == from_hmsn(-1, 59, 59, 999_999_877)
expect from_nanos_since_midnight(0) == midnight
expect from_nanos_since_midnight((24 * Const.nanos_per_hour)) == from_hms(24, 0, 0)
expect from_nanos_since_midnight((25 * Const.nanos_per_hour)) == from_hms(25, 0, 0)

# <---- sub ---->
expect sub(from_hms(12, 34, 56), from_hms(12, 34, 55)) == Duration.from_seconds(1)
expect sub(from_hmsn(25, 0, 0, 1), from_hmsn(1, 1, 1, 2)) == Duration.from_nanoseconds(23 * Const.nanos_per_hour + 58 * Const.nanos_per_minute + 59 * Const.nanos_per_second - 1)
expect sub(from_hms(-12, 34, 56), from_hms(12, 34, 55)) == Duration.from_nanoseconds(-1 * Const.nanos_per_hour * 24 + Const.nanos_per_second)

# <---- to_nanos_since_midnight ---->
expect to_nanos_since_midnight({ hour: 12, minute: 34, second: 56, nanosecond: 5 }) == 12 * nanos_per_hour + 34 * nanos_per_minute + 56 * nanos_per_second + 5
expect to_nanos_since_midnight(from_hmsn(12, 34, 56, 5)) == 12 * Const.nanos_per_hour + 34 * Const.nanos_per_minute + 56 * Const.nanos_per_second + 5
expect to_nanos_since_midnight(from_hmsn(-1, 0, 0, 0)) == -1 * Const.nanos_per_hour

# <---- before ---->
expect
    a = from_nanos_since_midnight 0
    b = from_nanos_since_midnight 0
    !(b |> before a)
expect
    a = from_nanos_since_midnight 0
    b = from_nanos_since_midnight 1
    !(b |> before a)
expect
    a = from_nanos_since_midnight 1
    b = from_nanos_since_midnight 0
    b |> before a

# <---- after ---->
expect
    a = from_nanos_since_midnight 0
    b = from_nanos_since_midnight 0
    !(b |> after a)
expect
    a = from_nanos_since_midnight 0
    b = from_nanos_since_midnight 1
    b |> after a
expect
    a = from_nanos_since_midnight 1
    b = from_nanos_since_midnight 0
    !(b |> after a)

# <---- equal ---->
expect
    a = from_nanos_since_midnight 0
    b = from_nanos_since_midnight 0
    b |> equal a
expect
    a = from_nanos_since_midnight 0
    b = from_nanos_since_midnight 1
    !(b |> equal a)
expect
    a = from_nanos_since_midnight 1
    b = from_nanos_since_midnight 0
    !(b |> equal a)
