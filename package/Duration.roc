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

	## The whole-days component of the `Duration`. See [`to_days`](Duration#to_days) for the total.
	days : Duration -> I64
	days = |duration| duration.days

	## The hours component of the `Duration`, from -23 to 23. See [`to_hours`](Duration#to_hours) for the total.
	hours : Duration -> I8
	hours = |duration| duration.hours

	## The minutes component of the `Duration`, from -59 to 59. See [`to_minutes`](Duration#to_minutes) for the total.
	minutes : Duration -> I8
	minutes = |duration| duration.minutes

	## The seconds component of the `Duration`, from -59 to 59. See [`to_seconds`](Duration#to_seconds) for the total.
	seconds : Duration -> I8
	seconds = |duration| duration.seconds

	## The nanoseconds component of the `Duration`, from -999,999,999 to 999,999,999. See [`to_nanoseconds`](Duration#to_nanoseconds) for the total.
	nanoseconds : Duration -> I32
	nanoseconds = |duration| duration.nanoseconds

	## Add two `Duration` objects.
	add : Duration, Duration -> Duration
	add = |d1, d2| {
		nanos1 = to_nanoseconds(d1)
		nanos2 = to_nanoseconds(d2)
		nanos1.plus_saturated(nanos2) |> from_nanoseconds
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
	from_days = |n| {
		days_saturated =
			if n > I64.highest.to_i128() {
				I64.highest.to_i128()
			} else if n < I64.lowest.to_i128() {
				I64.lowest.to_i128()
			} else {
				n
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
	from_hms = |h, m, s| {
		from_hours(h.to_i128()) |> add(from_minutes(m.to_i128())) |> add(from_seconds(s.to_i128()))
	}

	from_hmsn : I64, I8, I8, I32 -> Duration
	from_hmsn = |h, m, s, n| {
		from_hours(h.to_i128()) |> add(from_minutes(m.to_i128())) |> add(from_seconds(s.to_i128())) |> add(from_nanoseconds(n.to_i128()))
	}

	## Create a `Duration` object from hours.
	from_hours : I128 -> Duration
	from_hours = |n| {
		hours_saturated =
			if (n // 24) > I64.highest.to_i128() {
				I64.highest.to_i128() * 24
			} else if (n // 24) < I64.lowest.to_i128() {
				I64.lowest.to_i128() * 24
			} else {
				n
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
	from_minutes = |n| {
		minutes_saturated =
			if (n.to_i128() // Const.minutes_per_day.to_i128()) > I64.highest.to_i128() {
				I64.highest.to_i128() * Const.minutes_per_day.to_i128()
			} else if (n.to_i128() // Const.minutes_per_day.to_i128()) < I64.lowest.to_i128() {
				I64.lowest.to_i128() * Const.minutes_per_day.to_i128()
			} else {
				n.to_i128()
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
		whole_days = nanos // Const.nanos_per_day.to_i128()
		nanos_saturated =
			if whole_days > I64.highest.to_i128() {
				I64.highest.to_i128() * Const.nanos_per_day.to_i128()
			} else if whole_days < I64.lowest.to_i128() {
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
	from_seconds = |n| {
		seconds_saturated =
			if (n.to_i128() // Const.seconds_per_day.to_i128()) > I64.highest.to_i128() {
				I64.highest.to_i128() * Const.seconds_per_day.to_i128()
			} else if (n.to_i128() // Const.seconds_per_day.to_i128()) < I64.lowest.to_i128() {
				I64.lowest.to_i128() * Const.seconds_per_day.to_i128()
			} else {
				n.to_i128()
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
		nanos1.minus_saturated(nanos2) |> from_nanoseconds
	}

	## Convert a `Duration` object to days (truncates hours and lower).
	to_days : Duration -> I64
	to_days = |duration| duration.days

	## Convert a `Duration` object to hours (truncates minutes and lower).
	to_hours : Duration -> I64
	to_hours = |duration| {
		duration.hours.to_i64()
			.plus_saturated(duration.days.to_i64().times_saturated(24))
	}

	## Convert a `Duration` object to minutes (truncates seconds and lower).
	to_minutes : Duration -> I64
	to_minutes = |duration| {
		duration.minutes.to_i64()
			.plus_saturated(duration.hours.to_i64().times_saturated(Const.minutes_per_hour.to_i64()))
			.plus_saturated(duration.days.times_saturated(Const.minutes_per_day.to_i64()))
	}

	## Convert a `Duration` object to nanoseconds.
	to_nanoseconds : Duration -> I128
	to_nanoseconds = |duration| {
		duration.nanoseconds.to_i128()
			.plus_saturated(duration.seconds.to_i128().times_saturated(Const.nanos_per_second.to_i128()))
			.plus_saturated(duration.minutes.to_i128().times_saturated(Const.nanos_per_minute.to_i128()))
			.plus_saturated(duration.hours.to_i128().times_saturated(Const.nanos_per_hour.to_i128()))
			.plus_saturated(duration.days.to_i128().times_saturated(Const.nanos_per_day.to_i128()))
	}

	## Convert a `Duration` object to seconds (truncates nanoseconds).
	to_seconds : Duration -> I64
	to_seconds = |duration| {
		duration.seconds.to_i64()
			.plus_saturated(duration.minutes.to_i64().times_saturated(Const.seconds_per_minute.to_i64()))
			.plus_saturated(duration.hours.to_i64().times_saturated(Const.seconds_per_hour.to_i64()))
			.plus_saturated(duration.days.times_saturated(Const.seconds_per_day.to_i64()))
	}
}

# <===== TESTS ====>
# <---- days / hours / minutes / seconds / nanoseconds ---->
expect {
	d = Duration.from_days(2).add(Duration.from_hmsn(3, 4, 5, 6))
	d.days() == 2 and d.hours() == 3 and d.minutes() == 4 and d.seconds() == 5 and d.nanoseconds() == 6
}
expect {
	d = Duration.from_hours(25)
	d.days() == 1 and d.hours() == 1 and d.minutes() == 0 and d.seconds() == 0 and d.nanoseconds() == 0
}
expect {
	d = Duration.from_nanoseconds(-1)
	d.days() == 0 and d.hours() == 0 and d.minutes() == 0 and d.seconds() == 0 and d.nanoseconds() == -1
}

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
