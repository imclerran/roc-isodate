## The Time module provides the `Time` type as well as functions for working with time values.
##
## These functions include functions for creating `Time` objects from various numeric values, converting `Time`s to and from ISO 8601 strings, and performing arithmetic operations on `Time`s.
import Const
import Duration
import Utils

## A time of day, from `00:00:00` up to but not including `24:00:00`.
## ```
## Time : {
##     hour : U8,
##     minute : U8,
##     second : U8,
##     nanosecond : U32
## }
## ```
## Every `Time` is a valid time of day. Constructors validate their fields and return a `Try`,
## ISO 8601 parsing normalizes UTC offsets and the end-of-day notation `24:00:00`, and arithmetic wraps around midnight.
## When you need to know how many days were crossed, use [`add_duration_with_day_offset`](Time#add_duration_with_day_offset)
## or [`from_iso_str_with_day_offset`](Time#from_iso_str_with_day_offset).
Time :: { hour : U8, minute : U8, second : U8, nanosecond : U32 }.{

	## Are two Times equal?
	## Two values are equal only when all of their parts match, so normalize non-normalized values first if you want calendar equality.
	is_eq : _

	## Hash a `Time`, so it can be used as a `Dict` key or `Set` element. Agrees with [`is_eq`](Time#is_eq).
	to_hash : _

	## Show the `Time` as an ISO 8601 string, such as `09:30:00` or `09:30:00,5`.
	## This is what `Str.inspect`, `dbg`, and failing `expect` reports use.
	to_inspect : Time -> Str
	to_inspect = |time| to_iso_str(time)

	## The hour of the `Time`, from 0 to 23.
	hour : Time -> U8
	hour = |time| time.hour

	## The minute of the `Time`, from 0 to 59.
	minute : Time -> U8
	minute = |time| time.minute

	## The second of the `Time`, from 0 to 59.
	second : Time -> U8
	second = |time| time.second

	## The nanosecond of the `Time`, from 0 to 999,999,999.
	nanosecond : Time -> U32
	nanosecond = |time| time.nanosecond

	## Same as [`add_duration`](Time#add_duration)
	add : Time, Duration -> Time
	add = add_duration

	## Add a `Duration` to a `Time`, wrapping around midnight: `23:00:00` plus two hours is `01:00:00`.
	## Use [`add_duration_with_day_offset`](Time#add_duration_with_day_offset) to also learn how many days were crossed.
	add_duration : Time, Duration -> Time
	add_duration = |time, duration| add_nanos_i128(time, duration.to_nanoseconds()).time

	## Add a `Duration` to a `Time`, wrapping around midnight, and also return the number of whole days crossed.
	## ```
	## Time.from_hms(23, 0, 0)?.add_duration_with_day_offset(Duration.from_hours(2)) == { time: Time.from_hms(1, 0, 0)?, day_offset: 1 }
	## Time.from_hms(1, 0, 0)?.add_duration_with_day_offset(Duration.from_hours(-2)) == { time: Time.from_hms(23, 0, 0)?, day_offset: -1 }
	## ```
	add_duration_with_day_offset : Time, Duration -> { time : Time, day_offset : I64 }
	add_duration_with_day_offset = |time, duration| add_nanos_i128(time, duration.to_nanoseconds())

	## Add hours to a `Time`, wrapping around midnight.
	add_hours : Time, I64 -> Time
	add_hours = |time, hours| add_nanos_i128(time, hours.to_i128() * Const.nanos_per_hour.to_i128()).time

	## Add minutes to a `Time`, wrapping around midnight.
	add_minutes : Time, I64 -> Time
	add_minutes = |time, minutes| add_nanos_i128(time, minutes.to_i128() * Const.nanos_per_minute.to_i128()).time

	## Add nanoseconds to a `Time`, wrapping around midnight.
	add_nanoseconds : Time, I64 -> Time
	add_nanoseconds = |time, nanos| add_nanos_i128(time, nanos.to_i128()).time

	## Add seconds to a `Time`, wrapping around midnight.
	add_seconds : Time, I64 -> Time
	add_seconds = |time, seconds| add_nanos_i128(time, seconds.to_i128() * Const.nanos_per_second.to_i128()).time

	## Determine if the first `Time` occurs after the second `Time`.
	after : Time, Time -> Bool
	after = |a, b| a.order_relative_to(b) == After

	## Determine if the first `Time` occurs before the second `Time`.
	before : Time, Time -> Bool
	before = |a, b| a.order_relative_to(b) == Before

	## Whether the first `Time` is before the second. This is what the `<` operator uses.
	is_lt : Time, Time -> Bool
	is_lt = |a, b| a.order_relative_to(b) == Before

	## Whether the first `Time` is after the second. This is what the `>` operator uses.
	is_gt : Time, Time -> Bool
	is_gt = |a, b| a.order_relative_to(b) == After

	## Whether the first `Time` is before or the same as the second. This is what the `<=` operator uses.
	is_lte : Time, Time -> Bool
	is_lte = |a, b| a.order_relative_to(b) != After

	## Whether the first `Time` is after or the same as the second. This is what the `>=` operator uses.
	is_gte : Time, Time -> Bool
	is_gte = |a, b| a.order_relative_to(b) != Before

	## The earlier of two `Time`s. Returns the first when they are equal. Lets `List.min` work on a `List(Time)`.
	min : Time, Time -> Time
	min = |a, b| if b.is_lt(a) { b } else { a }

	## The later of two `Time`s. Returns the first when they are equal. Lets `List.max` work on a `List(Time)`.
	max : Time, Time -> Time
	max = |a, b| if b.is_gt(a) { b } else { a }

	## Compare two `Time` objects.
	## If the first occurs before the second, it returns Before.
	## If the first and the second are equal, it returns Same.
	## If the first occurs after the second, it returns After.
	## This is what `List.sort` and `List.sort_by` use.
	order_relative_to : Time, Time -> [Before, Same, After]
	order_relative_to = |a, b| {
		a.hour.order_relative_to(b.hour)
			|> (|result| if result != Same {
				result
			} else {
				a.minute.order_relative_to(b.minute)
			})
			|> (|result| if result != Same {
				result
			} else {
				a.second.order_relative_to(b.second)
			})
			|> (|result| if result != Same {
				result
			} else {
				a.nanosecond.order_relative_to(b.nanosecond)
			})
	}

	## Format a `Time` object according to the given format string.
	## The following placeholders are supported:
	## - `{hh}`: 2-digit hour (00-23)
	## - `{h}`: hour (0-23)
	## - `{mm}`: 2-digit minute (00-59)
	## - `{m}`: minute (0-59)
	## - `{ss}`: 2-digit second (00-59)
	## - `{s}`: second (0-59)
	## - `{f}` or `{f:}`: fractional part of the second
	## - `{f:x}`: fractional part of the second with x digits
	## - `{n}`: nanosecond (0-999,999,999)
	format : Time, Str -> Str
	format = |time, fmt| {
		(
			fmt
				.replace_first("{hh}", Utils.expand_int_with_zeros(time.hour.to_i64(), 2))
				.replace_first("{h}", time.hour.to_str())
				.replace_first("{mm}", Utils.expand_int_with_zeros(time.minute.to_i64(), 2))
				.replace_first("{m}", time.minute.to_str())
				.replace_first("{ss}", Utils.expand_int_with_zeros(time.second.to_i64(), 2))
				.replace_first("{s}", time.second.to_str())
				.replace_first("{f}", Utils.nanos_to_frac_str(time.nanosecond.to_i32_wrap()).drop_prefix(","))
				|> Utils.replace_fx_format(time.nanosecond.to_i32_wrap()),
		).replace_first("{n}", time.nanosecond.to_str())
	}

	## Create a `Time` from the hour, minute, and second. The hour must be 0 to 23, and the minute and second 0 to 59.
	## ISO 8601's end-of-day notation `24:00:00` names the next day's midnight, so it is accepted by
	## [`from_iso_str`](Time#from_iso_str) but not here.
	from_hms : U8, U8, U8 -> Try(Time, [InvalidHour, InvalidMinute, InvalidSecond])
	from_hms = |h, m, s| {
		if h > 23 {
			Err(InvalidHour)
		} else if m > 59 {
			Err(InvalidMinute)
		} else if s > 59 {
			Err(InvalidSecond)
		} else {
			Ok({ hour: h, minute: m, second: s, nanosecond: 0 })
		}
	}

	## Create a `Time` from the hour, minute, second, and nanosecond. The hour must be 0 to 23, the minute and second 0 to 59,
	## and the nanosecond 0 to 999,999,999. See [`from_hms`](Time#from_hms).
	from_hmsn : U8, U8, U8, U32 -> Try(Time, [InvalidHour, InvalidMinute, InvalidSecond, InvalidNanosecond])
	from_hmsn = |h, m, s, n| {
		if h > 23 {
			Err(InvalidHour)
		} else if m > 59 {
			Err(InvalidMinute)
		} else if s > 59 {
			Err(InvalidSecond)
		} else if n > 999_999_999 {
			Err(InvalidNanosecond)
		} else {
			Ok({ hour: h, minute: m, second: s, nanosecond: n })
		}
	}

	## Convert an ISO 8601 string to a `Time` object.
	## The result is always a time of day from `00:00:00` up to but not including `24:00:00`.
	## The end-of-day notation `24:00:00` gives midnight, and a UTC offset that carries the time across midnight wraps around,
	## so `"23:00:00-05:00"` gives `04:00:00`.
	## Use [`from_iso_str_with_day_offset`](Time#from_iso_str_with_day_offset) to find out how many days were carried.
	from_iso_str : Str -> Try(Time, [InvalidTimeFormat])
	from_iso_str = |str| str.to_utf8() |> from_iso_u8

	## Convert an ISO 8601 list of UTF-8 bytes to a `Time` object. See [`from_iso_str`](Time#from_iso_str).
	from_iso_u8 : List(U8) -> Try(Time, [InvalidTimeFormat])
	from_iso_u8 = |bytes| Ok(from_iso_u8_with_day_offset(bytes)?.time)

	## Convert an ISO 8601 string to a `Time` object, along with the number of days the time was carried across midnight.
	## ```
	## Time.from_iso_str_with_day_offset("23:00:00-05:00") == Ok({ time: Time.from_hms(4, 0, 0)?, day_offset: 1 })
	## Time.from_iso_str_with_day_offset("01:00:00+03:00") == Ok({ time: Time.from_hms(22, 0, 0)?, day_offset: -1 })
	## Time.from_iso_str_with_day_offset("24:00:00") == Ok({ time: Time.midnight, day_offset: 1 })
	## ```
	from_iso_str_with_day_offset : Str -> Try({ time : Time, day_offset : I64 }, [InvalidTimeFormat])
	from_iso_str_with_day_offset = |str| str.to_utf8() |> from_iso_u8_with_day_offset

	## Convert an ISO 8601 list of UTF-8 bytes to a `Time` object, along with the number of days the time was carried across midnight.
	## See [`from_iso_str_with_day_offset`](Time#from_iso_str_with_day_offset).
	from_iso_u8_with_day_offset : List(U8) -> Try({ time : Time, day_offset : I64 }, [InvalidTimeFormat])
	from_iso_u8_with_day_offset = |bytes| {
		total = parse_iso_u8_nanos(bytes)?
		day_offset = total.div_floor_by(Const.nanos_per_day)
		Ok({ time: unchecked_from_nanos(total - day_offset * Const.nanos_per_day), day_offset })
	}

	## Convert nanoseconds since midnight to a `Time`. The value must be at least 0 and less than the number of nanoseconds in a day.
	## To wrap a value around midnight instead, add it to [`midnight`](Time#midnight) with [`add_nanoseconds`](Time#add_nanoseconds).
	from_nanos_since_midnight : I64 -> Try(Time, [NanosecondsOutOfRange])
	from_nanos_since_midnight = |nanos| {
		if nanos < 0 or nanos >= Const.nanos_per_day {
			Err(NanosecondsOutOfRange)
		} else {
			Ok(unchecked_from_nanos(nanos))
		}
	}

	## `Time` object representing 00:00:00.
	midnight : Time
	midnight = { hour: 0, minute: 0, second: 0, nanosecond: 0 }

	## The latest `Time` that can be represented: 23:59:59.999999999, the last nanosecond of the day.
	highest : Time
	highest = { hour: 23, minute: 59, second: 59, nanosecond: 999_999_999 }

	## The earliest `Time` that can be represented: 00:00:00. Same as [`midnight`](Time#midnight).
	lowest : Time
	lowest = midnight

	## Every `Time` is already a valid time of day, so this returns its input unchanged.
	## It is kept for code written when a `Time` could hold an hour outside 0 to 23.
	normalize : Time -> Time
	normalize = |time| time

	## Subtract two `Time` objects to get the `Duration` between them. The result is negative when the first is earlier.
	sub : Time, Time -> Duration
	sub = |a, b| {
		a_nanos = to_nanos_since_midnight(a)
		b_nanos = to_nanos_since_midnight(b)
		Duration.from_nanoseconds((a_nanos - b_nanos).to_i128())
	}

	## Let a string literal be used where a `Time` is expected, so the ISO 8601 time is checked at compile time.
	## ```
	## standup : Time
	## standup = "09:30:00"
	## ```
	## An invalid literal is a compile-time error.
	from_quote : Str -> Try(Time, [BadQuotedBytes(Str)])
	from_quote = |raw| {
		match from_iso_str(raw) {
			Ok(time) => Ok(time)
			Err(InvalidTimeFormat) => Err(BadQuotedBytes("expected an ISO 8601 time, such as 09:30:00, but got ${raw}"))
		}
	}

	## Convert a `Time` object to an ISO 8601 string.
	to_iso_str : Time -> Str
	to_iso_str = |time| {
		Utils.expand_int_with_zeros(time.hour.to_i64(), 2)
			.concat(":")
			.concat(Utils.expand_int_with_zeros(time.minute.to_i64(), 2))
			.concat(":")
			.concat(Utils.expand_int_with_zeros(time.second.to_i64(), 2))
			.concat(Utils.nanos_to_frac_str(time.nanosecond.to_i32_wrap()))
	}

	## Convert a `Time` object to an ISO 8601 list of UTF-8 bytes.
	to_iso_u8 : Time -> List(U8)
	to_iso_u8 = |time| to_iso_str(time).to_utf8()

	## Convert a `Time` object to the number of nanoseconds since midnight.
	to_nanos_since_midnight : Time -> I64
	to_nanos_since_midnight = |time| {
		h_nanos = time.hour.to_i64() * Const.nanos_per_hour.to_i64()
		m_nanos = time.minute.to_i64() * Const.nanos_per_minute.to_i64()
		s_nanos = time.second.to_i64() * Const.nanos_per_second.to_i64()
		nanos = time.nanosecond.to_i64()
		h_nanos + m_nanos + s_nanos + nanos
	}
}

## Build a `Time` from a nanosecond count already known to be at least 0 and less than a day.
unchecked_from_nanos : I64 -> Time
unchecked_from_nanos = |nanos| {
	h = nanos // Const.nanos_per_hour
	rem_h = nanos % Const.nanos_per_hour
	m = rem_h // Const.nanos_per_minute
	rem_m = rem_h % Const.nanos_per_minute
	s = rem_m // Const.nanos_per_second
	n = rem_m % Const.nanos_per_second
	{ hour: h.to_u8_wrap(), minute: m.to_u8_wrap(), second: s.to_u8_wrap(), nanosecond: n.to_u32_wrap() }
}

## Add nanoseconds to a `Time`, wrapping around midnight and reporting the whole days crossed.
## Computed in I128 so no intermediate step can overflow; the day count saturates at the I64 bounds.
add_nanos_i128 : Time, I128 -> { time : Time, day_offset : I64 }
add_nanos_i128 = |time, nanos| {
	day = Const.nanos_per_day.to_i128()
	total = Time.to_nanos_since_midnight(time).to_i128().plus_saturated(nanos)
	days = total.div_floor_by(day)
	day_offset =
		if days > I64.highest.to_i128() {
			I64.highest
		} else if days < I64.lowest.to_i128() {
			I64.lowest
		} else {
			days.to_i64_wrap()
		}
	{ time: unchecked_from_nanos((total - days * day).to_i64_wrap()), day_offset }
}

## Parse an ISO 8601 time to nanoseconds since midnight, before any wrapping. A UTC offset or the end-of-day
## notation `24:00:00` can leave the result negative or at a full day or more.
parse_iso_u8_nanos : List(U8) -> Try(I64, [InvalidTimeFormat])
parse_iso_u8_nanos = |bytes| {
	if Utils.validate_utf8_single_bytes(bytes) {
		stripped_bytes = strip_t_and_z(bytes)
		match (Utils.split_with_delims(stripped_bytes, |b| ['.', ',', '+', '-'].contains(b)), bytes.last()) {
			# time.fractionaltime+timeoffset / time,fractionaltime-timeoffset
			([time_bytes, [byte1], fractional_bytes, [byte2], offset_bytes], Ok(last_byte)) if last_byte != 'Z' => {
				time_nanos = parse_fractional_time(time_bytes, [byte1].concat(fractional_bytes))?
				offset_nanos = parse_time_offset([byte2].concat(offset_bytes))?
				Ok(time_nanos + offset_nanos)
			}

			# time+timeoffset / time-timeoffset
			([time_bytes, [byte1], offset_bytes], Ok(last_byte)) if (byte1 == '+' or byte1 == '-') and last_byte != 'Z' => {
				time_nanos = parse_whole_time(time_bytes)?
				offset_nanos = parse_time_offset([byte1].concat(offset_bytes))?
				Ok(time_nanos + offset_nanos)
			}

			# time.fractionaltime / time,fractionaltime
			([time_bytes, [byte1], fractional_bytes], _) if byte1 == ',' or byte1 == '.' => {
				parse_fractional_time(time_bytes, [byte1].concat(fractional_bytes))
			}

			# time
			([time_bytes], _) => parse_whole_time(time_bytes)
			_ => Err(InvalidTimeFormat)
		}
	} else {
		Err(InvalidTimeFormat)
	}
}

parse_whole_time : List(U8) -> Try(I64, [InvalidTimeFormat])
parse_whole_time = |bytes| {
	match bytes {
		[_, _] => parse_local_time_hour(bytes) # hh
		[_, _, _, _] => parse_local_time_minute_basic(bytes) # hhmm
		[_, _, ':', _, _] => parse_local_time_minute_extended(bytes) # hh:mm
		[_, _, _, _, _, _] => parse_local_time_basic(bytes) # hhmmss
		[_, _, ':', _, _, ':', _, _] => parse_local_time_extended(bytes) # hh:mm:ss
		_ => Err(InvalidTimeFormat)
	}
}

## Parse a time with a fractional final field. The fraction scales by the unit of that field.
## ISO 8601 only allows the end-of-day notation `24:00:00` with a zero fraction, so `24.5` and `24:00:00,5` are rejected.
parse_fractional_time : List(U8), List(U8) -> Try(I64, [InvalidTimeFormat])
parse_fractional_time = |whole_bytes, fractional_bytes| {
	(whole_nanos, unit) =
		match whole_bytes {
			[_, _] => (parse_local_time_hour(whole_bytes)?, Const.nanos_per_hour) # hh
			[_, _, _, _] => (parse_local_time_minute_basic(whole_bytes)?, Const.nanos_per_minute) # hhmm
			[_, _, ':', _, _] => (parse_local_time_minute_extended(whole_bytes)?, Const.nanos_per_minute) # hh:mm
			[_, _, _, _, _, _] => (parse_local_time_basic(whole_bytes)?, Const.nanos_per_second) # hhmmss
			[_, _, ':', _, _, ':', _, _] => (parse_local_time_extended(whole_bytes)?, Const.nanos_per_second) # hh:mm:ss
			_ => return Err(InvalidTimeFormat)
		}
	frac = Utils.utf8_to_frac(fractional_bytes) ?? return Err(InvalidTimeFormat)
	frac_nanos = (frac * unit.to_f64()).round_to_i64_try() ?? return Err(InvalidTimeFormat)
	if whole_nanos == Const.nanos_per_day and frac_nanos != 0 {
		Err(InvalidTimeFormat)
	} else {
		Ok(whole_nanos + frac_nanos)
	}
}

## Parse a UTC offset such as `-05:00` to the nanoseconds that convert the local time to UTC.
parse_time_offset : List(U8) -> Try(I64, [InvalidTimeFormat])
parse_time_offset = |bytes| {
	match bytes {
		['-', h1, h2] => parse_time_offset_help(h1, h2, '0', '0', 1)
		['+', h1, h2] => parse_time_offset_help(h1, h2, '0', '0', -1)
		['-', h1, h2, m1, m2] => parse_time_offset_help(h1, h2, m1, m2, 1)
		['+', h1, h2, m1, m2] => parse_time_offset_help(h1, h2, m1, m2, -1)
		['-', h1, h2, ':', m1, m2] => parse_time_offset_help(h1, h2, m1, m2, 1)
		['+', h1, h2, ':', m1, m2] => parse_time_offset_help(h1, h2, m1, m2, -1)
		_ => Err(InvalidTimeFormat)
	}
}

parse_time_offset_help : U8, U8, U8, U8, I64 -> Try(I64, [InvalidTimeFormat])
parse_time_offset_help = |h1, h2, m1, m2, sign| {
	match (Utils.utf8_to_int_signed([h1, h2]), Utils.utf8_to_int_signed([m1, m2])) {
		(Ok(hour), Ok(minute)) => {
			# ISO 8601 bounds the offset only by its syntax: any offset of less than 24 hours in either direction is
			# accepted, as in chrono, Temporal and Python. Converting the local time to UTC negates the offset.
			if hour >= 0 and hour < 24 and minute >= 0 and minute < 60 {
				Ok(sign * (hour * Const.nanos_per_hour + minute * Const.nanos_per_minute))
			} else {
				Err(InvalidTimeFormat)
			}
		}

		_ => Err(InvalidTimeFormat)
	}
}

## The local-time parsers below return nanoseconds since midnight. Hour 24 is accepted only as exactly `24`, `24:00` or `24:00:00`,
## ISO 8601's notation for the end of the day, and gives a full day of nanoseconds.
parse_local_time_hour : List(U8) -> Try(I64, [InvalidTimeFormat])
parse_local_time_hour = |bytes| {
	match Utils.utf8_to_int_signed(bytes) {
		Ok(hour) if hour >= 0 and hour <= 24 => Ok(hour * Const.nanos_per_hour)
		_ => Err(InvalidTimeFormat)
	}
}

parse_local_time_minute_basic : List(U8) -> Try(I64, [InvalidTimeFormat])
parse_local_time_minute_basic = |bytes| {
	match Utils.split_at_indices(bytes, [2]) {
		[hour_bytes, minute_bytes] => hm_to_nanos(Utils.utf8_to_int_signed(hour_bytes), Utils.utf8_to_int_signed(minute_bytes))
		_ => Err(InvalidTimeFormat)
	}
}

parse_local_time_minute_extended : List(U8) -> Try(I64, [InvalidTimeFormat])
parse_local_time_minute_extended = |bytes| {
	match Utils.split_at_indices(bytes, [2, 3]) {
		[hour_bytes, _, minute_bytes] => hm_to_nanos(Utils.utf8_to_int_signed(hour_bytes), Utils.utf8_to_int_signed(minute_bytes))
		_ => Err(InvalidTimeFormat)
	}
}

parse_local_time_basic : List(U8) -> Try(I64, [InvalidTimeFormat])
parse_local_time_basic = |bytes| {
	match Utils.split_at_indices(bytes, [2, 4]) {
		[hour_bytes, minute_bytes, second_bytes] => hms_to_nanos(Utils.utf8_to_int_signed(hour_bytes), Utils.utf8_to_int_signed(minute_bytes), Utils.utf8_to_int_signed(second_bytes))
		_ => Err(InvalidTimeFormat)
	}
}

parse_local_time_extended : List(U8) -> Try(I64, [InvalidTimeFormat])
parse_local_time_extended = |bytes| {
	match Utils.split_at_indices(bytes, [2, 3, 5, 6]) {
		[hour_bytes, _, minute_bytes, _, second_bytes] => hms_to_nanos(Utils.utf8_to_int_signed(hour_bytes), Utils.utf8_to_int_signed(minute_bytes), Utils.utf8_to_int_signed(second_bytes))
		_ => Err(InvalidTimeFormat)
	}
}

hm_to_nanos : Try(I64, _), Try(I64, _) -> Try(I64, [InvalidTimeFormat])
hm_to_nanos = |hour_res, minute_res| {
	match (hour_res, minute_res) {
		(Ok(h), Ok(m)) if h >= 0 and h <= 23 and m >= 0 and m <= 59 => Ok(h * Const.nanos_per_hour + m * Const.nanos_per_minute)
		(Ok(24), Ok(0)) => Ok(Const.nanos_per_day)
		_ => Err(InvalidTimeFormat)
	}
}

hms_to_nanos : Try(I64, _), Try(I64, _), Try(I64, _) -> Try(I64, [InvalidTimeFormat])
hms_to_nanos = |hour_res, minute_res, second_res| {
	match (hour_res, minute_res, second_res) {
		(Ok(h), Ok(m), Ok(s)) if h >= 0 and h <= 23 and m >= 0 and m <= 59 and s >= 0 and s <= 59 => Ok(h * Const.nanos_per_hour + m * Const.nanos_per_minute + s * Const.nanos_per_second)
		(Ok(24), Ok(0), Ok(0)) => Ok(Const.nanos_per_day)
		_ => Err(InvalidTimeFormat)
	}
}

strip_t_and_z : List(U8) -> List(U8)
strip_t_and_z = |bytes| {
	match bytes {
		['T', .. as tail] => strip_t_and_z(tail)
		[.. as head, 'Z'] => head
		_ => bytes
	}
}

# <===== TESTS ====>
# <---- hour / minute / second / nanosecond ---->
expect {
	t = Time.from_hmsn(23, 59, 58, 999_999_999)?
	t.hour() == 23 and t.minute() == 59 and t.second() == 58 and t.nanosecond() == 999_999_999
}
expect Time.midnight.hour() == 0 and Time.midnight.minute() == 0 and Time.midnight.second() == 0 and Time.midnight.nanosecond() == 0

# <---- add_nanoseconds ---->
expect Time.from_hmsn(12, 34, 56, 5)?.add_nanoseconds(Const.nanos_per_second) == Time.from_hmsn(12, 34, 57, 5)?
expect Time.from_hmsn(12, 34, 56, 5)?.add_nanoseconds(-Const.nanos_per_second) == Time.from_hmsn(12, 34, 55, 5)?

# <---- add_seconds ---->
expect Time.from_hms(12, 34, 56)?.add_seconds(59) == Time.from_hms(12, 35, 55)?
expect Time.from_hms(12, 34, 56)?.add_seconds(-59) == Time.from_hms(12, 33, 57)?

# <---- add_minutes ---->
expect Time.from_hms(12, 34, 56)?.add_minutes(59) == Time.from_hms(13, 33, 56)?
expect Time.from_hms(12, 34, 56)?.add_minutes(-59) == Time.from_hms(11, 35, 56)?

# <---- add_hours ---->
expect Time.from_hms(12, 34, 56)?.add_hours(1) == Time.from_hms(13, 34, 56)?
expect Time.from_hms(12, 34, 56)?.add_hours(-1) == Time.from_hms(11, 34, 56)?
expect Time.from_hms(12, 34, 56)?.add_hours(12) == Time.from_hms(0, 34, 56)?
expect Time.from_hms(12, 34, 56)?.add_hours(-13) == Time.from_hms(23, 34, 56)?

# <---- add_duration ---->
expect {
	duration = Duration.from_hours(1)
	res = Time.add_duration(Time.from_hms(0, 0, 0)?, duration)
	res == Time.from_hms(1, 0, 0)?
}

# <---- from_hms / from_hmsn validation ---->
expect Time.from_hms(23, 59, 59)?.hour() == 23
expect Time.from_hmsn(23, 59, 59, 999_999_999) == Ok(Time.highest)
expect Time.from_hms(24, 0, 0) == Err(InvalidHour)
expect Time.from_hms(0, 60, 0) == Err(InvalidMinute)
expect Time.from_hms(0, 0, 60) == Err(InvalidSecond)
expect Time.from_hmsn(24, 0, 0, 0) == Err(InvalidHour)
expect Time.from_hmsn(0, 60, 0, 0) == Err(InvalidMinute)
expect Time.from_hmsn(0, 0, 60, 0) == Err(InvalidSecond)
expect Time.from_hmsn(0, 0, 0, 1_000_000_000) == Err(InvalidNanosecond)
# The first invalid field, in order, is the one reported.
expect Time.from_hmsn(24, 60, 60, 1_000_000_000) == Err(InvalidHour)
expect Time.from_hmsn(0, 60, 60, 1_000_000_000) == Err(InvalidMinute)

# <---- from_nanos_since_midnight ---->
expect Time.from_nanos_since_midnight(0) == Ok(Time.midnight)
expect Time.from_nanos_since_midnight(Const.nanos_per_day - 1) == Ok(Time.highest)
expect Time.from_nanos_since_midnight(12 * Const.nanos_per_hour + 34 * Const.nanos_per_minute + 56 * Const.nanos_per_second + 5) == Ok(Time.from_hmsn(12, 34, 56, 5)?)
expect Time.from_nanos_since_midnight(-1) == Err(NanosecondsOutOfRange)
expect Time.from_nanos_since_midnight(Const.nanos_per_day) == Err(NanosecondsOutOfRange)
expect Time.from_nanos_since_midnight(I64.highest) == Err(NanosecondsOutOfRange)
expect Time.from_nanos_since_midnight(I64.lowest) == Err(NanosecondsOutOfRange)
# Wrapping a count around midnight is done by adding it to midnight.
expect Time.midnight.add_nanoseconds(Const.nanos_per_day) == Time.midnight
expect Time.midnight.add_nanoseconds(-1) == Time.highest

# <---- normalize ---->
# Every Time is already a valid time of day, so normalize is the identity.
expect Time.normalize(Time.from_hms(23, 0, 0)?) == Time.from_hms(23, 0, 0)?
expect Time.normalize(Time.midnight) == Time.midnight

# <---- from_iso_str normalizes / with_day_offset ---->
expect Time.from_iso_str("23:00:00-05:00") == Ok(Time.from_hms(4, 0, 0)?)
expect Time.from_iso_str("01:00:00+03:00") == Ok(Time.from_hms(22, 0, 0)?)
expect Time.from_iso_str("12:00:00+01") == Ok(Time.from_hms(11, 0, 0)?)
expect Time.from_iso_str_with_day_offset("23:00:00-05:00") == Ok({ time: Time.from_hms(4, 0, 0)?, day_offset: 1 })
expect Time.from_iso_str_with_day_offset("01:00:00+03:00") == Ok({ time: Time.from_hms(22, 0, 0)?, day_offset: -1 })
expect Time.from_iso_str_with_day_offset("12:00:00+01") == Ok({ time: Time.from_hms(11, 0, 0)?, day_offset: 0 })
expect Time.from_iso_str_with_day_offset("24:00:00") == Ok({ time: Time.midnight, day_offset: 1 })
expect Time.from_iso_str_with_day_offset("23:59:59,5-00:30") == Ok({ time: Time.from_hmsn(0, 29, 59, 500_000_000)?, day_offset: 1 })
expect Time.from_iso_u8_with_day_offset("00:00:00+14:00".to_utf8()) == Ok({ time: Time.from_hms(10, 0, 0)?, day_offset: -1 })
expect Time.from_iso_str_with_day_offset("not a time") == Err(InvalidTimeFormat)
# Any offset of less than 24 hours in either direction is accepted, and large ones can cross a day.
expect Time.from_iso_str_with_day_offset("12:00:00-23:00") == Ok({ time: Time.from_hms(11, 0, 0)?, day_offset: 1 })
expect Time.from_iso_str_with_day_offset("12:00:00+23:00") == Ok({ time: Time.from_hms(13, 0, 0)?, day_offset: -1 })
expect Time.from_iso_str_with_day_offset("00:00:00-23:59") == Ok({ time: Time.from_hms(23, 59, 0)?, day_offset: 0 })
expect Time.from_iso_str_with_day_offset("00:00:00+23:59") == Ok({ time: Time.from_hms(0, 1, 0)?, day_offset: -1 })
expect Time.from_iso_str("12:00:00+24:00") == Err(InvalidTimeFormat)
expect Time.from_iso_str("12:00:00-24:00") == Err(InvalidTimeFormat)
expect Time.from_iso_str("12:00:00+00:60") == Err(InvalidTimeFormat)
expect Time.from_iso_str("12:00:00+-500") == Err(InvalidTimeFormat)
# ISO 8601 allows hour 24 only as exactly 24:00:00, with a zero fraction.
expect Time.from_iso_str("24:00:00,000") == Ok(Time.midnight)
expect Time.from_iso_str("24:00:00,5") == Err(InvalidTimeFormat)
expect Time.from_iso_str("24.5") == Err(InvalidTimeFormat)
expect Time.from_iso_str("24:00.5") == Err(InvalidTimeFormat)
expect Time.from_iso_str("24:30:00") == Err(InvalidTimeFormat)
expect Time.from_iso_str("24:00:01") == Err(InvalidTimeFormat)
expect Time.from_iso_str("25:00:00") == Err(InvalidTimeFormat)
# The end-of-day notation combines with an offset like any other time, in every format.
expect Time.from_iso_str_with_day_offset("24:00:00-01:00") == Ok({ time: Time.from_hms(1, 0, 0)?, day_offset: 1 })
expect Time.from_iso_str_with_day_offset("24:00:00+01:00") == Ok({ time: Time.from_hms(23, 0, 0)?, day_offset: 0 })
expect Time.from_iso_str_with_day_offset("24:00:00+14:00") == Ok({ time: Time.from_hms(10, 0, 0)?, day_offset: 0 })
expect Time.from_iso_str_with_day_offset("T24Z") == Ok({ time: Time.midnight, day_offset: 1 })
expect Time.from_iso_str_with_day_offset("240000Z") == Ok({ time: Time.midnight, day_offset: 1 })
expect Time.from_iso_str_with_day_offset("T24:00:00Z") == Ok({ time: Time.midnight, day_offset: 1 })
# A fraction is rounded to the nearest nanosecond, and rounding can carry all the way into the next day.
expect Time.from_iso_str("00:00:00,0000000001") == Ok(Time.midnight)
expect Time.from_iso_str("00:00:00,0000000009") == Ok(Time.from_hmsn(0, 0, 0, 1)?)
expect Time.from_iso_str("23:59:59,999999999") == Ok(Time.highest)
expect Time.from_iso_str_with_day_offset("23:59:59,9999999994") == Ok({ time: Time.highest, day_offset: 0 })
expect Time.from_iso_str_with_day_offset("23:59:59,9999999999") == Ok({ time: Time.midnight, day_offset: 1 })
# Every parsed time, with or without an offset, has an hour from 0 to 23.
expect ["23:00:00-05:00", "01:00:00+03:00", "T24", "0000+1400", "T24-1200", "12:00:00Z"].map(|str| Time.from_iso_str(str).map_ok(|time| time.hour() >= 0 and time.hour() < 24)) == [Ok(Bool.True), Ok(Bool.True), Ok(Bool.True), Ok(Bool.True), Ok(Bool.True), Ok(Bool.True)]

# <---- add_duration_with_day_offset ---->
expect Time.from_hms(23, 0, 0)?.add_duration_with_day_offset(Duration.from_hours(2)) == { time: Time.from_hms(1, 0, 0)?, day_offset: 1 }
expect Time.from_hms(1, 0, 0)?.add_duration_with_day_offset(Duration.from_hours(-2)) == { time: Time.from_hms(23, 0, 0)?, day_offset: -1 }
expect Time.from_hms(9, 30, 0)?.add_duration_with_day_offset(Duration.from_minutes(15)) == { time: Time.from_hms(9, 45, 0)?, day_offset: 0 }
expect Time.midnight.add_duration_with_day_offset(Duration.from_days(3)) == { time: Time.midnight, day_offset: 3 }
expect Time.midnight.add_duration_with_day_offset(Duration.from_nanoseconds(-1)) == { time: Time.highest, day_offset: -1 }
expect Time.from_hms(12, 0, 0)?.add_duration_with_day_offset(Duration.from_hours(-36)) == { time: Time.midnight, day_offset: -1 }
expect Time.from_hms(11, 0, 0)?.add_duration_with_day_offset(Duration.from_hours(-36)) == { time: Time.from_hms(23, 0, 0)?, day_offset: -2 }
expect Time.midnight.add_duration_with_day_offset(Duration.from_days(I64.highest.to_i128())).day_offset == I64.highest
expect Time.midnight.add_duration_with_day_offset(Duration.from_days(I64.lowest.to_i128())).day_offset == I64.lowest

# <---- to_iso_str ---->
expect Time.to_iso_str(Time.from_hmsn(12, 34, 56, 5)?) == "12:34:56,000000005"
expect Time.to_iso_str(Time.midnight) == "00:00:00"
expect Time.to_iso_str(Time.highest) == "23:59:59,999999999"
expect Time.from_iso_str(Time.to_iso_str(Time.highest)) == Ok(Time.highest)
expect {
	str = Time.to_iso_str(Time.from_hmsn(0, 0, 0, 500_000_000)?)
	str == "00:00:00,5"
}

# <---- sub ---->
expect Time.sub(Time.from_hms(12, 34, 56)?, Time.from_hms(12, 34, 55)?) == Duration.from_seconds(1.I128)
expect Time.sub(Time.from_hmsn(23, 0, 0, 1)?, Time.from_hmsn(1, 1, 1, 2)?) == Duration.from_nanoseconds(21 * Const.nanos_per_hour.to_i128() + 58 * Const.nanos_per_minute.to_i128() + 59 * Const.nanos_per_second.to_i128() - 1)
# The result is negative when the first time is earlier.
expect Time.sub(Time.from_hms(0, 34, 56)?, Time.from_hms(12, 34, 55)?) == Duration.from_nanoseconds((-12) * Const.nanos_per_hour.to_i128() + Const.nanos_per_second.to_i128())
expect Time.sub(Time.midnight, Time.highest) == Duration.from_nanoseconds(-(Const.nanos_per_day.to_i128() - 1))

# <---- to_nanos_since_midnight ---->
expect Time.to_nanos_since_midnight({ hour: 12, minute: 34, second: 56, nanosecond: 5 }) == 12 * Const.nanos_per_hour + 34 * Const.nanos_per_minute + 56 * Const.nanos_per_second + 5
expect Time.to_nanos_since_midnight(Time.from_hmsn(12, 34, 56, 5)?) == 12 * Const.nanos_per_hour + 34 * Const.nanos_per_minute + 56 * Const.nanos_per_second + 5

# <---- before ---->
expect {
	a = Time.from_nanos_since_midnight(0)?
	b = Time.from_nanos_since_midnight(0)?
	!(b.before(a))
}
expect {
	a = Time.from_nanos_since_midnight(0)?
	b = Time.from_nanos_since_midnight(1)?
	!(b.before(a))
}
expect {
	a = Time.from_nanos_since_midnight(1)?
	b = Time.from_nanos_since_midnight(0)?
	b.before(a)
}

# <---- after ---->
expect {
	a = Time.from_nanos_since_midnight(0)?
	b = Time.from_nanos_since_midnight(0)?
	!(b.after(a))
}
expect {
	a = Time.from_nanos_since_midnight(0)?
	b = Time.from_nanos_since_midnight(1)?
	b.after(a)
}
expect {
	a = Time.from_nanos_since_midnight(1)?
	b = Time.from_nanos_since_midnight(0)?
	!(b.after(a))
}

# <---- to_inspect ---->
expect Str.inspect(Time.from_hms(9, 30, 0)) == "09:30:00"
expect Str.inspect(Time.from_hmsn(9, 30, 0, 500_000_000)) == "09:30:00,5"
expect Str.inspect(Time.midnight) == "00:00:00"
expect Str.inspect([Time.from_hms(1, 2, 3)]) == "[01:02:03]"

# <---- min / max ---->
expect Time.from_hms(9, 30, 0).min(Time.from_hms(13, 0, 0)) == Time.from_hms(9, 30, 0)
expect Time.from_hms(9, 30, 0).max(Time.from_hms(13, 0, 0)) == Time.from_hms(13, 0, 0)
expect [Time.from_hms(9, 30, 0), Time.from_hms(13, 0, 0), Time.from_hms(0, 0, 1)].min() == Ok(Time.from_hms(0, 0, 1))
expect [Time.from_hms(9, 30, 0), Time.from_hms(13, 0, 0), Time.from_hms(0, 0, 1)].max() == Ok(Time.from_hms(13, 0, 0))
expect [Time.from_hms(9, 30, 0), Time.from_hms(13, 0, 0), Time.from_hms(0, 0, 1)].sort() == [Time.from_hms(0, 0, 1), Time.from_hms(9, 30, 0), Time.from_hms(13, 0, 0)]

# <---- from_quote ---->
expect {
	t : Time
	t = "09:30:00"
	t == Time.from_hms(9, 30, 0)
}
expect {
	t : Time
	t = "09:30:00,5"
	t == Time.from_hmsn(9, 30, 0, 500_000_000)
}
expect Time.from_quote("not a time").is_err()

# <---- to_hash ---->
expect {
	d = Dict.empty().insert(Time.from_hms(9, 30, 0), "standup")
	d.get(Time.from_iso_str("09:30:00")?) == Ok("standup")
}
expect Set.from_list([Time.from_hms(9, 30, 0), Time.from_hmsn(9, 30, 0, 0), Time.from_nanos_since_midnight(34_200_000_000_000)]).len() == 1
expect Set.from_list([Time.from_hms(9, 30, 0), Time.from_hms(9, 30, 1)]).len() == 2

# <---- is_eq (==) ---->
expect {
	a = Time.from_nanos_since_midnight(0)?
	b = Time.from_nanos_since_midnight(0)?
	b == a
}
expect {
	a = Time.from_nanos_since_midnight(0)?
	b = Time.from_nanos_since_midnight(1)?
	b != a
}
expect {
	a = Time.from_nanos_since_midnight(1)?
	b = Time.from_nanos_since_midnight(0)?
	b != a
}

# <---- format ---->
expect {
	res = Time.format(Time.from_hmsn(12, 34, 56, 5)?, "{h}:{m}:{s}.{f}")
	res == "12:34:56.000000005"
}

expect {
	res = Time.format(Time.from_hmsn(12, 34, 56, 123456789)?, "{h}:{m}:{s}.{f:3}")
	res == "12:34:56.123"
}

expect {
	res = Time.format(Time.from_hmsn(12, 34, 56, 123456789)?, "0.{f:}s")
	res == "0.123456789s"
}

expect {
	time = Time.from_hmsn(1, 2, 3, 4)?
	res = Time.format(time, "{hh}:{mm}:{ss} + {n}ns")
	res == "01:02:03 + 4ns"
}

# <---- lowest / highest / wrapping ---->
expect Time.to_nanos_since_midnight(Time.highest) == Const.nanos_per_day - 1
expect Time.lowest == Time.midnight
expect Time.midnight.add_hours(24) == Time.midnight
expect Time.midnight.add_hours(25) == Time.from_hms(1, 0, 0)?
expect Time.midnight.add_hours(-1) == Time.from_hms(23, 0, 0)?
expect Time.midnight.add_hours(-25) == Time.from_hms(23, 0, 0)?
expect Time.from_hms(23, 0, 0)?.add(Duration.from_hours(2)) == Time.from_hms(1, 0, 0)?
expect Time.highest.add_nanoseconds(1) == Time.midnight
expect Time.midnight.add_nanoseconds(-1) == Time.highest
expect Time.midnight.add_minutes(Const.minutes_per_day.to_i64()) == Time.midnight
expect Time.midnight.add_seconds(Const.seconds_per_day.to_i64() + 1) == Time.from_hms(0, 0, 1)?
expect Time.midnight.add(Duration.from_days(200_000)) == Time.midnight
expect Time.from_hms(6, 0, 0)?.add(Duration.from_days(-200_000)) == Time.from_hms(6, 0, 0)?
# Extreme inputs wrap without overflowing. I64.highest hours is 7 modulo 24, and I64.lowest hours is 16 modulo 24.
expect Time.midnight.add_hours(I64.highest) == Time.from_hms(7, 0, 0)?
expect Time.midnight.add_hours(I64.lowest) == Time.from_hms(16, 0, 0)?
expect Time.midnight.add_nanoseconds(I64.highest).add_nanoseconds(-I64.highest) == Time.midnight
expect Time.midnight.add(Duration.from_days(I64.highest.to_i128())) == Time.midnight
expect Time.midnight.add(Duration.from_days(I64.lowest.to_i128())) == Time.midnight
# to_iso_str can only ever produce a valid ISO 8601 time of day.
expect Time.from_hms(23, 0, 0)?.add_hours(2).to_iso_str() == "01:00:00"

# <---- comparison operators and sorting ---->
expect Time.from_hms(1, 0, 0)? < Time.from_hms(2, 0, 0)?
expect Time.from_hms(2, 0, 0)? > Time.from_hms(1, 0, 0)?
expect Time.from_hms(1, 0, 0)? <= Time.from_hms(1, 0, 0)?
expect Time.from_hms(1, 0, 0)? >= Time.from_hms(1, 0, 0)?
expect Time.from_hmsn(1, 0, 0, 1)? > Time.from_hms(1, 0, 0)?
expect !(Time.from_hms(2, 0, 0)? < Time.from_hms(1, 0, 0)?)
expect Time.lowest == Time.midnight and Time.midnight < Time.highest
expect [Time.from_hms(5, 0, 0)?, Time.from_hms(1, 0, 0)?, Time.from_hmsn(1, 0, 0, 1)?].sort() == [Time.from_hms(1, 0, 0)?, Time.from_hmsn(1, 0, 0, 1)?, Time.from_hms(5, 0, 0)?]
