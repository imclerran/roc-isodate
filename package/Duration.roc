## The duration modules provides the `Duration` type and associated functions for representing time durations and performing date/time arithmetic.
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
Duration :: { days : I64, hours : I8, minutes : I8, seconds : I8, nanoseconds : I32 }.{

	## Are two Durations equal?
	is_eq : _

	## Add two `Duration` objects.
	add : Duration, Duration -> Duration
	add = |d1, d2| {
		nanos1 = to_nanoseconds(d1)
		nanos2 = to_nanoseconds(d2)
		nanos1 |> add_saturated_i128(nanos2) |> from_nanoseconds
	}

	## Format a `Time` object according to the given format string.
	## The following placeholders are supported:
	## - `{d}`: day (0-I64.highest)
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
	format = |d, fmt| {
		(
			fmt
				.replace_first("{d}", d.days.to_str())
				.replace_first("{hh}", Utils.expand_int_with_zeros(d.hours.to_i64(), 2))
				.replace_first("{h}", d.hours.to_str())
				.replace_first("{mm}", Utils.expand_int_with_zeros(d.minutes.to_i64(), 2))
				.replace_first("{m}", d.minutes.to_str())
				.replace_first("{ss}", Utils.expand_int_with_zeros(d.seconds.to_i64(), 2))
				.replace_first("{s}", d.seconds.to_str())
				.replace_first("{f}", Utils.nanos_to_frac_str(d.nanoseconds).drop_prefix(","))
				|> Utils.replace_fx_format(d.nanoseconds),
		).replace_first("{n}", d.nanoseconds.to_str())
	}

	## Format a `Time` object according to the given format string. Negative numbers will not include a minus sign.
	## The following placeholders are supported:
	## - `{d}`: day (0-I64.highest)
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
	format_unsigned = |d, fmt| {
		(
			fmt
				.replace_first("{d}", d.days.to_str())
				.replace_first("{hh}", Utils.expand_int_with_zeros(d.hours.to_i64(), 2))
				.replace_first("{h}", d.hours.to_str())
				.replace_first("{mm}", Utils.expand_int_with_zeros(d.minutes.to_i64(), 2))
				.replace_first("{m}", d.minutes.to_str())
				.replace_first("{ss}", Utils.expand_int_with_zeros(d.seconds.to_i64(), 2))
				.replace_first("{s}", d.seconds.to_str())
				.replace_first("{f}", Utils.nanos_to_frac_str(d.nanoseconds).drop_prefix(","))
				|> Utils.replace_fx_format(d.nanoseconds),
		).replace_first("{n}", d.nanoseconds.to_str())
			.replace_each("-", "")
	}

	## Create a `Duration` object from days.
	from_days : I128 -> Duration
	from_days = |days| {
		days_saturated =
			if days > I64.highest.to_i128() {
				I64.highest.to_i128()
			} else if days < I64.lowest.to_i128() {
				I64.lowest.to_i128()
			} else {
				days
			}
		{
			days: days_saturated.to_i64_try() ?? {
				crash "Unreachable"
			},
			hours: 0,
			minutes: 0,
			seconds: 0,
			nanoseconds: 0,
		}
	}

	from_hms : I64, I8, I8 -> Duration
	from_hms = |hours, minutes, seconds| {
		from_hours(hours.to_i128()) |> add(from_minutes(minutes.to_i128())) |> add(from_seconds(seconds.to_i128()))
	}

	from_hmsn : I64, I8, I8, I32 -> Duration
	from_hmsn = |hours, minutes, seconds, nanoseconds| {
		from_hours(hours.to_i128()) |> add(from_minutes(minutes.to_i128())) |> add(from_seconds(seconds.to_i128())) |> add(from_nanoseconds(nanoseconds.to_i128()))
	}

	## Create a `Duration` object from hours.
	from_hours : I128 -> Duration
	from_hours = |hours| {
		hours_saturated =
			if (hours // 24) > I64.highest.to_i128() {
				I64.highest.to_i128() * 24
			} else if (hours // 24) < I64.lowest.to_i128() {
				I64.lowest.to_i128() * 24
			} else {
				hours
			}
		{
			days: (hours_saturated // 24).to_i64_try() ?? {
				crash "Unreachable"
			},
			hours: (hours_saturated % 24).to_i8_try() ?? {
				crash "Unreachable"
			},
			minutes: 0,
			seconds: 0,
			nanoseconds: 0,
		}
	}

	## Create a `Duration` object from minutes.
	from_minutes : I128 -> Duration
	from_minutes = |minutes| {
		minutes_saturated =
			if (minutes.to_i128() // Const.minutes_per_day.to_i128()) > I64.highest.to_i128() {
				I64.highest.to_i128() * Const.minutes_per_day.to_i128()
			} else if (minutes.to_i128() // Const.minutes_per_day.to_i128()) < I64.lowest.to_i128() {
				I64.lowest.to_i128() * Const.minutes_per_day.to_i128()
			} else {
				minutes.to_i128()
			}
		{
			days: (minutes_saturated // Const.minutes_per_day.to_i128()).to_i64_try() ?? {
				crash "Unreachable"
			},
			hours: ((minutes_saturated % Const.minutes_per_day.to_i128()) // Const.minutes_per_hour.to_i128()).to_i8_try() ?? {
				crash "Unreachable"
			},
			minutes: (minutes_saturated % Const.minutes_per_hour.to_i128()).to_i8_try() ?? {
				crash "Unreachable"
			},
			seconds: 0,
			nanoseconds: 0,
		}
	}

	## Create a `Duration` object from nanoseconds.
	from_nanoseconds : I128 -> Duration
	from_nanoseconds = |nanos| {
		days = nanos // Const.nanos_per_day.to_i128()
		nanos_saturated =
			if days > I64.highest.to_i128() {
				I64.highest.to_i128() * Const.nanos_per_day.to_i128()
			} else if days < I64.lowest.to_i128() {
				I64.lowest.to_i128() * Const.nanos_per_day.to_i128()
			} else {
				nanos
			}
		{
			days: (nanos_saturated // Const.nanos_per_day.to_i128()).to_i64_try() ?? {
				crash "Unreachable"
			},
			hours: ((nanos_saturated % Const.nanos_per_day.to_i128()) // Const.nanos_per_hour.to_i128()).to_i8_try() ?? {
				crash "Unreachable"
			},
			minutes: ((nanos_saturated % Const.nanos_per_hour.to_i128()) // Const.nanos_per_minute.to_i128()).to_i8_try() ?? {
				crash "Unreachable"
			},
			seconds: ((nanos_saturated % Const.nanos_per_minute.to_i128()) // Const.nanos_per_second.to_i128()).to_i8_try() ?? {
				crash "Unreachable"
			},
			nanoseconds: (nanos_saturated % Const.nanos_per_second.to_i128()).to_i32_try() ?? {
				crash "Unreachable"
			},
		}
	}

	## Create a `Duration` object from seconds.
	from_seconds : I128 -> Duration
	from_seconds = |seconds| {
		seconds_saturated =
			if (seconds.to_i128() // Const.seconds_per_day.to_i128()) > I64.highest.to_i128() {
				I64.highest.to_i128() * Const.seconds_per_day.to_i128()
			} else if (seconds.to_i128() // Const.seconds_per_day.to_i128()) < I64.lowest.to_i128() {
				I64.lowest.to_i128() * Const.seconds_per_day.to_i128()
			} else {
				seconds.to_i128()
			}
		{
			days: (seconds_saturated // Const.seconds_per_day.to_i128()).to_i64_try() ?? {
				crash "Unreachable"
			},
			hours: ((seconds_saturated % Const.seconds_per_day.to_i128()) // Const.seconds_per_hour.to_i128()).to_i8_try() ?? {
				crash "Unreachable"
			},
			minutes: ((seconds_saturated % Const.seconds_per_hour.to_i128()) // Const.seconds_per_minute.to_i128()).to_i8_try() ?? {
				crash "Unreachable"
			},
			seconds: (seconds_saturated % Const.seconds_per_minute.to_i128()).to_i8_try() ?? {
				crash "Unreachable"
			},
			nanoseconds: 0,
		}
	}

	## Subtract two `Duration` objects.
	sub : Duration, Duration -> Duration
	sub = |d1, d2| {
		nanos1 = to_nanoseconds(d1)
		nanos2 = to_nanoseconds(d2)
		nanos1 |> sub_saturated_i128(nanos2) |> from_nanoseconds
	}

	## Convert a `Duration` object to days (truncates hours and lower).
	to_days : Duration -> I64
	to_days = |duration| duration.days

	## Convert a `Duration` object to hours (truncates minutes and lower).
	to_hours : Duration -> I64
	to_hours = |duration| {
		duration.hours.to_i64()
			|> add_saturated_i64(duration.days.to_i64() |> mul_saturated_i64(24))
	}

	## Convert a `Duration` object to minutes (truncates seconds and lower).
	to_minutes : Duration -> I64
	to_minutes = |duration| {
		duration.minutes.to_i64()
			|> add_saturated_i64(duration.hours.to_i64() |> mul_saturated_i64(Const.minutes_per_hour.to_i64()))
			|> add_saturated_i64(duration.days |> mul_saturated_i64(Const.minutes_per_day.to_i64()))
	}

	## Convert a `Duration` object to nanoseconds.
	to_nanoseconds : Duration -> I128
	to_nanoseconds = |duration| {
		duration.nanoseconds.to_i128()
			|> add_saturated_i128(duration.seconds.to_i128() |> mul_saturated_i128(Const.nanos_per_second.to_i128()))
			|> add_saturated_i128(duration.minutes.to_i128() |> mul_saturated_i128(Const.nanos_per_minute.to_i128()))
			|> add_saturated_i128(duration.hours.to_i128() |> mul_saturated_i128(Const.nanos_per_hour.to_i128()))
			|> add_saturated_i128(duration.days.to_i128() |> mul_saturated_i128(Const.nanos_per_day.to_i128()))
	}

	## Convert a `Duration` object to seconds (truncates nanoseconds).
	to_seconds : Duration -> I64
	to_seconds = |duration| {
		duration.seconds.to_i64()
			|> add_saturated_i64(duration.minutes.to_i64() |> mul_saturated_i64(Const.seconds_per_minute.to_i64()))
			|> add_saturated_i64(duration.hours.to_i64() |> mul_saturated_i64(Const.seconds_per_hour.to_i64()))
			|> add_saturated_i64(duration.days |> mul_saturated_i64(Const.seconds_per_day.to_i64()))
	}
}

add_saturated_i64 = |a, b| {
	if b > 0 and a > I64.highest - b {
		I64.highest
	} else if b < 0 and a < I64.lowest - b {
		I64.lowest
	} else {
		a + b
	}
}

mul_saturated_i64 = |a, b| {
	if a == 0 or b == 0 {
		0
	} else if a > 0 {
		if b > 0 {
			if a > I64.highest // b {
				I64.highest
			} else {
				a * b
			}
		} else {
			if b < I64.lowest // a {
				I64.lowest
			} else {
				a * b
			}
		}
	} else {
		if b > 0 {
			if a < I64.lowest // b {
				I64.lowest
			} else {
				a * b
			}
		} else {
			if a < I64.highest // b {
				I64.highest
			} else {
				a * b
			}
		}
	}
}

add_saturated_i128 = |a, b| {
	max_i128 = I128.highest
	min_i128 = I128.lowest
	if b > 0 and a > max_i128 - b {
		max_i128
	} else if b < 0 and a < min_i128 - b {
		min_i128
	} else {
		a + b
	}
}

sub_saturated_i128 = |a, b| {
	max_i128 = I128.highest
	min_i128 = I128.lowest
	if b < 0 and a > max_i128 + b {
		max_i128
	} else if b > 0 and a < min_i128 + b {
		min_i128
	} else {
		a - b
	}
}

mul_saturated_i128 = |a, b| {
	max_i128 = I128.highest
	min_i128 = I128.lowest
	if a == 0 or b == 0 {
		0
	} else if a > 0 {
		if b > 0 {
			if a > max_i128 // b {
				max_i128
			} else {
				a * b
			}
		} else {
			if b < min_i128 // a {
				min_i128
			} else {
				a * b
			}
		}
	} else {
		if b > 0 {
			if a < min_i128 // b {
				min_i128
			} else {
				a * b
			}
		} else {
			if a < max_i128 // b {
				max_i128
			} else {
				a * b
			}
		}
	}
}

# <===== TESTS ====>
# <---- add ---->
expect {
	d1 = Duration.from_days(I64.highest.to_i128() // 2)
	d2 = Duration.from_days(I64.highest.to_i128() // 2)
	d3 = Duration.from_days((I64.highest.to_i128() // 2) * 2)
	Duration.add(d1, d2) == d3
}

expect {
	d1 = Duration.from_days(I64.lowest.to_i128())
	d2 = Duration.from_days(I64.highest.to_i128())
	Duration.add(d1, d2) == Duration.from_days(-1.I128)
}

expect {
	days = I64.highest
	duration = Duration.from_days(days.to_i128())
	Duration.add(duration, duration) == Duration.from_days(days.to_i128())
}

# <---- from_hmsn ---->
expect {
	res = Duration.from_hmsn(I64.highest, 0, 0, 0)
	res == Duration.from_days(384307168202282325) |> Duration.add(Duration.from_hours(7))
}

expect {
	res = Duration.from_hmsn(0, 127, 0, 0)
	res == Duration.from_hours(2) |> Duration.add(Duration.from_minutes(7))
}

expect {
	res = Duration.from_hmsn(0, 0, 127, 0)
	res == Duration.from_minutes(2) |> Duration.add(Duration.from_seconds(7))
}

expect {
	res = Duration.from_hmsn(0, 0, 0, I32.highest)
	res == Duration.from_seconds(2) |> Duration.add(Duration.from_nanoseconds(147483647))
}

expect {
	res = Duration.from_hmsn(I64.highest, 127, 127, I32.highest)
	res == Duration.from_days(384307168202282325) |> Duration.add(Duration.from_hours(9)) |> Duration.add(Duration.from_minutes(9)) |> Duration.add(Duration.from_seconds(9)) |> Duration.add(Duration.from_nanoseconds(147483647))
}

# <---- sub ---->
expect {
	d = Duration.from_days(I64.highest.to_i128())
	Duration.sub(d, d) == Duration.from_days(0)
}

expect {
	d = Duration.from_days(I64.lowest.to_i128())
	Duration.sub(d, d) == Duration.from_days(0)
}

expect {
	d1 = Duration.from_days(1)
	d2 = Duration.from_days(2)
	Duration.sub(d1, d2) == Duration.from_days(-1.I128)
}

# <---- saturation test ---->
expect {
	days_over = I64.highest.to_i128() + 1
	duration = Duration.from_days(days_over)
	duration.to_days() == I64.highest
}

expect {
	days_under = I64.lowest.to_i128() - 1
	duration = Duration.from_days(days_under)
	duration.to_days() == I64.lowest
}

# <---- format & format_unsigned ---->
expect {
	d = Duration.from_hmsn(1, 2, 3, 456000000)
	Duration.format(d, "{d}d {hh}:{mm}:{ss}.{f:3}") == "0d 01:02:03.456"
}

expect {
	d = Duration.from_seconds(-90)
	Duration.format_unsigned(d, "{m}:{ss}") == "1:30"
}

# <---- to_* conversions ---->
expect {
	d = Duration.from_hms(1, 30, 0)
	d.to_hours() == 1 and d.to_minutes() == 90 and d.to_seconds() == 5400
}
