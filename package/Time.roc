## The Time module provides the `Time` type as well as functions for working with time values.
##
## These functions include functions for creating `Time` objects from various numeric values, converting `Time`s to and from ISO 8601 strings, and performing arithmetic operations on `Time`s.
import Const
import Duration
import Utils

## Object representing a time of day. Hours may be less than 0 or greater than 24.
## ```
## Time : {
##     hour : I8,
##     minute : U8,
##     second : U8,
##     nanosecond : U32
## }
## ```
Time :: { hour : I8, minute : U8, second : U8, nanosecond : U32 }.{

	## Are two Times equal?
	is_eq : _

	## Get the hour of the `Time` object.
	get_hour : Time -> I8
	get_hour = |time| time.hour

	## Get the minute of the `Time` object.
	get_minute : Time -> U8
	get_minute = |time| time.minute

	## Get the second of the `Time` object.
	get_second : Time -> U8
	get_second = |time| time.second

	## Get the nanosecond of the `Time` object.
	get_nanosecond : Time -> U32
	get_nanosecond = |time| time.nanosecond

	## Same as [`add_duration`](Time#add_duration)
	add : Time, Duration -> Time
	add = add_duration

	## Add a `Duration` object to a `Time` object. (May be deprecated in favor of [`add`](Time#add) in the future.)
	add_duration : Time, Duration -> Time
	add_duration = |time, duration| {
		duration_nanos = duration.to_nanoseconds()
		time_nanos = to_nanos_since_midnight(time).to_i128()
		from_nanos_since_midnight((duration_nanos + time_nanos).to_i64_wrap())
	}

	## Add hours to a `Time` object.
	add_hours : Time, I64 -> Time
	add_hours = |time, hours| add_nanoseconds(time, hours * Const.nanos_per_hour)

	## Add minutes to a `Time` object.
	add_minutes : Time, I64 -> Time
	add_minutes = |time, minutes| add_nanoseconds(time, minutes * Const.nanos_per_minute)

	## Add nanoseconds to a `Time` object.
	add_nanoseconds : Time, I64 -> Time
	add_nanoseconds = |time, nanos| {
		from_nanos_since_midnight(to_nanos_since_midnight(time) + nanos)
	}

	## Add seconds to a `Time` object.
	add_seconds : Time, I64 -> Time
	add_seconds = |time, seconds| add_nanoseconds(time, seconds * Const.nanos_per_second)

	## Determine if the first `Time` occurs after the second `Time`.
	after : Time, Time -> Bool
	after = |a, b| a.order_relative_to(b) == After

	## Determine if the first `Time` occurs before the second `Time`.
	before : Time, Time -> Bool
	before = |a, b| a.order_relative_to(b) == Before

	## Compare two `Time` objects.
	## If the first occurs before the second, it returns Before.
	## If the first and the second are equal, it returns Same.
	## If the first occurs after the second, it returns After.
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

	## Determine if the first `Time` is equal to the second `Time`.
	equal : Time, Time -> Bool
	equal = |a, b| a.order_relative_to(b) == Same

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

	## Create a `Time` object from the hour, minute, and second.
	from_hms : I64, I64, I64 -> Time
	from_hms = |hour, minute, second| { hour: hour.to_i8_wrap(), minute: minute.to_u8_wrap(), second: second.to_u8_wrap(), nanosecond: 0.U32 }

	## Create a `Time` object from the hour, minute, second, and nanosecond.
	from_hmsn : I64, I64, I64, I64 -> Time
	from_hmsn = |hour, minute, second, nanosecond| { hour: hour.to_i8_wrap(), minute: minute.to_u8_wrap(), second: second.to_u8_wrap(), nanosecond: nanosecond.to_u32_wrap() }

	## Convert an ISO 8601 string to a `Time` object.
	from_iso_str : Str -> Try(Time, [InvalidTimeFormat])
	from_iso_str = |str| str.to_utf8() |> from_iso_u8

	## Convert an ISO 8601 list of UTF-8 bytes to a `Time` object.
	from_iso_u8 : List(U8) -> Try(Time, [InvalidTimeFormat])
	from_iso_u8 = |bytes| {
		if Utils.validate_utf8_single_bytes(bytes) {
			stripped_bytes = strip_t_and_z(bytes)
			match (Utils.split_with_delims(stripped_bytes, |b| ['.', ',', '+', '-'].contains(b)), bytes.last()) {
				# time.fractionaltime+timeoffset / time,fractionaltime-timeoffset
				([time_bytes, [byte1], fractional_bytes, [byte2], offset_bytes], Ok(last_byte)) if last_byte != 'Z' => {
					time_res = parse_fractional_time(time_bytes, [[byte1], fractional_bytes] |> join)
					offset_res = parse_time_offset([[byte2], offset_bytes] |> join)
					combine_time_and_offset_results(time_res, offset_res)
				}

				# time+timeoffset / time-timeoffset
				([time_bytes, [byte1], offset_bytes], Ok(last_byte)) if (byte1 == '+' or byte1 == '-') and last_byte != 'Z' => {
					time_res = parse_whole_time(time_bytes)
					offset_res = parse_time_offset([[byte1], offset_bytes] |> join)
					combine_time_and_offset_results(time_res, offset_res)
				}

				# time.fractionaltime / time,fractionaltime
				([time_bytes, [byte1], fractional_bytes], _) if byte1 == ',' or byte1 == '.' => {
					parse_fractional_time(time_bytes, [[byte1], fractional_bytes] |> join)
				}

				# time
				([time_bytes], _) => parse_whole_time(time_bytes)
				_ => Err(InvalidTimeFormat)
			}
		} else {
			Err(InvalidTimeFormat)
		}
	}

	## Convert nanoseconds since midnight to a `Time` object.
	from_nanos_since_midnight : I64 -> Time
	from_nanos_since_midnight = |nanos| {
		nanos1 = ((nanos % Const.nanos_per_day + Const.nanos_per_day) % Const.nanos_per_day).to_u64_wrap()
		nanos2 = nanos1.to_i64_wrap() % Const.nanos_per_hour
		minute = (nanos2 // Const.nanos_per_minute).to_u8_wrap()
		nanos3 = nanos2 % Const.nanos_per_minute
		second = (nanos3 // Const.nanos_per_second).to_u8_wrap()
		nanosecond = (nanos3 % Const.nanos_per_second).to_u32_wrap()
		casted_val = (minute.to_i64() * Const.nanos_per_minute + second.to_i64() * Const.nanos_per_second + nanosecond.to_i64())
		hour = ((nanos - casted_val) // Const.nanos_per_hour).to_i8_wrap()
		{ hour, minute, second, nanosecond }
	}

	## `Time` object representing 00:00:00.
	midnight : Time
	midnight = { hour: 0, minute: 0, second: 0, nanosecond: 0 }

	## Normalize a `Time` object to ensure that the hour is between 0 and 23.
	normalize : Time -> Time
	normalize = |time| {
		h_normalized = ((time.hour.to_i64() % Const.hours_per_day.to_i64() + Const.hours_per_day.to_i64()) % Const.hours_per_day.to_i64()).to_i8_wrap()
		from_hmsn(h_normalized.to_i64(), time.minute.to_i64(), time.second.to_i64(), time.nanosecond.to_i64())
	}

	## Subtract two `Time` objects to get the `Duration` between them.
	sub : Time, Time -> Duration
	sub = |a, b| {
		a_nanos = to_nanos_since_midnight(a)
		b_nanos = to_nanos_since_midnight(b)
		Duration.from_nanoseconds((a_nanos - b_nanos).to_i128())
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

combine_time_and_offset_results = |time_res, offset_res| {
	match (time_res, offset_res) {
		(Ok(time), Ok(offset)) => {
			Time.add_duration(time, offset) |> Ok
		}
		_ => Err(InvalidTimeFormat)
	}
}

parse_whole_time : List(U8) -> Try(Time, [InvalidTimeFormat])
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

parse_fractional_time : List(U8), List(U8) -> Try(Time, [InvalidTimeFormat])
parse_fractional_time = |whole_bytes, fractional_bytes| {
	add_duration_and_time = |d, t| Time.add_duration(t, d)
	match (whole_bytes, Utils.utf8_to_frac(fractional_bytes)) {
		([_, _], Ok(frac)) => { # hh
			time = parse_local_time_hour(whole_bytes)?
			ns = (frac * Const.nanos_per_hour.to_f64()) |> round
			Duration.from_nanoseconds(ns.to_i128()) |> add_duration_and_time(time) |> Ok
		}

		([_, _, _, _], Ok(frac)) => { # hhmm
			time = parse_local_time_minute_basic(whole_bytes)?
			ns = (frac * Const.nanos_per_minute.to_f64()) |> round
			Duration.from_nanoseconds(ns.to_i128()) |> add_duration_and_time(time) |> Ok
		}

		([_, _, ':', _, _], Ok(frac)) => { # hh:mm
			time = parse_local_time_minute_extended(whole_bytes)?
			ns = (frac * Const.nanos_per_minute.to_f64()) |> round
			Duration.from_nanoseconds(ns.to_i128()) |> add_duration_and_time(time) |> Ok
		}

		([_, _, _, _, _, _], Ok(frac)) => { # hhmmss
			time = parse_local_time_basic(whole_bytes)?
			ns = (frac * Const.nanos_per_second.to_f64()) |> round
			Duration.from_nanoseconds(ns.to_i128()) |> add_duration_and_time(time) |> Ok
		}

		([_, _, ':', _, _, ':', _, _], Ok(frac)) => { # hh:mm:ss
			time = parse_local_time_extended(whole_bytes)?
			ns = (frac * Const.nanos_per_second.to_f64()) |> round
			Duration.from_nanoseconds(ns.to_i128()) |> add_duration_and_time(time) |> Ok
		}

		_ => Err(InvalidTimeFormat)
	}
}

parse_time_offset : List(U8) -> Try(Duration, [InvalidTimeFormat])
parse_time_offset = |bytes| {
	match bytes {
		['-', h1, h2] => {
			parse_time_offset_help(h1, h2, '0', '0', 1)
		}

		['+', h1, h2] => {
			parse_time_offset_help(h1, h2, '0', '0', -1)
		}

		['-', h1, h2, m1, m2] => {
			parse_time_offset_help(h1, h2, m1, m2, 1)
		}

		['+', h1, h2, m1, m2] => {
			parse_time_offset_help(h1, h2, m1, m2, -1)
		}

		['-', h1, h2, ':', m1, m2] => {
			parse_time_offset_help(h1, h2, m1, m2, 1)
		}

		['+', h1, h2, ':', m1, m2] => {
			parse_time_offset_help(h1, h2, m1, m2, -1)
		}

		_ => Err(InvalidTimeFormat)
	}
}

parse_time_offset_help : U8, U8, U8, U8, I64 -> Try(Duration, [InvalidTimeFormat])
parse_time_offset_help = |h1, h2, m1, m2, sign| {
	is_valid_offset = |offset| {
		if offset >= -14 * Const.nanos_per_hour.to_i64() and offset <= 12 * Const.nanos_per_hour.to_i64() {
			Valid
		} else {
			Invalid
		}
	}
	match (Utils.utf8_to_int_signed([h1, h2]), Utils.utf8_to_int_signed([m1, m2])) {
		(Ok(hour), Ok(minute)) => {
			offset_nanos = sign * (hour * Const.nanos_per_hour.to_i64() + minute * Const.nanos_per_minute.to_i64())
			match is_valid_offset(offset_nanos) {
				Valid => Duration.from_nanoseconds(offset_nanos.to_i128()) |> Ok
				Invalid => Err(InvalidTimeFormat)
			}
		}

		_ => Err(InvalidTimeFormat)
	}
}

parse_local_time_hour : List(U8) -> Try(Time, [InvalidTimeFormat])
parse_local_time_hour = |bytes| {
	match Utils.utf8_to_int_signed(bytes) {
		Ok(hour) if hour >= 0 and hour <= 24 => {
			Time.from_hms(hour, 0, 0) |> Ok
		}

		_ => Err(InvalidTimeFormat)
	}
}

parse_local_time_minute_basic : List(U8) -> Try(Time, [InvalidTimeFormat])
parse_local_time_minute_basic = |bytes| {
	match Utils.split_at_indices(bytes, [2]) {
		[hour_bytes, minute_bytes] => {
			match (Utils.utf8_to_int_signed(hour_bytes), Utils.utf8_to_int_signed(minute_bytes)) {
				(Ok(hour), Ok(minute)) if hour >= 0 and hour <= 23 and minute >= 0 and minute <= 59 => {
					Time.from_hms(hour, minute, 0) |> Ok
				}

				(Ok(24), Ok(0)) => {
					Time.from_hms(24, 0, 0) |> Ok
				}

				_ => Err(InvalidTimeFormat)
			}
		}

		_ => Err(InvalidTimeFormat)
	}
}

parse_local_time_minute_extended : List(U8) -> Try(Time, [InvalidTimeFormat])
parse_local_time_minute_extended = |bytes| {
	match Utils.split_at_indices(bytes, [2, 3]) {
		[hour_bytes, _, minute_bytes] => {
			match (Utils.utf8_to_int_signed(hour_bytes), Utils.utf8_to_int_signed(minute_bytes)) {
				(Ok(hour), Ok(minute)) if hour >= 0 and hour <= 23 and minute >= 0 and minute <= 59 => {
					Time.from_hms(hour, minute, 0) |> Ok
				}

				(Ok(24), Ok(0)) => {
					Time.from_hms(24, 0, 0) |> Ok
				}

				_ => Err(InvalidTimeFormat)
			}
		}

		_ => Err(InvalidTimeFormat)
	}
}

parse_local_time_basic : List(U8) -> Try(Time, [InvalidTimeFormat])
parse_local_time_basic = |bytes| {
	match Utils.split_at_indices(bytes, [2, 4]) {
		[hour_bytes, minute_bytes, second_bytes] => {
			match (Utils.utf8_to_int_signed(hour_bytes), Utils.utf8_to_int_signed(minute_bytes), Utils.utf8_to_int_signed(second_bytes)) {
				(Ok(h), Ok(m), Ok(s)) if h >= 0 and h <= 23 and m >= 0 and m <= 59 and s >= 0 and s <= 59 => {
					Time.from_hms(h, m, s) |> Ok
				}

				(Ok(24), Ok(0), Ok(0)) => {
					Time.from_hms(24, 0, 0) |> Ok
				}

				_ => Err(InvalidTimeFormat)
			}
		}

		_ => Err(InvalidTimeFormat)
	}
}

parse_local_time_extended : List(U8) -> Try(Time, [InvalidTimeFormat])
parse_local_time_extended = |bytes| {
	match Utils.split_at_indices(bytes, [2, 3, 5, 6]) {
		[hour_bytes, _, minute_bytes, _, second_bytes] => {
			match (Utils.utf8_to_int_signed(hour_bytes), Utils.utf8_to_int_signed(minute_bytes), Utils.utf8_to_int_signed(second_bytes)) {
				(Ok(h), Ok(m), Ok(s)) if h >= 0 and h <= 23 and m >= 0 and m <= 59 and s >= 0 and s <= 59 => {
					Time.from_hms(h, m, s) |> Ok
				}

				(Ok(24), Ok(0), Ok(0)) => {
					Time.from_hms(24, 0, 0) |> Ok
				}

				_ => Err(InvalidTimeFormat)
			}
		}

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

join = |list_of_lists| {
	list_of_lists.fold([], |acc, sublist| acc.concat(sublist))
}

round = |x| {
	if x >= 0.0 {
		(x + 0.5).to_i64_wrap()
	} else {
		(x - 0.5).to_i64_wrap()
	}
}

# <===== TESTS ====>
# <---- add_nanoseconds ---->
expect Time.from_hmsn(12, 34, 56, 5).add_nanoseconds(Const.nanos_per_second) == Time.from_hmsn(12, 34, 57, 5)
expect Time.from_hmsn(12, 34, 56, 5).add_nanoseconds(-Const.nanos_per_second) == Time.from_hmsn(12, 34, 55, 5)

# <---- add_seconds ---->
expect Time.from_hms(12, 34, 56).add_seconds(59) == Time.from_hms(12, 35, 55)
expect Time.from_hms(12, 34, 56).add_seconds(-59) == Time.from_hms(12, 33, 57)

# <---- add_minutes ---->
expect Time.from_hms(12, 34, 56).add_minutes(59) == Time.from_hms(13, 33, 56)
expect Time.from_hms(12, 34, 56).add_minutes(-59) == Time.from_hms(11, 35, 56)

# <---- add_hours ---->
expect Time.from_hms(12, 34, 56).add_hours(1) == Time.from_hms(13, 34, 56)
expect Time.from_hms(12, 34, 56).add_hours(-1) == Time.from_hms(11, 34, 56)
expect Time.from_hms(12, 34, 56).add_hours(12) == Time.from_hms(24, 34, 56)

# <---- add_duration ---->
expect {
	duration = Duration.from_hours(1)
	res = Time.add_duration(Time.from_hms(0, 0, 0), duration)
	res == Time.from_hms(1, 0, 0)
}

# <---- from_nanos_since_midnight ---->
expect Time.from_nanos_since_midnight(-123) == Time.from_hmsn(-1, 59, 59, 999_999_877)
expect Time.from_nanos_since_midnight(0) == Time.midnight
expect Time.from_nanos_since_midnight((24 * Const.nanos_per_hour)) == Time.from_hms(24, 0, 0)
expect Time.from_nanos_since_midnight((25 * Const.nanos_per_hour)) == Time.from_hms(25, 0, 0)

expect Time.from_nanos_since_midnight((12 * Const.nanos_per_hour + 34 * Const.nanos_per_minute + 56 * Const.nanos_per_second + 5)) == Time.from_hmsn(12, 34, 56, 5)

# <---- normalize ---->
expect Time.normalize(Time.from_hms(-1, 0, 0)) == Time.from_hms(23, 0, 0)
expect Time.normalize(Time.from_hms(24, 0, 0)) == Time.from_hms(0, 0, 0)
expect Time.normalize(Time.from_hms(25, 0, 0)) == Time.from_hms(1, 0, 0)

# <---- to_iso_str ---->
expect Time.to_iso_str(Time.from_hmsn(12, 34, 56, 5)) == "12:34:56,000000005"
expect Time.to_iso_str(Time.midnight) == "00:00:00"
expect {
	str = Time.to_iso_str(Time.from_hmsn(0, 0, 0, 500_000_000))
	str == "00:00:00,5"
}

# <---- from_nanos_since_midnight ---->
expect Time.from_nanos_since_midnight(-123) == Time.from_hmsn(-1, 59, 59, 999_999_877)
expect Time.from_nanos_since_midnight(0) == Time.midnight
expect Time.from_nanos_since_midnight((24 * Const.nanos_per_hour)) == Time.from_hms(24, 0, 0)
expect Time.from_nanos_since_midnight((25 * Const.nanos_per_hour)) == Time.from_hms(25, 0, 0)

# <---- sub ---->
expect Time.sub(Time.from_hms(12, 34, 56), Time.from_hms(12, 34, 55)) == Duration.from_seconds(1.I128)
expect Time.sub(Time.from_hmsn(25, 0, 0, 1), Time.from_hmsn(1, 1, 1, 2)) == Duration.from_nanoseconds(23 * Const.nanos_per_hour.to_i128() + 58 * Const.nanos_per_minute.to_i128() + 59 * Const.nanos_per_second.to_i128() - 1)
expect Time.sub(Time.from_hms(-12, 34, 56), Time.from_hms(12, 34, 55)) == Duration.from_nanoseconds((-1) * Const.nanos_per_hour.to_i128() * 24 + Const.nanos_per_second.to_i128())

# <---- to_nanos_since_midnight ---->
expect Time.to_nanos_since_midnight({ hour: 12, minute: 34, second: 56, nanosecond: 5 }) == 12 * Const.nanos_per_hour + 34 * Const.nanos_per_minute + 56 * Const.nanos_per_second + 5
expect Time.to_nanos_since_midnight(Time.from_hmsn(12, 34, 56, 5)) == 12 * Const.nanos_per_hour + 34 * Const.nanos_per_minute + 56 * Const.nanos_per_second + 5
expect Time.to_nanos_since_midnight(Time.from_hmsn(-1, 0, 0, 0)) == -1 * Const.nanos_per_hour

# <---- before ---->
expect {
	a = Time.from_nanos_since_midnight(0)
	b = Time.from_nanos_since_midnight(0)
	!(b.before(a))
}
expect {
	a = Time.from_nanos_since_midnight(0)
	b = Time.from_nanos_since_midnight(1)
	!(b.before(a))
}
expect {
	a = Time.from_nanos_since_midnight(1)
	b = Time.from_nanos_since_midnight(0)
	b.before(a)
}

# <---- after ---->
expect {
	a = Time.from_nanos_since_midnight(0)
	b = Time.from_nanos_since_midnight(0)
	!(b.after(a))
}
expect {
	a = Time.from_nanos_since_midnight(0)
	b = Time.from_nanos_since_midnight(1)
	b.after(a)
}
expect {
	a = Time.from_nanos_since_midnight(1)
	b = Time.from_nanos_since_midnight(0)
	!(b.after(a))
}

# <---- equal ---->
expect {
	a = Time.from_nanos_since_midnight(0)
	b = Time.from_nanos_since_midnight(0)
	b.equal(a)
}
expect {
	a = Time.from_nanos_since_midnight(0)
	b = Time.from_nanos_since_midnight(1)
	!(b.equal(a))
}
expect {
	a = Time.from_nanos_since_midnight(1)
	b = Time.from_nanos_since_midnight(0)
	!(b.equal(a))
}

# <---- format ---->
expect {
	res = Time.format(Time.from_hmsn(12, 34, 56, 5), "{h}:{m}:{s}.{f}")
	res == "12:34:56.000000005"
}

expect {
	res = Time.format(Time.from_hmsn(12, 34, 56, 123456789), "{h}:{m}:{s}.{f:3}")
	res == "12:34:56.123"
}

expect {
	res = Time.format(Time.from_hmsn(12, 34, 56, 1234567891), "0.{f:}s")
	res == "0.123456789s"
}

expect {
	time = Time.from_hmsn(1, 2, 3, 4)
	res = Time.format(time, "{hh}:{mm}:{ss} + {n}ns")
	res == "01:02:03 + 4ns"
}
