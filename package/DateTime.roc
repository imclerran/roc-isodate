## The DateTime module provides the `DateTime` type, including functions for working with combined date and time values.
##
## These functions include functions for creating `DateTime` objects from various numeric values, converting `DateTime`s to and from ISO 8601 strings, and performing arithmetic operations on `DateTime`s.
import Const
import Date
import Duration
import Time
import Utils

## ```
## DateTime :: { date : Date, time: Time }
## ```
DateTime :: { date : Date, time : Time }.{
	is_eq : _
	Interval : { start : DateTime, end : DateTime }

	## Same as [`add_duration`](DateTime#add_duration)
	add : DateTime, Duration -> DateTime
	add = add_duration

	## Add days to a `DateTime` object.
	add_days : DateTime, I64 -> DateTime
	add_days = |date_time, days| { date: Date.add_days(date_time.date, days), time: date_time.time }

	## Add a `Duration` object to a `DateTime` object. (May be deprecated in favor of [`add`](DateTime#add) in the future.)
	add_duration : DateTime, Duration -> DateTime
	add_duration = |date_time, duration| {
		duration_nanos = duration.to_nanoseconds()
		date_nanos = Date.to_nanos_since_epoch(date_time.date)
		time_nanos = Time.to_nanos_since_midnight(date_time.time).to_i128()
		from_nanos_since_epoch(duration_nanos + date_nanos + time_nanos)
	}

	## Add minutes to a `DateTime` object.
	add_minutes : DateTime, I64 -> DateTime
	add_minutes = |date_time, minutes| add_nanoseconds(date_time, minutes * Const.nanos_per_minute)

	## Add months to a `DateTime` object.
	add_months : DateTime, I64 -> DateTime
	add_months = |date_time, months| { date: Date.add_months(date_time.date, months), time: date_time.time }

	## Add hours to a `DateTime` object.
	add_hours : DateTime, I64 -> DateTime
	add_hours = |date_time, hours| add_nanoseconds(date_time, hours * Const.nanos_per_hour)

	## Add nanoseconds to a `DateTime` object.
	add_nanoseconds : DateTime, I64 -> DateTime
	add_nanoseconds = |date_time, nanos| {
		# new_time = Time.add_nanoseconds(date_time.time, nanos)
		time_nanos = Time.to_nanos_since_midnight(date_time.time) + nanos
		days =
			if time_nanos >= 0 {
				time_nanos // Const.nanos_per_day.to_i64()
			} else {
				(time_nanos // Const.nanos_per_day.to_i64()) + (
					if time_nanos % Const.nanos_per_day.to_i64() < 0 {
						-1
					} else {
						0
					}
				)
			}
		{ date: Date.add_days(date_time.date, days), time: Time.from_nanos_since_midnight(time_nanos) |> Time.normalize }
	}

	## Add seconds to a `DateTime` object.
	add_seconds : DateTime, I64 -> DateTime
	add_seconds = |date_time, seconds| add_nanoseconds(date_time, seconds * Const.nanos_per_second)

	## Add years to a `DateTime` object.
	add_years : DateTime, I64 -> DateTime
	add_years = |date_time, years| { date: Date.add_years(date_time.date, years), time: date_time.time }

	## Determine if the first `DateTime` occurs after the second `DateTime`.
	after : DateTime, DateTime -> Bool
	after = |a, b| a.order_relative_to(b) == After

	## Determine if the first `DateTime` occurs before the second `DateTime`.
	before : DateTime, DateTime -> Bool
	before = |a, b| a.order_relative_to(b) == Before

	## Compare two `DateTime` objects.
	## If the first occurs before the second, it returns Before.
	## If the first and the second are equal, it returns Same.
	## If the first occurs after the second, it returns After.
	order_relative_to : DateTime, DateTime -> [Before, Same, After]
	order_relative_to = |a, b| {
		match a.date.order_relative_to(b.date) {
			Same => a.time.order_relative_to(b.time)
			result => result
		}
	}

	## Determine if the first `DateTime` equals the second `DateTime`.
	equal : DateTime, DateTime -> Bool
	equal = |a, b| a.order_relative_to(b) == Same

	## Format a `DateTime` object according to the given format string.
	## The following placeholders are supported:
	## - `{YYYY}`: 4-digit year
	## - `{YY}`: 2-digit year
	## - `{MM}`: 2-digit month (01-12)
	## - `{M}`: month (1-12)
	## - `{DD}`: 2-digit day of the month (01-31)
	## - `{D}`: day of the month (1-31)
	## - `{hh}`: 2-digit hour (00-23)
	## - `{h}`: hour (0-23)
	## - `{mm}`: 2-digit minute (00-59)
	## - `{m}`: minute (0-59)
	## - `{ss}`: 2-digit second (00-59)
	## - `{s}`: second (0-59)
	## - `{f}` or `{f:}`: fractional part of the second (in nanoseconds)
	## - `{f:x}`: fractional part of the second with x digits
	## - `{n}`: nanosecond (0-999,999,999)
	format : DateTime, Str -> Str
	format = |dt, fmt| {
		time_fmt = Date.format(dt.date, fmt)
		Time.format(dt.time, time_fmt)
	}

	## Convert an ISO 8601 string to a `DateTime` object.
	from_iso_str : Str -> Try(DateTime, [InvalidDateTimeFormat])
	from_iso_str = |str| str.to_utf8() |> from_iso_u8

	## Convert an ISO 8601 list of UTF-8 bytes to a `DateTime` object.
	from_iso_u8 : List(U8) -> Try(DateTime, [InvalidDateTimeFormat])
	from_iso_u8 = |bytes| {
		match Utils.split_with_delims(bytes, |b| b == 'T') {
			[date_bytes, ['T'], time_bytes] => {
				# TODO: currently cannot support timezone offsets which exceed or precede the current day
				match (Date.from_iso_u8(date_bytes), Time.from_iso_u8(time_bytes)) {
					(Ok(date), Ok(time)) => {
						normalize({ date, time }) |> Ok
					}
					_ => Err(InvalidDateTimeFormat)
				}
			}
			[date_bytes] => {
				match Date.from_iso_u8(date_bytes) {
					Ok(date) => {
						{ date, time: Time.from_hms(0, 0, 0) } |> Ok
					}
					_ => Err(InvalidDateTimeFormat)
				}
			}
			_ => Err(InvalidDateTimeFormat)
		}
	}

	## Convert the number of nanoseconds since the Unix epoch to a `DateTime` object.
	from_nanos_since_epoch : I128 -> DateTime
	from_nanos_since_epoch = |nanos| {
		time_nanos =
			if nanos < 0 and nanos % Const.nanos_per_day.to_i128() != 0 {
				nanos % Const.nanos_per_day.to_i128() + Const.nanos_per_day.to_i128()
			} else {
				nanos % Const.nanos_per_day.to_i128()
			}
		date_nanos = nanos - time_nanos
		date = Date.from_nanos_since_epoch(date_nanos)
		time = Time.from_nanos_since_midnight(time_nanos.to_i64_wrap())
		{ date, time }
	}

	## Create a `DateTime` object from the year and day of the year.
	from_yd : I64, I64 -> DateTime
	from_yd = |year, day| { date: Date.from_yd(year, day.to_u16_wrap()), time: Time.midnight }

	## Create a `DateTime` object from the year, month, and day.
	from_ymd : I64, I64, I64 -> DateTime
	from_ymd = |year, month, day| { date: Date.from_ymd(year, month.to_u8_wrap(), day.to_u8_wrap()), time: Time.midnight }

	## Create a `DateTime` object from the year and week.
	from_yw : I64, I64 -> DateTime
	from_yw = |year, week| { date: Date.from_yw(year, week.to_u8_wrap()), time: Time.midnight }

	## Create a `DateTime` object from the year, week, and day of the week.
	from_ywd : I64, I64, I64 -> DateTime
	from_ywd = |year, week, day| { date: Date.from_ywd(year, week.to_u8_wrap(), day.to_u8_wrap()), time: Time.midnight }

	## Create a `DateTime` object from the year, month, day, hour, minute, and second.
	from_ymdhms : I64, I64, I64, I64, I64, I64 -> DateTime
	from_ymdhms = |year, month, day, hour, minute, second| {
		{ date: Date.from_ymd(year, month.to_u8_wrap(), day.to_u8_wrap()), time: Time.from_hms(hour, minute, second) }
	}

	## Create a `DateTime` object from the year, month, day, hour, minute, second, and nanosecond.
	from_ymdhmsn : I64, I64, I64, I64, I64, I64, I64 -> DateTime
	from_ymdhmsn = |year, month, day, hour, minute, second, nanosecond| {
		{ date: Date.from_ymd(year, month.to_u8_wrap(), day.to_u8_wrap()), time: Time.from_hmsn(hour, minute, second, nanosecond) }
	}

	## Subtract two `DateTime` objects to get the `Duration` between them.
	sub : DateTime, DateTime -> Duration
	sub = |a, b| {
		a_nanos = to_nanos_since_epoch(a)
		b_nanos = to_nanos_since_epoch(b)
		Duration.from_nanoseconds(a_nanos - b_nanos)
	}

	## Convert a `DateTime` object to an ISO 8601 string.
	to_iso_str : DateTime -> Str
	to_iso_str = |date_time| {
		Date.to_iso_str(date_time.date).concat("T").concat(Time.to_iso_str(date_time.time))
	}

	## Convert a `DateTime` object to an ISO 8601 list of UTF-8 bytes.
	to_iso_u8 : DateTime -> List(U8)
	to_iso_u8 = |date_time| {
		Date.to_iso_u8(date_time.date).concat(['T']).concat(Time.to_iso_u8(date_time.time))
	}

	## Convert a `DateTime` object to the number of nanoseconds since the Unix epoch.
	to_nanos_since_epoch : DateTime -> I128
	to_nanos_since_epoch = |date_time| {
		date_nanos = Date.to_nanos_since_epoch(date_time.date)
		time_nanos = Time.to_nanos_since_midnight(date_time.time).to_i128()
		date_nanos + time_nanos
	}

	## `DateTime` object representing the Unix epoch (1970-01-01T00:00:00).
	unix_epoch : DateTime
	unix_epoch = { date: Date.unix_epoch, time: Time.midnight }

	## Get the day of the week for a `DateTime` object (0 = Sunday, 6 = Saturday).
	weekday : DateTime -> U8
	weekday = |dt| Date.weekday(dt.date)

	## Normalize a `DateTime` object.
	normalize : DateTime -> DateTime
	normalize = |date_time| {
		DateTime.add_hours(
			{
				date: date_time.date,
				time: Time.from_hmsn(0, Time.get_minute(date_time.time).to_i64(), Time.get_second(date_time.time).to_i64(), Time.get_nanosecond(date_time.time).to_i64()),
			},
			Time.get_hour(date_time.time).to_i64(),
		)
	}
}

# <==== TESTS ====>
# <---- add_nanoseconds ---->
expect DateTime.from_ymdhmsn(1970, 1, 1, 0, 0, 0, 0).add_nanoseconds(1) == DateTime.from_ymdhmsn(1970, 1, 1, 0, 0, 0, 1)
expect DateTime.from_ymdhmsn(1970, 1, 1, 0, 0, 0, 0).add_nanoseconds(Const.nanos_per_second) == DateTime.from_ymdhmsn(1970, 1, 1, 0, 0, 1, 0)
expect DateTime.from_ymdhmsn(1970, 1, 1, 0, 0, 0, 0).add_nanoseconds(Const.nanos_per_day) == DateTime.from_ymdhmsn(1970, 1, 2, 0, 0, 0, 0)
expect DateTime.from_ymdhmsn(1970, 1, 1, 0, 0, 0, 0).add_nanoseconds(-1) == DateTime.from_ymdhmsn(1969, 12, 31, 23, 59, 59, (Const.nanos_per_second - 1))
expect DateTime.from_ymdhmsn(1970, 1, 1, 0, 0, 0, 0).add_nanoseconds(-Const.nanos_per_day) == DateTime.from_ymdhmsn(1969, 12, 31, 0, 0, 0, 0)
expect DateTime.from_ymdhmsn(1970, 1, 1, 0, 0, 0, 0).add_nanoseconds(((-Const.nanos_per_day) - 1)) == DateTime.from_ymdhmsn(1969, 12, 30, 23, 59, 59, (Const.nanos_per_second - 1))

# <---- add_duration ---->
expect DateTime.add_duration(DateTime.unix_epoch, Duration.from_nanoseconds(-1.I128)) == DateTime.from_ymdhmsn(1969, 12, 31, 23, 59, 59, (Const.nanos_per_second - 1))
expect DateTime.add_duration(DateTime.unix_epoch, Duration.from_days(365.I128)) == DateTime.from_ymdhmsn(1971, 1, 1, 0, 0, 0, 0)

# <--- after --->
expect {
	a = DateTime.from_nanos_since_epoch(0.I128)
	b = DateTime.from_nanos_since_epoch(0.I128)
	!(a.after(b))
}
expect {
	a = DateTime.from_nanos_since_epoch(0.I128)
	b = DateTime.from_nanos_since_epoch(1.I128)
	!(a.after(b))
}
expect {
	a = DateTime.from_nanos_since_epoch(1.I128)
	b = DateTime.from_nanos_since_epoch(0.I128)
	a.after(b)
}

# <--- before --->
expect {
	a = DateTime.from_nanos_since_epoch(0.I128)
	b = DateTime.from_nanos_since_epoch(0.I128)
	!(a.before(b))
}
expect {
	a = DateTime.from_nanos_since_epoch(0.I128)
	b = DateTime.from_nanos_since_epoch(1.I128)
	a.before(b)
}
expect {
	a = DateTime.from_nanos_since_epoch(1.I128)
	b = DateTime.from_nanos_since_epoch(0.I128)
	!(a.before(b))
}

# <--- equal --->
expect {
	a = DateTime.from_nanos_since_epoch(0.I128)
	b = DateTime.from_nanos_since_epoch(0.I128)
	a.equal(b)
}
expect {
	a = DateTime.from_nanos_since_epoch(0.I128)
	b = DateTime.from_nanos_since_epoch(1.I128)
	!(a.equal(b))
}
expect {
	a = DateTime.from_nanos_since_epoch(1.I128)
	b = DateTime.from_nanos_since_epoch(0.I128)
	!(a.equal(b))
}

# <--- format --->
expect {
	res = DateTime.format(DateTime.from_ymdhmsn(1970, 1, 1, 1, 1, 1, 123456789), "{YYYY}-{MM}-{DD}T{hh}:{mm}:{ss}.{f:3}")
	res == "1970-01-01T01:01:01.123"
}

# <--- from_nanos_since_epoch --->
expect DateTime.from_nanos_since_epoch((364 * 24 * Const.nanos_per_hour.to_i128() + 12 * Const.nanos_per_hour.to_i128() + 34 * Const.nanos_per_minute.to_i128() + 56 * Const.nanos_per_second.to_i128() + 5)) == DateTime.from_ymdhmsn(1970, 12, 31, 12, 34, 56, 5)
expect DateTime.from_nanos_since_epoch(-1.I128) == DateTime.from_ymdhmsn(1969, 12, 31, 23, 59, 59, (Const.nanos_per_second - 1))

# <--- normalize --->
expect DateTime.normalize(DateTime.from_ymdhmsn(1970, 1, 2, -12, 1, 2, 3)) == DateTime.from_ymdhmsn(1970, 1, 1, 12, 1, 2, 3)
expect DateTime.normalize(DateTime.from_ymdhmsn(1970, 1, 1, 12, 1, 2, 3)) == DateTime.from_ymdhmsn(1970, 1, 1, 12, 1, 2, 3)
expect DateTime.normalize(DateTime.from_ymdhmsn(1970, 1, 1, 36, 1, 2, 3)) == DateTime.from_ymdhmsn(1970, 1, 2, 12, 1, 2, 3)

# <--- sub --->
expect DateTime.sub(DateTime.from_ymd(1970, 1, 1), DateTime.from_ymdhmsn(1970, 1, 1, 0, 0, 0, 1)) == Duration.from_nanoseconds(-1.I128)
expect DateTime.sub(DateTime.from_ymdhmsn(1970, 1, 1, 1, 1, 1, 1), DateTime.from_yd(1968, 1)) == Duration.from_nanoseconds((Const.nanos_per_day.to_i128() * 731 + Const.nanos_per_hour.to_i128() + Const.nanos_per_minute.to_i128() + Const.nanos_per_second.to_i128() + 1))

# <---- to_iso_str ---->
expect DateTime.to_iso_str(DateTime.unix_epoch) == "1970-01-01T00:00:00"
expect DateTime.to_iso_str(DateTime.from_ymdhmsn(1970, 1, 1, 0, 0, 0, (Const.nanos_per_second // 2))) == "1970-01-01T00:00:00,5"

# <---- to_iso_u8 ---->
expect DateTime.to_iso_u8(DateTime.unix_epoch) == Str.to_utf8("1970-01-01T00:00:00")

# <--- to_nanos_since_epoch --->
expect DateTime.to_nanos_since_epoch(DateTime.from_ymdhmsn(1970, 12, 31, 12, 34, 56, 5)) == 364 * Const.nanos_per_day.to_i128() + 12 * Const.nanos_per_hour.to_i128() + 34 * Const.nanos_per_minute.to_i128() + 56 * Const.nanos_per_second.to_i128() + 5
