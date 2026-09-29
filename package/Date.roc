## The Date module provides the `Date` type, including various functions for working with dates.
##
## These functions include functions for creating dates from various numeric values, converting dates to and from ISO 8601 strings, and performing arithmetic operations on dates.
import Const
import Duration
import Utils

## ```
## Date :: {
##     year: I64,
##     month: U8,
##     day_of_month: U8,
##     day_of_year: U16
## }
## ```
Date :: {
	year : I64,
	month : U8,
	day_of_month : U8,
	day_of_year : U16,
}.{

	## Are two Dates equal?
	is_eq : Date, Date -> Bool
	is_eq = |a, b| a.year == b.year and a.day_of_year == b.day_of_year

	## Same as [`add_duration`](Date#add_duration).
	add : Date, Duration -> Date
	add = add_duration

	## Add the given number of days to the given `Date`.
	add_days : Date, I64 -> Date
	add_days = |date, days| {
		from_days_since_epoch(num_days_since_epoch(date) + days)
	}

	## Add the given `Date` and `Duration`. (May be deprecated in favor of [`add`](Date#add) in the future.)
	add_duration : Date, Duration -> Date
	add_duration = |date, duration| {
		duration_nanos = duration.to_nanoseconds()
		date_nanos = to_nanos_since_epoch(date)
		from_nanos_since_epoch(duration_nanos + date_nanos)
	}

	## Add the given number of months to the given `Date`.
	add_months : Date, I64 -> Date
	add_months = |date, months| {
		total_months = date.year * 12 + (date.month.to_i64() - 1) + months
		new_year = total_months.div_floor_by(12)
		new_month = (
			(total_months - new_year * 12).to_u8_try() ?? {
				crash "Unreachable"
			}
		) + 1
		days_in_new_month = days_in_month(new_year, new_month)
		new_day =
			if date.day_of_month > days_in_new_month {
				days_in_new_month
			} else {
				date.day_of_month
			}
		from_ymd(new_year, new_month, new_day)
	}

	## Add the given number of years to the given `Date`.
	add_years : Date, I64 -> Date
	add_years = |date, years| {
		date.add_months(years * 12)
	}

	## Determine if the first `Date` falls after the second `Date`.
	after : Date, Date -> Bool
	after = |a, b| a.order_relative_to(b) == After

	## Determine if the first `Date` falls before the second `Date`.
	before : Date, Date -> Bool
	before = |a, b| a.order_relative_to(b) == Before

	## Convert the given calendar week and year to the day of the year.
	calendar_week_to_days_in_year : U8, I64 -> I64
	calendar_week_to_days_in_year = |week, year| {
		# Week 1 of a year is the first week with a majority of its days in that year
		# https://en.wikipedia.org/wiki/ISO_week_date#First_week
		w = week.to_i64()
		days_since_epoch = num_days_since_epoch_until_year(year)
		length_of_maybe_first_week =
			if year >= Const.epoch_year {
				Const.epoch_week_offset.to_i64() - days_since_epoch % 7
			} else {
				(Const.epoch_week_offset.to_i64() + days_since_epoch.abs()) % 7
			}
		if length_of_maybe_first_week >= 4 and w == 1 {
			0
		} else {
			(w - 1) * Const.days_per_week.to_i64() + length_of_maybe_first_week
		}
	}

	## Compare two `Date` objects.
	## If the first is before the second, it returns Before.
	## If the first is after the second, it returns After.
	## If the first and the second are equal, it returns Same.
	order_relative_to : Date, Date -> [Before, Same, After]
	order_relative_to = |a, b| {
		match a.year.order_relative_to(b.year) {
			Same => a.day_of_year.order_relative_to(b.day_of_year)
			result => result
		}
	}

	## Determine if the first `Date` equals the second `Date`.
	equal : Date, Date -> Bool
	equal = |a, b| a.year == b.year and a.day_of_year == b.day_of_year

	## Format a `Date` object according to the given format string.
	## The following placeholders are supported:
	## - `{YYYY}`: 4-digit year
	## - `{YY}`: 2-digit year
	## - `{MM}`: 2-digit month (01-12)
	## - `{M}`: month (1-12)
	## - `{DD}`: 2-digit day of the month (01-31)
	## - `{D}`: day of the month (1-31)
	format : Date, Str -> Str
	format = |date, fmt| {
		fmt
			.replace_first("{YYYY}", Utils.expand_int_with_zeros(date.year, 4))
			.replace_first("{YY}", Utils.expand_int_with_zeros(date.year % 100, 2))
			.replace_first("{MM}", Utils.expand_int_with_zeros(date.month.to_i64(), 2))
			.replace_first("{M}", date.month.to_str())
			.replace_first("{DD}", Utils.expand_int_with_zeros(date.day_of_month.to_i64(), 2))
			.replace_first("{D}", date.day_of_month.to_str())
	}

	## Convert the given ISO 8601 string to a `Date`.
	from_iso_str : Str -> Try(Date, [InvalidDateFormat])
	from_iso_str = |str| str.to_utf8() |> from_iso_u8

	# TODO: More efficient parsing method?
	## Convert the given ISO 8601 list of UTF-8 bytes to a `Date`.
	from_iso_u8 : List(U8) -> Try(Date, [InvalidDateFormat])
	from_iso_u8 = |bytes| {
		if Utils.validate_utf8_single_bytes(bytes) {
			match bytes {
				[_, _] => parse_calendar_date_century(bytes) # YY
				[_, _, _, _] => parse_calendar_date_year(bytes) # YYYY
				[_, _, _, _, 'W', _, _] => parse_week_date_reduced_basic(bytes) # YYYYWww
				[_, _, _, _, '-', _, _] => parse_calendar_date_month(bytes) # YYYY-MM
				[_, _, _, _, _, _, _] => parse_ordinal_date_basic(bytes) # YYYYDDD
				[_, _, _, _, '-', 'W', _, _] => parse_week_date_reduced_extended(bytes) # YYYY-Www
				[_, _, _, _, 'W', _, _, _] => parse_week_date_basic(bytes) # YYYYWwwD
				[_, _, _, _, '-', _, _, _] => parse_ordinal_date_extended(bytes) # YYYY-DDD
				[_, _, _, _, _, _, _, _] => parse_calendar_date_basic(bytes) # YYYYMMDD
				[_, _, _, _, '-', 'W', _, _, '-', _] => parse_week_date_extended(bytes) # YYYY-Www-D
				[_, _, _, _, '-', _, _, '-', _, _] => parse_calendar_date_extended(bytes) # YYYY-MM-DD
				_ => Err(InvalidDateFormat)
			}
		} else {
			Err(InvalidDateFormat)
		}
	}

	## Create a `Date` object from the given days since the epoch.
	## Uses Howard Hinnant's Euclidean affine date algorithm.
	from_days_since_epoch : I64 -> Date
	from_days_since_epoch = |days_since_epoch| {
		# 1. Shift epoch from 1970-01-01 to 0000-03-01 (719,468 days)
		# Moving the year start to March 1 puts Leap Day (Feb 29) at the very end.
		z = days_since_epoch + 719468

		# 2. Split into 400-year Gregorian eras (146,097 days per era)
		era = if z >= 0 {
			z // 146097
		} else {
			(z - 146096) // 146097
		}

		# Day of era: [0, 146096]
		doe = z - era * 146097

		# Year of era: [0, 399]
		yoe = (doe - doe // 1460 + doe // 36524 - doe // 146096) // 365

		# Calendar year relative to a March 1 start
		y_march = yoe + era * 400

		# Day of year relative to March 1: [0, 365]
		doy = doe - (365 * yoe + yoe // 4 - yoe // 100)

		# 3. Affine transformation from day-of-year to month position [0, 11] (0 = Mar, 11 = Feb)
		mp = (5 * doy + 2) // 153

		# Day of month (1-indexed)
		day = doy - (153 * mp + 2) // 5 + 1

		# Convert month from March-based [0, 11] to standard [1, 12]
		month = if mp < 10 {
			mp + 3
		} else {
			mp - 9
		}

		# Adjust calendar year for January and February (which belong to the next calendar year)
		year = if month <= 2 {
			y_march + 1
		} else {
			y_march
		}

		from_ymd(
			year,
			month.to_u8_try() ?? {
				crash "Unreachable"
			},
			day.to_u8_try() ?? {
				crash "Unreachable"
			},
		)
	}

	## Create a `Date` object from the given nanoseconds since the epoch.
	from_nanos_since_epoch : I128 -> Date
	from_nanos_since_epoch = |nanos| {
		days = nanos.div_floor_by(Const.nanos_per_day.to_i128())
		from_days_since_epoch(
			days.to_i64_try() ?? {
				crash "Days overflow I64"
			},
		)
	}

	## Create a `Date` object from the given year and day of the year.
	from_yd : I64, U16 -> Date
	from_yd = |year, day_of_year| {
		from_ymd(year, 1, 1).add_days(day_of_year.to_i64() - 1)
	}

	## Create a `Date` object from the given year, month, and day of the month.
	from_ymd : I64, U8, U8 -> Date
	from_ymd = |year, month, day| {
		{ year, month, day_of_month: day, day_of_year: ymd_to_days_in_year(year, month, day) }
	}

	## Create a `Date` object from the given year and week.
	from_yw : I64, U8 -> Date
	from_yw = |year, week| {
		from_ywd(year, week, 1)
	}

	## Create a `Date` object from the given year, week, and day of the week.
	from_ywd : I64, U8, U8 -> Date
	from_ywd = |year, week, day| {
		days_in_year = if is_leap_year(year) {
			366
		} else {
			365
		}
		d = calendar_week_to_days_in_year(week, year) + day.to_i64()
		if d > days_in_year {
			from_yd(
				year + 1,
				(d - days_in_year).to_u16_try() ?? {
					crash "Unreachable"
				},
			)
		} else if d <= 0 {
			days_in_prev_year = if is_leap_year(year - 1) {
				366
			} else {
				365
			}
			from_yd(
				year - 1,
				(d + days_in_prev_year).to_u16_try() ?? {
					crash "Unreachable"
				},
			)
		} else {
			from_yd(
				year,
				d.to_u16_try() ?? {
					crash "Unreachable"
				},
			)
		}
	}

	## Check whether the given date falls in a leap year
	is_leap : Date -> Bool
	is_leap = |date| is_leap_year(date.year)

	## Subtract two `Date` objects to get the `Duration` between them.
	sub : Date, Date -> Duration
	sub = |a, b| {
		a_nanos = to_nanos_since_epoch(a)
		b_nanos = to_nanos_since_epoch(b)
		Duration.from_nanoseconds(a_nanos - b_nanos)
	}

	## Convert the given `Date` to an ISO 8601 string.
	to_iso_str : Date -> Str
	to_iso_str = |date| {
		Utils.expand_int_with_zeros(date.year, 4)
			.concat("-")
			.concat(Utils.expand_int_with_zeros(date.month.to_i64(), 2))
			.concat("-")
			.concat(Utils.expand_int_with_zeros(date.day_of_month.to_i64(), 2))
	}

	## Convert the `Date` to an ISO 8601 string as a list of UTF-8 bytes.
	to_iso_u8 : Date -> List(U8)
	to_iso_u8 = |date| to_iso_str(date).to_utf8()

	## Convert the given `Date` to nanoseconds since the epoch.
	to_nanos_since_epoch : Date -> I128
	to_nanos_since_epoch = |date| {
		days = num_days_since_epoch(date)
		days.to_i128() * Const.nanos_per_day.to_i128()
	}

	## `Date` object representing the Unix epoch (1970-01-01).
	unix_epoch : Date
	unix_epoch = { year: 1970, month: 1, day_of_month: 1, day_of_year: 1 }

	## Get the day of the week for a `Date` object (0 = Sunday, 6 = Saturday).
	weekday : Date -> U8
	weekday = |date| weekday_help(date.year, date.month, date.day_of_month)

	## Returns the number of days in the given month of the given year.
	days_in_month : I64, U8 -> U8
	days_in_month = |year, month| {
		Const.month_days({ month, is_leap: is_leap_year(year) }) ?? {
			crash "Invalid month: must be between 1 and 12"
		}
	}
}

## Check whether the given year is a leap year.
is_leap_year = |year| {
	(year % Const.leap_interval.to_i64() == 0 and year % Const.leap_exception.to_i64() != 0) or year % Const.leap_non_exception.to_i64() == 0
}

## Calculate the number of days since the epoch.
num_days_since_epoch : Date -> I64
num_days_since_epoch = |date| {
	days_to_start_of_year =
		(date.year - Const.epoch_year) * 365 + signed_leap_years_since_epoch(date.year)

	is_leap = is_leap_year(date.year)
	get_month_days = |m| Const.month_days({ month: m, is_leap }) ?? {
		crash "Unreachable"
	}

	days_in_prior_months = (1..<date.month).iter().map(|m| get_month_days(m).to_i64()).sum()
	days_to_start_of_year + days_in_prior_months + date.day_of_month.to_i64() - 1
}

## Calculate the number of days since the epoch until the given year.
num_days_since_epoch_until_year : I64 -> I64
num_days_since_epoch_until_year = |year| {
	num_days_since_epoch({ year, month: 1, day_of_month: 1, day_of_year: 1 })
}

## Computes the total number of leap years from year -infinity up to `y` (inclusive).
leaps_up_to : I64 -> I64
leaps_up_to = |y| {
	y.div_floor_by(4) - y.div_floor_by(100) + y.div_floor_by(400)
}

## Returns the signed offset of leap years strictly between the epoch and the start of `year`.
signed_leap_years_since_epoch : I64 -> I64
signed_leap_years_since_epoch = |year| {
	# We want leaps up to (year - 1), because we are calculating days to the *start* of `year`
	leaps_up_to(year - 1) - leaps_up_to(1970 - 1)
}

parse_calendar_date_century : List(U8) -> Try(Date, [InvalidDateFormat])
parse_calendar_date_century = |bytes| {
	match Utils.utf8_to_int_signed(bytes) {
		Ok(century) => Date.from_ymd(century * 100, 1, 1) |> Ok
		_ => Err(InvalidDateFormat)
	}
}

parse_calendar_date_year : List(U8) -> Try(Date, [InvalidDateFormat])
parse_calendar_date_year = |bytes| {
	match Utils.utf8_to_int_signed(bytes) {
		Ok(year) => Date.from_ymd(year, 1, 1) |> Ok
		_ => Err(InvalidDateFormat)
	}
}

parse_calendar_date_month : List(U8) -> Try(Date, [InvalidDateFormat])
parse_calendar_date_month = |bytes| {
	match Utils.split_at_indices(bytes, [4, 5]) {
		[year_bytes, _, month_bytes] => {
			match (Utils.utf8_to_int_signed(year_bytes), Utils.utf8_to_int(month_bytes)) {
				(Ok(year), Ok(month)) if month >= 1 and month <= 12 => {
					Date.from_ymd(
						year,
						month.to_u8_try() ?? {
							crash "Unreachable"
						},
						1,
					)
						|> Ok
				}
				_ => Err(InvalidDateFormat)
			}
		}
		_ => Err(InvalidDateFormat)
	}
}

parse_ordinal_date_basic : List(U8) -> Try(Date, [InvalidDateFormat])
parse_ordinal_date_basic = |bytes| {
	match Utils.split_at_indices(bytes, [4]) {
		[year_bytes, day_bytes] => {
			match (Utils.utf8_to_int_signed(year_bytes), Utils.utf8_to_int(day_bytes)) {
				(Ok(year), Ok(day)) if day >= 1 and day <= 366 => {
					Date.from_yd(
						year,
						day.to_u16_try() ?? {
							crash "Unreachable"
						},
					)
						|> Ok
				}
				_ => Err(InvalidDateFormat)
			}
		}
		_ => Err(InvalidDateFormat)
	}
}

parse_ordinal_date_extended : List(U8) -> Try(Date, [InvalidDateFormat])
parse_ordinal_date_extended = |bytes| {
	match Utils.split_at_indices(bytes, [4, 5]) {
		[year_bytes, _, day_bytes] => {
			match (Utils.utf8_to_int_signed(year_bytes), Utils.utf8_to_int(day_bytes)) {
				(Ok(year), Ok(day)) if day >= 1 and day <= 366 => {
					Date.from_yd(
						year,
						day.to_u16_try() ?? {
							crash "Unreachable"
						},
					)
						|> Ok
				}
				_ => Err(InvalidDateFormat)
			}
		}
		_ => Err(InvalidDateFormat)
	}
}

parse_week_date_reduced_basic : List(U8) -> Try(Date, [InvalidDateFormat])
parse_week_date_reduced_basic = |bytes| {
	match Utils.split_at_indices(bytes, [4, 5]) {
		[year_bytes, _, week_bytes] => {
			match (Utils.utf8_to_int(year_bytes), Utils.utf8_to_int(week_bytes)) {
				(Ok(year), Ok(week)) if year <= 9223372036854775807 and week >= 1 and week <= 52 => {
					Date.from_yw(
						year.to_i64_try() ?? {
							crash "Unreachable"
						},
						week.to_u8_try() ?? {
							crash "Unreachable"
						},
					)
						|> Ok
				}
				_ => Err(InvalidDateFormat)
			}
		}
		_ => Err(InvalidDateFormat)
	}
}

parse_week_date_reduced_extended : List(U8) -> Try(Date, [InvalidDateFormat])
parse_week_date_reduced_extended = |bytes| {
	match Utils.split_at_indices(bytes, [4, 6]) {
		[year_bytes, _, week_bytes] => {
			match (Utils.utf8_to_int(year_bytes), Utils.utf8_to_int(week_bytes)) {
				(Ok(year), Ok(week)) if year <= 9223372036854775807 and week >= 1 and week <= 52 => {
					Date.from_yw(
						year.to_i64_try() ?? {
							crash "Unreachable"
						},
						week.to_u8_try() ?? {
							crash "Unreachable"
						},
					)
						|> Ok
				}
				_ => Err(InvalidDateFormat)
			}
		}
		_ => Err(InvalidDateFormat)
	}
}

parse_week_date_basic : List(U8) -> Try(Date, [InvalidDateFormat])
parse_week_date_basic = |bytes| {
	match Utils.split_at_indices(bytes, [4, 5, 7]) {
		[year_bytes, _, week_bytes, day_bytes] => {
			match (Utils.utf8_to_int(year_bytes), Utils.utf8_to_int(week_bytes), Utils.utf8_to_int(day_bytes)) {
				(Ok(y), Ok(w), Ok(d)) if y <= 9223372036854775807 and w >= 1 and w <= 52 and d >= 1 and d <= 7 => {
					Date.from_ywd(
						y.to_i64_try() ?? {
							crash "Unreachable"
						},
						w.to_u8_try() ?? {
							crash "Unreachable"
						},
						d.to_u8_try() ?? {
							crash "Unreachable"
						},
					)
						|> Ok
				}
				_ => Err(InvalidDateFormat)
			}
		}
		_ => Err(InvalidDateFormat)
	}
}

parse_week_date_extended : List(U8) -> Try(Date, [InvalidDateFormat])
parse_week_date_extended = |bytes| {
	match Utils.split_at_indices(bytes, [4, 6, 8, 9]) {
		[year_bytes, _, week_bytes, _, day_bytes] => {
			match (Utils.utf8_to_int(year_bytes), Utils.utf8_to_int(week_bytes), Utils.utf8_to_int(day_bytes)) {
				(Ok(y), Ok(w), Ok(d)) if y <= 9223372036854775807 and w >= 1 and w <= 52 and d >= 1 and d <= 7 => {
					Date.from_ywd(
						y.to_i64_try() ?? {
							crash "Unreachable"
						},
						w.to_u8_try() ?? {
							crash "Unreachable"
						},
						d.to_u8_try() ?? {
							crash "Unreachable"
						},
					)
						|> Ok
				}
				_ => Err(InvalidDateFormat)
			}
		}
		_ => Err(InvalidDateFormat)
	}
}

parse_calendar_date_basic : List(U8) -> Try(Date, [InvalidDateFormat])
parse_calendar_date_basic = |bytes| {
	match Utils.split_at_indices(bytes, [4, 6]) {
		[year_bytes, month_bytes, day_bytes] => {
			match (Utils.utf8_to_int(year_bytes), Utils.utf8_to_int(month_bytes), Utils.utf8_to_int(day_bytes)) {
				(Ok(y), Ok(m), Ok(d)) if y <= 9223372036854775807 and m >= 1 and m <= 12 and d >= 1 and d <= 31 => {
					Date.from_ymd(
						y.to_i64_try() ?? {
							crash "Unreachable"
						},
						m.to_u8_try() ?? {
							crash "Unreachable"
						},
						d.to_u8_try() ?? {
							crash "Unreachable"
						},
					)
						|> Ok
				}
				_ => Err(InvalidDateFormat)
			}
		}
		_ => Err(InvalidDateFormat)
	}
}

parse_calendar_date_extended : List(U8) -> Try(Date, [InvalidDateFormat])
parse_calendar_date_extended = |bytes| {
	match Utils.split_at_indices(bytes, [4, 5, 7, 8]) {
		[year_bytes, _, month_bytes, _, day_bytes] => {
			match (Utils.utf8_to_int_signed(year_bytes), Utils.utf8_to_int(month_bytes), Utils.utf8_to_int(day_bytes)) {
				(Ok(y), Ok(m), Ok(d)) if y <= 9223372036854775807 and m >= 1 and m <= 12 and d >= 1 and d <= 31 => {
					Date.from_ymd(
						y.to_i64_try() ?? {
							crash "Unreachable"
						},
						m.to_u8_try() ?? {
							crash "Unreachable"
						},
						d.to_u8_try() ?? {
							crash "Unreachable"
						},
					)
						|> Ok
				}
				_ => Err(InvalidDateFormat)
			}
		}
		_ => Err(InvalidDateFormat)
	}
}

## Return the day of the week, from 0=Sunday to 6=Saturday
weekday_help : I64, U8, U8 -> U8
weekday_help = |year, month, day| {
	year2xxx = (year % 400) + 2400 # to handle years before the epoch
	date = Date.from_ymd(year2xxx, month, day)
	days_since_epoch = Date.to_nanos_since_epoch(date) // Const.nanos_per_day.to_i128()
	((days_since_epoch + 4) % 7).to_i64_wrap().to_u8_wrap()
}

## Convert the given year, month, and day of the month to the day of the year.
ymd_to_days_in_year : I64, U8, U8 -> U16
ymd_to_days_in_year = |year, month, day| {
	(1..<month).iter().map(|m| Date.days_in_month(year, m).to_u16()).sum() + day.to_u16()
}

# <===== TESTS ====>
# <---- add_days ---->
expect Date.add_days(Date.unix_epoch, 365) == Date.from_ymd(1971, 1, 1)
expect Date.add_days(Date.unix_epoch, (365 * 2)) == Date.from_ymd(1972, 1, 1)
expect Date.add_days(Date.unix_epoch, (365 * 2 + 366)) == Date.from_ymd(1973, 1, 1)
expect Date.add_days(Date.unix_epoch, -1) == Date.from_ymd(1969, 12, 31)
expect Date.add_days(Date.unix_epoch, -365) == Date.from_ymd(1969, 1, 1)
expect Date.add_days(Date.unix_epoch, (-365 - 1)) == Date.from_ymd(1968, 12, 31)
expect Date.add_days(Date.unix_epoch, (-365 - 366)) == Date.from_ymd(1968, 1, 1)

# <---- add_duration ---->
expect Date.add_duration(Date.unix_epoch, Duration.from_days(1)) == Date.from_ymd(1970, 1, 2)

# <---- add_months ---->
expect Date.add_months(Date.unix_epoch, 12) == Date.from_ymd(1971, 1, 1)
expect Date.add_months(Date.from_ymd(1970, 1, 31), 1) == Date.from_ymd(1970, 2, 28)
expect Date.add_months(Date.from_ymd(1972, 2, 29), 12) == Date.from_ymd(1973, 2, 28)

# <---- after ---->
expect {
	a = Date.from_yd(2025, 1)
	b = Date.from_yd(2025, 2)
	b.after(a)
}
expect {
	a = Date.from_yd(2025, 2)
	b = Date.from_yd(2025, 1)
	!(b.after(a))
}
expect {
	a = Date.from_yd(2025, 1)
	b = Date.from_yd(2025, 1)
	!(b.after(a))
}

# <---- before ---->
expect {
	a = Date.from_yd(2025, 1)
	b = Date.from_yd(2025, 2)
	a.before(b)
}
expect {
	a = Date.from_yd(2025, 2)
	b = Date.from_yd(2025, 1)
	!(a.before(b))
}
expect {
	a = Date.from_yd(2025, 1)
	b = Date.from_yd(2025, 1)
	!(a.before(b))
}

# <---- calendar_week_to_days_in_year ---->
expect Date.calendar_week_to_days_in_year(1, 1965) == 3
expect Date.calendar_week_to_days_in_year(1, 1964) == 0
expect Date.calendar_week_to_days_in_year(1, 1970) == 0
expect Date.calendar_week_to_days_in_year(1, 1971) == 3

expect Date.calendar_week_to_days_in_year(1, 1972) == 2
expect Date.calendar_week_to_days_in_year(1, 1973) == 0
expect Date.calendar_week_to_days_in_year(2, 2024) == 7

# <---- days_in_month ---->
expect Date.days_in_month(1969, 1) == 31
expect Date.days_in_month(1969, 2) == 28
expect Date.days_in_month(1969, 3) == 31
expect Date.days_in_month(1969, 4) == 30
expect Date.days_in_month(1969, 5) == 31
expect Date.days_in_month(1969, 6) == 30
expect Date.days_in_month(1969, 7) == 31
expect Date.days_in_month(1969, 8) == 31
expect Date.days_in_month(1969, 9) == 30
expect Date.days_in_month(1969, 10) == 31
expect Date.days_in_month(1969, 11) == 30
expect Date.days_in_month(1969, 12) == 31
expect Date.days_in_month(2024, 2) == 29

# <---- equal ---->
expect {
	a = Date.from_yd(2025, 1)
	b = Date.from_yd(2025, 1)
	a.equal(b)
}
expect {
	a = Date.from_yd(2025, 2)
	b = Date.from_yd(2025, 1)
	!(a.equal(b))
}
expect {
	a = Date.from_yd(2025, 1)
	b = Date.from_yd(2025, 2)
	!(a.equal(b))
}

# <---- format ---->
expect {
	date = Date.from_ymd(2024, 12, 31)
	Date.format(date, "{YYYY}-{MM}-{DD}") == "2024-12-31" and
		Date.format(date, "{MM}/{DD}/{YYYY}") == "12/31/2024" and
			Date.format(date, "{YY}-{MM}-{DD}") == "24-12-31" and
				Date.format(date, "{M}/{D}/{YYYY}") == "12/31/2024" and
					Date.format(date, "{M}/{D}/{YY}") == "12/31/24"
}

expect {
	date = Date.unix_epoch
	Date.format(date, "{YYYY}-{MM}-{DD}") == "1970-01-01" and
		Date.format(date, "{MM}/{DD}/{YYYY}") == "01/01/1970" and
			Date.format(date, "{YY}-{MM}-{DD}") == "70-01-01" and
				Date.format(date, "{M}/{D}/{YYYY}") == "1/1/1970" and
					Date.format(date, "{M}/{D}/{YY}") == "1/1/70"
}

# <---- from_nanos_since_epoch ---->
expect Date.from_nanos_since_epoch(0) == { year: 1970, month: 1, day_of_month: 1, day_of_year: 1 }
expect Date.from_nanos_since_epoch((Const.nanos_per_day.to_i128() * 365)) == { year: 1971, month: 1, day_of_month: 1, day_of_year: 1 }
expect Date.from_nanos_since_epoch((Const.nanos_per_day.to_i128() * 365 * 2 + Const.nanos_per_day.to_i128() * 366)) == { year: 1973, month: 1, day_of_month: 1, day_of_year: 1 }
expect Date.from_nanos_since_epoch(-Const.nanos_per_day.to_i128()) == { year: 1969, month: 12, day_of_month: 31, day_of_year: 365 }
expect Date.from_nanos_since_epoch(((-Const.nanos_per_day.to_i128()) * 365)) == { year: 1969, month: 1, day_of_month: 1, day_of_year: 1 }
expect Date.from_nanos_since_epoch(((-Const.nanos_per_day.to_i128()) * 365 - Const.nanos_per_day.to_i128() * 366)) == { year: 1968, month: 1, day_of_month: 1, day_of_year: 1 }
expect Date.from_nanos_since_epoch(-1.I128) == { year: 1969, month: 12, day_of_month: 31, day_of_year: 365 }

# <---- from_yd ---->
expect Date.from_yd(1970, 1) == { year: 1970, month: 1, day_of_month: 1, day_of_year: 1 }
expect Date.from_yd(1970, 31) == { year: 1970, month: 1, day_of_month: 31, day_of_year: 31 }
expect Date.from_yd(1970, 32) == { year: 1970, month: 2, day_of_month: 1, day_of_year: 32 }
expect Date.from_yd(1970, 60) == { year: 1970, month: 3, day_of_month: 1, day_of_year: 60 }
expect Date.from_yd(1972, 61) == { year: 1972, month: 3, day_of_month: 1, day_of_year: 61 }

# <---- from_ymd ---->
expect Date.from_ymd(1970, 1, 1) == { year: 1970, month: 1, day_of_month: 1, day_of_year: 1 }
expect Date.from_ymd(1970, 12, 31) == { year: 1970, month: 12, day_of_month: 31, day_of_year: 365 }
expect Date.from_ymd(1972, 3, 1) == { year: 1972, month: 3, day_of_month: 1, day_of_year: 61 }

# <---- from_yw ---->
expect Date.from_yw(1970, 1) == { year: 1970, month: 1, day_of_month: 1, day_of_year: 1 }
expect Date.from_yw(1971, 1) == { year: 1971, month: 1, day_of_month: 4, day_of_year: 4 }

# <---- from_ywd ---->
expect Date.from_ywd(1970, 1, 1) == { year: 1970, month: 1, day_of_month: 1, day_of_year: 1 }
expect Date.from_ywd(1970, 52, 5) == { year: 1971, month: 1, day_of_month: 1, day_of_year: 1 }

# <---- num_days_since_epoch ---->
expect num_days_since_epoch(Date.from_ymd(2024, 1, 1)) == 19723 # Removed due to compiler bug with optional record fields
expect num_days_since_epoch(Date.from_ymd(1970, 12, 31)) == 365 - 1
expect num_days_since_epoch(Date.from_ymd(1971, 1, 2)) == 365 + 1
expect num_days_since_epoch(Date.from_ymd(2024, 1, 1)) == 19723
expect num_days_since_epoch(Date.from_ymd(2024, 2, 1)) == 19723 + 31
expect num_days_since_epoch(Date.from_ymd(2024, 12, 31)) == 19723 + 366 - 1
expect num_days_since_epoch(Date.from_ymd(1969, 12, 31)) == -1
expect num_days_since_epoch(Date.from_ymd(1969, 12, 30)) == -2
expect num_days_since_epoch(Date.from_ymd(1969, 1, 1)) == -365
expect num_days_since_epoch(Date.from_ymd(1968, 1, 1)) == -365 - 366

# <---- num_days_since_epoch_until_year ---->
expect num_days_since_epoch_until_year(1968) == -365 - 366
expect num_days_since_epoch_until_year(1970) == 0
expect num_days_since_epoch_until_year(1971) == 365
expect num_days_since_epoch_until_year(1972) == 365 + 365
expect num_days_since_epoch_until_year(1973) == 365 + 365 + 366
expect num_days_since_epoch_until_year(2024) == 19723

# <---- sub ---->
expect Date.sub(Date.from_ymd(2025, 1, 1), Date.from_ymd(2025, 1, 2)) == Duration.from_days(-1.I128)
expect Date.sub(Date.from_ymd(1970, 1, 1), Date.from_ymd(1968, 1, 1)) == Duration.from_days(731.I128)

# <---- to_nanos_since_epoch ---->
expect Date.to_nanos_since_epoch({ year: 1970, month: 1, day_of_month: 1, day_of_year: 1 }) == 0
expect Date.to_nanos_since_epoch({ year: 1970, month: 12, day_of_month: 31, day_of_year: 365 }) == Const.nanos_per_hour.to_i128() * 24 * 364
expect Date.to_nanos_since_epoch({ year: 1973, month: 1, day_of_month: 1, day_of_year: 1 }) == Const.nanos_per_hour.to_i128() * 24 * 365 * 2 + Const.nanos_per_hour.to_i128() * 24 * 366
expect Date.to_nanos_since_epoch({ year: 1969, month: 12, day_of_month: 31, day_of_year: 365 }) == Const.nanos_per_hour.to_i128() * 24 * (-1)
expect Date.to_nanos_since_epoch({ year: 1969, month: 1, day_of_month: 1, day_of_year: 1 }) == Const.nanos_per_hour.to_i128() * 24 * (-365)
expect Date.to_nanos_since_epoch({ year: 1968, month: 1, day_of_month: 1, day_of_year: 1 }) == Const.nanos_per_hour.to_i128() * 24 * (-365) - Const.nanos_per_hour.to_i128() * 24 * 366

# <---- to_iso_str ---->
expect Date.to_iso_str(Date.unix_epoch) == "1970-01-01"

# <---- weekday_help ---->
expect weekday_help(1964, 10, 10) == 6
expect weekday_help(1964, 10, 11) == 0
expect weekday_help(1964, 10, 12) == 1
expect weekday_help(2024, 10, 12) == 6

# <---- ymd_to_days_in_year ---->
expect ymd_to_days_in_year(1970, 1, 1) == 1
expect ymd_to_days_in_year(1970, 12, 31) == 365
expect ymd_to_days_in_year(1972, 3, 1) == 61
