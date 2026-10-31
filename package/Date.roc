## The Date module provides the `Date` type, including various functions for working with dates.
##
## These functions include functions for creating dates from various numeric values, converting dates to and from ISO 8601 strings, and performing arithmetic operations on dates.
import Const
import Duration
import Month
import Utils

## ```
## Date :: {
##     year: I64,
##     month: Month,
##     day_of_month: U8,
##     day_of_year: U16
## }
## ```
## A `Date` can represent any year from -999,999,999 to 999,999,999 (see [`lowest`](Date#lowest) and [`highest`](Date#highest)).
## Date arithmetic and conversions from days or nanoseconds since the epoch saturate to those bounds rather than overflowing.
Date :: {
	year : I64,
	month : Month,
	day_of_month : U8,
	day_of_year : U16,
}.{

	## Are two Dates equal?
	is_eq : Date, Date -> Bool
	is_eq = |a, b| a.year == b.year and a.day_of_year == b.day_of_year

	## The year of the `Date`.
	year : Date -> I64
	year = |date| date.year

	## The month of the `Date`.
	month : Date -> Month
	month = |date| date.month

	## The day of the month, from 1 to 31.
	day_of_month : Date -> U8
	day_of_month = |date| date.day_of_month

	## The day of the year, from 1 to 366.
	day_of_year : Date -> U16
	day_of_year = |date| date.day_of_year

	## Same as [`add_duration`](Date#add_duration).
	add : Date, Duration -> Date
	add = add_duration

	## Add the given number of days to the given `Date`.
	add_days : Date, I64 -> Date
	add_days = |date, days| {
		from_days_since_epoch(num_days_since_epoch(date).plus_saturated(days))
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
		total_months = date.year.times_saturated(12).plus_saturated(date.month.to_u8().to_i64() - 1).plus_saturated(months)
		new_year = total_months.div_floor_by(12)
		if new_year > Const.max_year {
			highest
		} else if new_year < Const.min_year {
			lowest
		} else {
			# Floor division guarantees the remainder is 0..11, so this is always a valid month number.
			new_month = Month.from_u8((total_months - new_year * 12).to_u8_wrap() + 1) ?? {
				crash "Unreachable"
			}
			days_in_new_month = days_in_month(new_year, new_month)
			new_day =
				if date.day_of_month > days_in_new_month {
					days_in_new_month
				} else {
					date.day_of_month
				}
			unchecked_ymd(new_year, new_month, new_day)
		}
	}

	## Add the given number of years to the given `Date`.
	add_years : Date, I64 -> Date
	add_years = |date, years| {
		date.add_months(years.times_saturated(12))
	}

	## Determine if the first `Date` falls after the second `Date`.
	after : Date, Date -> Bool
	after = |a, b| a.order_relative_to(b) == After

	## Determine if the first `Date` falls before the second `Date`.
	before : Date, Date -> Bool
	before = |a, b| a.order_relative_to(b) == Before

	## Convert the given calendar week and year to the day of the year.
	calendar_week_to_days_in_year : U8, I64 -> I64
	calendar_week_to_days_in_year = |week, y| {
		# Week 1 of a year is the first week with a majority of its days in that year
		# https://en.wikipedia.org/wiki/ISO_week_date#First_week
		w = week.to_i64()
		days_since_epoch = num_days_since_epoch_until_year(y)
		length_of_maybe_first_week =
			if y >= Const.epoch_year {
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
			.replace_first("{MM}", Utils.expand_int_with_zeros(date.month.to_u8().to_i64(), 2))
			.replace_first("{M}", date.month.to_u8().to_str())
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
		# 0. Saturate to the supported range so none of the arithmetic below can overflow.
		days = clamp_days(days_since_epoch)

		# 1. Shift epoch from 1970-01-01 to 0000-03-01 (719,468 days)
		# Moving the year start to March 1 puts Leap Day (Feb 29) at the very end.
		z = days + 719468

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
		m = if mp < 10 {
			mp + 3
		} else {
			mp - 9
		}

		# Adjust calendar year for January and February (which belong to the next calendar year)
		y = if m <= 2 {
			y_march + 1
		} else {
			y_march
		}

		unchecked_ymd(
			y,
			# The affine transform above always yields a month in 1..12.
			Month.from_u8(m.to_u8_wrap()) ?? {
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
		clamped =
			if days < min_days_since_epoch.to_i128() {
				min_days_since_epoch
			} else if days > max_days_since_epoch.to_i128() {
				max_days_since_epoch
			} else {
				# Exact: the value is within the I64 bounds checked above.
				days.to_i64_wrap()
			}
		from_days_since_epoch(clamped)
	}

	## Create a `Date` object from the given year and day of the year (1 to 365, or 366 in a leap year).
	## Returns `Err(YearOutOfRange)` if the year is outside the supported range, or `Err(InvalidDayOfYear)` if the day is 0 or past the end of the year.
	from_yd : I64, U16 -> Try(Date, [YearOutOfRange, InvalidDayOfYear])
	from_yd = |y, doy| {
		check_year(y)?
		if doy == 0 or doy > days_in_year(y) {
			Err(InvalidDayOfYear)
		} else {
			Ok(unchecked_ymd(y, Jan, 1).add_days(doy.to_i64() - 1))
		}
	}

	## Create a `Date` object from the given year, month, and day of the month.
	## Returns `Err(YearOutOfRange)` if the year is outside the supported range, or `Err(InvalidDayOfMonth)` if the day is 0 or past the end of that month.
	from_ymd : I64, Month, U8 -> Try(Date, [YearOutOfRange, InvalidDayOfMonth])
	from_ymd = |y, m, d| {
		check_year(y)?
		if d == 0 or d > days_in_month(y, m) {
			Err(InvalidDayOfMonth)
		} else {
			Ok(unchecked_ymd(y, m, d))
		}
	}

	## Create a `Date` object from the given year and ISO week, on the first day of that week.
	## Returns `Err(YearOutOfRange)` if the year is outside the supported range, or `Err(InvalidWeek)` if the week is 0 or past the last week of the year (see [`weeks_in_year`](Date#weeks_in_year)).
	from_yw : I64, U8 -> Try(Date, [YearOutOfRange, InvalidWeek])
	from_yw = |y, week| {
		check_year(y)?
		check_week(y, week)?
		Ok(unchecked_ywd(y, week, 1))
	}

	## Create a `Date` object from the given year, ISO week, and day of the week (1 = Monday, 7 = Sunday).
	## Returns `Err(YearOutOfRange)` if the year is outside the supported range, `Err(InvalidWeek)` if the week is 0 or past the last week of the year, or `Err(InvalidWeekday)` if the day is not 1 to 7.
	from_ywd : I64, U8, U8 -> Try(Date, [YearOutOfRange, InvalidWeek, InvalidWeekday])
	from_ywd = |y, week, day| {
		check_year(y)?
		check_week(y, week)?
		if day == 0 or day > 7 {
			Err(InvalidWeekday)
		} else {
			Ok(unchecked_ywd(y, week, day))
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
			.concat(Utils.expand_int_with_zeros(date.month.to_u8().to_i64(), 2))
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
	unix_epoch = { year: 1970, month: Jan, day_of_month: 1, day_of_year: 1 }

	## The latest `Date` that can be represented: 999999999-12-31.
	highest : Date
	highest = unchecked_ymd(Const.max_year, Dec, 31)

	## The earliest `Date` that can be represented: -999999999-01-01.
	lowest : Date
	lowest = unchecked_ymd(Const.min_year, Jan, 1)

	## Get the day of the week for a `Date` object (0 = Sunday, 6 = Saturday).
	weekday : Date -> U8
	weekday = |date| weekday_help(date.year, date.month, date.day_of_month)

	## Returns the number of days in the given month of the given year.
	days_in_month : I64, Month -> U8
	days_in_month = |y, m| m.days({ is_leap: is_leap_year(y) })

	## Returns the number of days in the given year: 366 in a leap year, otherwise 365.
	days_in_year : I64 -> U16
	days_in_year = |y| if is_leap_year(y) {
		366
	} else {
		365
	}

	## Returns the number of ISO weeks in the given year: 53 if the year starts on a Thursday,
	## or is a leap year starting on a Wednesday; otherwise 52.
	weeks_in_year : I64 -> U8
	weeks_in_year = |y| {
		jan_1_weekday = weekday_help(y, Jan, 1)
		if jan_1_weekday == 4 or (jan_1_weekday == 3 and is_leap_year(y)) {
			53
		} else {
			52
		}
	}
}

## Build a `Date` from components already known to be valid. Only for internal use:
## every public constructor validates before calling this.
unchecked_ymd : I64, Month, U8 -> Date
unchecked_ymd = |y, m, d| {
	{ year: y, month: m, day_of_month: d, day_of_year: ymd_to_days_in_year(y, m, d) }
}

## Build a `Date` from a year, week, and weekday already known to be valid.
## Weeks that begin in the previous year or end in the next one resolve to the correct neighbouring date.
unchecked_ywd : I64, U8, U8 -> Date
unchecked_ywd = |y, week, day| {
	unchecked_ymd(y, Jan, 1).add_days(Date.calendar_week_to_days_in_year(week, y) + day.to_i64() - 1)
}

check_year : I64 -> Try({}, [YearOutOfRange])
check_year = |y| {
	if y < Const.min_year or y > Const.max_year {
		Err(YearOutOfRange)
	} else {
		Ok({})
	}
}

check_week : I64, U8 -> Try({}, [InvalidWeek])
check_week = |y, week| {
	if week == 0 or week > Date.weeks_in_year(y) {
		Err(InvalidWeek)
	} else {
		Ok({})
	}
}

## Collapse any constructor error into the parser's `InvalidDateFormat`.
or_invalid_format : Try(Date, _) -> Try(Date, [InvalidDateFormat])
or_invalid_format = |result| {
	match result {
		Ok(date) => Ok(date)
		Err(_) => Err(InvalidDateFormat)
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
	days_in_prior_months = months_before(date.month).map(
		|m| m.days({ is_leap: is_leap }).to_i64(),
	).sum()
	days_to_start_of_year + days_in_prior_months + date.day_of_month.to_i64() - 1
}

## Calculate the number of days since the epoch until the given year.
num_days_since_epoch_until_year : I64 -> I64
num_days_since_epoch_until_year = |year| {
	num_days_since_epoch({ year, month: Jan, day_of_month: 1, day_of_year: 1 })
}

## Days since the epoch of [`Date.highest`](Date#highest).
max_days_since_epoch : I64
max_days_since_epoch = num_days_since_epoch(Date.highest)

## Days since the epoch of [`Date.lowest`](Date#lowest).
min_days_since_epoch : I64
min_days_since_epoch = num_days_since_epoch(Date.lowest)

## Clamp a day count into the range `Date` supports.
clamp_days : I64 -> I64
clamp_days = |days| {
	if days < min_days_since_epoch {
		min_days_since_epoch
	} else if days > max_days_since_epoch {
		max_days_since_epoch
	} else {
		days
	}
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
		Ok(century) => Date.from_ymd(century * 100, Jan, 1) |> or_invalid_format
		_ => Err(InvalidDateFormat)
	}
}

parse_calendar_date_year : List(U8) -> Try(Date, [InvalidDateFormat])
parse_calendar_date_year = |bytes| {
	match Utils.utf8_to_int_signed(bytes) {
		Ok(year) => Date.from_ymd(year, Jan, 1) |> or_invalid_format
		_ => Err(InvalidDateFormat)
	}
}

parse_calendar_date_month : List(U8) -> Try(Date, [InvalidDateFormat])
parse_calendar_date_month = |bytes| {
	match Utils.split_at_indices(bytes, [4, 5]) {
		[year_bytes, _, month_bytes] => {
			match (Utils.utf8_to_int_signed(year_bytes), parse_month(month_bytes)) {
				(Ok(year), Ok(month)) => Date.from_ymd(year, month, 1) |> or_invalid_format
				_ => Err(InvalidDateFormat)
			}
		}
		_ => Err(InvalidDateFormat)
	}
}

## Parse a two-digit month, rejecting anything outside 1..12.
parse_month : List(U8) -> Try(Month, [InvalidDateFormat])
parse_month = |bytes| {
	match Utils.utf8_to_int(bytes) {
		Ok(n) if n <= 12 => {
			match Month.from_u8(n.to_u8_wrap()) {
				Ok(month) => Ok(month)
				Err(InvalidMonth) => Err(InvalidDateFormat)
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
				# Three day digits always fit in a U16; the constructor validates the range.
				(Ok(year), Ok(day)) => Date.from_yd(year, day.to_u16_wrap()) |> or_invalid_format
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
				# Three day digits always fit in a U16; the constructor validates the range.
				(Ok(year), Ok(day)) => Date.from_yd(year, day.to_u16_wrap()) |> or_invalid_format
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
				# Four year digits and two week digits always fit; the constructor validates the range.
				(Ok(year), Ok(week)) => Date.from_yw(year.to_i64_wrap(), week.to_u8_wrap()) |> or_invalid_format
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
				# Four year digits and two week digits always fit; the constructor validates the range.
				(Ok(year), Ok(week)) => Date.from_yw(year.to_i64_wrap(), week.to_u8_wrap()) |> or_invalid_format
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
				# Four year digits, two week digits, and one day digit always fit; the constructor validates the range.
				(Ok(y), Ok(w), Ok(d)) => Date.from_ywd(y.to_i64_wrap(), w.to_u8_wrap(), d.to_u8_wrap()) |> or_invalid_format
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
				# Four year digits, two week digits, and one day digit always fit; the constructor validates the range.
				(Ok(y), Ok(w), Ok(d)) => Date.from_ywd(y.to_i64_wrap(), w.to_u8_wrap(), d.to_u8_wrap()) |> or_invalid_format
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
			match (Utils.utf8_to_int(year_bytes), parse_month(month_bytes), Utils.utf8_to_int(day_bytes)) {
				# Four year digits and two day digits always fit; the constructor validates the range.
				(Ok(y), Ok(m), Ok(d)) => Date.from_ymd(y.to_i64_wrap(), m, d.to_u8_wrap()) |> or_invalid_format
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
			match (Utils.utf8_to_int_signed(year_bytes), parse_month(month_bytes), Utils.utf8_to_int(day_bytes)) {
				# Two day digits always fit in a U8; the constructor validates the range.
				(Ok(y), Ok(m), Ok(d)) => Date.from_ymd(y, m, d.to_u8_wrap()) |> or_invalid_format
				_ => Err(InvalidDateFormat)
			}
		}
		_ => Err(InvalidDateFormat)
	}
}

## Return the day of the week, from 0=Sunday to 6=Saturday
weekday_help : I64, Month, U8 -> U8
weekday_help = |year, month, day| {
	year2xxx = (year % 400) + 2400 # to handle years before the epoch
	date = unchecked_ymd(year2xxx, month, day)
	days_since_epoch = Date.to_nanos_since_epoch(date) // Const.nanos_per_day.to_i128()
	((days_since_epoch + 4) % 7).to_i64_wrap().to_u8_wrap()
}

## Convert the given year, month, and day of the month to the day of the year.
ymd_to_days_in_year : I64, Month, U8 -> U16
ymd_to_days_in_year = |year, month, day| {
	months_before(month).map(|m| Date.days_in_month(year, m).to_u16()).sum() + day.to_u16()
}

## All months of the year that come before the given month.
months_before : Month -> List(Month)
months_before = |month| Month.all.take_first(month.to_u8().to_u64() - 1)

# <===== TESTS ====>
# <---- add_days ---->
expect Date.add_days(Date.unix_epoch, 365) == Date.from_ymd(1971, Jan, 1)?
expect Date.add_days(Date.unix_epoch, (365 * 2)) == Date.from_ymd(1972, Jan, 1)?
expect Date.add_days(Date.unix_epoch, (365 * 2 + 366)) == Date.from_ymd(1973, Jan, 1)?
expect Date.add_days(Date.unix_epoch, -1) == Date.from_ymd(1969, Dec, 31)?
expect Date.add_days(Date.unix_epoch, -365) == Date.from_ymd(1969, Jan, 1)?
expect Date.add_days(Date.unix_epoch, (-365 - 1)) == Date.from_ymd(1968, Dec, 31)?
expect Date.add_days(Date.unix_epoch, (-365 - 366)) == Date.from_ymd(1968, Jan, 1)?

expect Date.add_days(Date.unix_epoch, I64.highest) == Date.highest
expect Date.add_days(Date.unix_epoch, I64.lowest) == Date.lowest
expect Date.add_days(Date.highest, 1) == Date.highest
expect Date.add_days(Date.lowest, -1) == Date.lowest
expect Date.add_days(Date.highest, -1) == Date.from_ymd(Const.max_year, Dec, 30)?
expect Date.add_days(Date.lowest, 1) == Date.from_ymd(Const.min_year, Jan, 2)?

# <---- add_duration ---->
expect Date.add_duration(Date.unix_epoch, Duration.from_days(1)) == Date.from_ymd(1970, Jan, 2)?
expect Date.add_duration(Date.unix_epoch, Duration.from_days(I128.highest)) == Date.highest
expect Date.add_duration(Date.unix_epoch, Duration.from_days(I128.lowest)) == Date.lowest

# <---- add_months ---->
expect Date.add_months(Date.unix_epoch, 12) == Date.from_ymd(1971, Jan, 1)?
expect Date.add_months(Date.from_ymd(1970, Jan, 31)?, 1) == Date.from_ymd(1970, Feb, 28)?
expect Date.add_months(Date.from_ymd(1972, Feb, 29)?, 12) == Date.from_ymd(1973, Feb, 28)?
expect Date.add_months(Date.from_ymd(2024, Jan, 31)?, -1) == Date.from_ymd(2023, Dec, 31)?
expect Date.add_months(Date.from_ymd(2024, Jan, 31)?, -11) == Date.from_ymd(2023, Feb, 28)?
expect Date.add_months(Date.from_ymd(2024, Mar, 31)?, 25) == Date.from_ymd(2026, Apr, 30)?
expect Date.add_months(Date.from_ymd(2024, Mar, 15)?, -27) == Date.from_ymd(2021, Dec, 15)?
expect Month.all.map(|m| Date.add_months(unchecked_ymd(2024, m, 1), 12)) == Month.all.map(|m| unchecked_ymd(2025, m, 1))
expect Month.all.map(|m| Date.add_months(unchecked_ymd(2024, m, 1), -12)) == Month.all.map(|m| unchecked_ymd(2023, m, 1))
expect Date.add_months(Date.unix_epoch, I64.highest) == Date.highest
expect Date.add_months(Date.unix_epoch, I64.lowest) == Date.lowest
expect Date.add_months(Date.highest, 1) == Date.highest
expect Date.add_months(Date.lowest, -1) == Date.lowest
expect Date.add_months(Date.highest, -1) == Date.from_ymd(Const.max_year, Nov, 30)?
expect Date.add_years(Date.unix_epoch, I64.highest) == Date.highest
expect Date.add_years(Date.unix_epoch, I64.lowest) == Date.lowest
expect Date.add_years(Date.highest, -1) == Date.from_ymd(Const.max_year - 1, Dec, 31)?

# <---- after ---->
expect {
	a = Date.from_yd(2025, 1)?
	b = Date.from_yd(2025, 2)?
	b.after(a)
}
expect {
	a = Date.from_yd(2025, 2)?
	b = Date.from_yd(2025, 1)?
	!(b.after(a))
}
expect {
	a = Date.from_yd(2025, 1)?
	b = Date.from_yd(2025, 1)?
	!(b.after(a))
}

# <---- before ---->
expect {
	a = Date.from_yd(2025, 1)?
	b = Date.from_yd(2025, 2)?
	a.before(b)
}
expect {
	a = Date.from_yd(2025, 2)?
	b = Date.from_yd(2025, 1)?
	!(a.before(b))
}
expect {
	a = Date.from_yd(2025, 1)?
	b = Date.from_yd(2025, 1)?
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

# <---- year / month / day_of_month / day_of_year ---->
expect {
	date = Date.from_ymd(2024, Feb, 29)?
	date.year() == 2024 and date.month() == Feb and date.day_of_month() == 29 and date.day_of_year() == 60
}
expect {
	date = Date.from_ymd(1969, Dec, 31)?
	date.year() == 1969 and date.month() == Dec and date.day_of_month() == 31 and date.day_of_year() == 365
}
expect Date.unix_epoch.year() == 1970 and Date.unix_epoch.month() == Jan and Date.unix_epoch.day_of_month() == 1 and Date.unix_epoch.day_of_year() == 1
expect Month.all.map(|m| unchecked_ymd(2023, m, 7).month()) == Month.all

# <---- days_in_month ---->
expect Date.days_in_month(1969, Jan) == 31
expect Date.days_in_month(1969, Feb) == 28
expect Date.days_in_month(1969, Mar) == 31
expect Date.days_in_month(1969, Apr) == 30
expect Date.days_in_month(1969, May) == 31
expect Date.days_in_month(1969, Jun) == 30
expect Date.days_in_month(1969, Jul) == 31
expect Date.days_in_month(1969, Aug) == 31
expect Date.days_in_month(1969, Sep) == 30
expect Date.days_in_month(1969, Oct) == 31
expect Date.days_in_month(1969, Nov) == 30
expect Date.days_in_month(1969, Dec) == 31
expect Date.days_in_month(2024, Feb) == 29
expect Month.all.map(|m| Date.days_in_month(2024, m).to_u16()).sum() == 366
expect Month.all.map(|m| Date.days_in_month(2023, m).to_u16()).sum() == 365
expect Month.all.map(|m| Date.days_in_month(1900, m).to_u16()).sum() == 365
expect Month.all.map(|m| Date.days_in_month(2000, m).to_u16()).sum() == 366

# <---- days_in_year ---->
expect Date.days_in_year(2024) == 366
expect Date.days_in_year(2023) == 365
expect Date.days_in_year(1900) == 365
expect Date.days_in_year(2000) == 366

# <---- weeks_in_year ---->
expect Date.weeks_in_year(2015) == 53 # starts on a Thursday
expect Date.weeks_in_year(2020) == 53 # leap year starting on a Wednesday
expect Date.weeks_in_year(2026) == 53 # starts on a Thursday
expect Date.weeks_in_year(2023) == 52
expect Date.weeks_in_year(2024) == 52
expect Date.weeks_in_year(2025) == 52
expect Date.weeks_in_year(1970) == 53 # starts on a Thursday

# <---- equal ---->
expect {
	a = Date.from_yd(2025, 1)?
	b = Date.from_yd(2025, 1)?
	a.equal(b)
}
expect {
	a = Date.from_yd(2025, 2)?
	b = Date.from_yd(2025, 1)?
	!(a.equal(b))
}
expect {
	a = Date.from_yd(2025, 1)?
	b = Date.from_yd(2025, 2)?
	!(a.equal(b))
}

# <---- format ---->
expect {
	date = Date.from_ymd(2024, Dec, 31)?
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

# <---- from_days_since_epoch ---->
expect Date.from_days_since_epoch(I64.highest) == Date.highest
expect Date.from_days_since_epoch(I64.lowest) == Date.lowest
expect Date.from_days_since_epoch(max_days_since_epoch) == Date.highest
expect Date.from_days_since_epoch(max_days_since_epoch + 1) == Date.highest
expect Date.from_days_since_epoch(min_days_since_epoch) == Date.lowest
expect Date.from_days_since_epoch(min_days_since_epoch - 1) == Date.lowest
expect Month.all.map(|m| Date.from_days_since_epoch(num_days_since_epoch(unchecked_ymd(2023, m, 15)))) == Month.all.map(|m| unchecked_ymd(2023, m, 15))
expect Month.all.map(|m| Date.from_days_since_epoch(num_days_since_epoch(unchecked_ymd(1969, m, 1)))) == Month.all.map(|m| unchecked_ymd(1969, m, 1))
expect Date.from_days_since_epoch(num_days_since_epoch(Date.from_ymd(2024, Feb, 29)?)) == Date.from_ymd(2024, Feb, 29)?
expect Date.from_days_since_epoch(num_days_since_epoch(Date.from_ymd(2024, Dec, 31)?)) == Date.from_ymd(2024, Dec, 31)?
expect Date.from_days_since_epoch(num_days_since_epoch(Date.from_ymd(2025, Jan, 1)?)) == Date.from_ymd(2025, Jan, 1)?

# <---- from_nanos_since_epoch ---->
expect Date.from_nanos_since_epoch(0) == { year: 1970, month: Jan, day_of_month: 1, day_of_year: 1 }
expect Date.from_nanos_since_epoch((Const.nanos_per_day.to_i128() * 365)) == { year: 1971, month: Jan, day_of_month: 1, day_of_year: 1 }
expect Date.from_nanos_since_epoch((Const.nanos_per_day.to_i128() * 365 * 2 + Const.nanos_per_day.to_i128() * 366)) == { year: 1973, month: Jan, day_of_month: 1, day_of_year: 1 }
expect Date.from_nanos_since_epoch(-Const.nanos_per_day.to_i128()) == { year: 1969, month: Dec, day_of_month: 31, day_of_year: 365 }
expect Date.from_nanos_since_epoch(((-Const.nanos_per_day.to_i128()) * 365)) == { year: 1969, month: Jan, day_of_month: 1, day_of_year: 1 }
expect Date.from_nanos_since_epoch(((-Const.nanos_per_day.to_i128()) * 365 - Const.nanos_per_day.to_i128() * 366)) == { year: 1968, month: Jan, day_of_month: 1, day_of_year: 1 }
expect Date.from_nanos_since_epoch(-1.I128) == { year: 1969, month: Dec, day_of_month: 31, day_of_year: 365 }
expect Date.from_nanos_since_epoch(I128.highest) == Date.highest
expect Date.from_nanos_since_epoch(I128.lowest) == Date.lowest
expect Date.from_nanos_since_epoch(Date.to_nanos_since_epoch(Date.highest)) == Date.highest
expect Date.from_nanos_since_epoch(Date.to_nanos_since_epoch(Date.lowest)) == Date.lowest
expect Date.from_nanos_since_epoch(Date.to_nanos_since_epoch(Date.highest) + Const.nanos_per_day.to_i128()) == Date.highest
expect Date.from_nanos_since_epoch(Date.to_nanos_since_epoch(Date.lowest) - 1) == Date.lowest

# <---- highest / lowest ---->
expect Date.highest.year() == Const.max_year and Date.highest.month() == Dec and Date.highest.day_of_month() == 31
expect Date.lowest.year() == Const.min_year and Date.lowest.month() == Jan and Date.lowest.day_of_month() == 1
expect Date.highest.to_iso_str() == "999999999-12-31"
expect Date.lowest.to_iso_str() == "-999999999-01-01"
expect Date.lowest.before(Date.highest)

# <---- from_yd ---->
expect Date.from_yd(2024, 366)? == Date.from_ymd(2024, Dec, 31)?
expect Date.from_yd(2023, 365)? == Date.from_ymd(2023, Dec, 31)?
expect Date.from_yd(2023, 366) == Err(InvalidDayOfYear)
expect Date.from_yd(2024, 367) == Err(InvalidDayOfYear)
expect Date.from_yd(2024, 0) == Err(InvalidDayOfYear)
expect Date.from_yd(Const.max_year + 1, 1) == Err(YearOutOfRange)
expect Date.from_yd(Const.min_year - 1, 1) == Err(YearOutOfRange)
expect Date.from_yd(1970, 1)? == { year: 1970, month: Jan, day_of_month: 1, day_of_year: 1 }
expect Date.from_yd(1970, 31)? == { year: 1970, month: Jan, day_of_month: 31, day_of_year: 31 }
expect Date.from_yd(1970, 32)? == { year: 1970, month: Feb, day_of_month: 1, day_of_year: 32 }
expect Date.from_yd(1970, 60)? == { year: 1970, month: Mar, day_of_month: 1, day_of_year: 60 }
expect Date.from_yd(1972, 61)? == { year: 1972, month: Mar, day_of_month: 1, day_of_year: 61 }

# <---- from_ymd ---->
expect Date.from_ymd(2024, Feb, 29)? == Date.from_yd(2024, 60)?
expect Date.from_ymd(2023, Feb, 29) == Err(InvalidDayOfMonth)
expect Date.from_ymd(2024, Apr, 31) == Err(InvalidDayOfMonth)
expect Date.from_ymd(2024, Jan, 0) == Err(InvalidDayOfMonth)
expect Date.from_ymd(2024, Jan, 255) == Err(InvalidDayOfMonth)
expect Date.from_ymd(Const.max_year, Dec, 31)? == Date.highest
expect Date.from_ymd(Const.min_year, Jan, 1)? == Date.lowest
expect Date.from_ymd(Const.max_year + 1, Jan, 1) == Err(YearOutOfRange)
expect Date.from_ymd(Const.min_year - 1, Dec, 31) == Err(YearOutOfRange)
expect Month.all.map(|m| Date.from_ymd(2023, m, Date.days_in_month(2023, m) + 1)) == Month.all.map(|_| Err(InvalidDayOfMonth))
expect Date.from_ymd(1970, Jan, 1)? == { year: 1970, month: Jan, day_of_month: 1, day_of_year: 1 }
expect Date.from_ymd(1970, Dec, 31)? == { year: 1970, month: Dec, day_of_month: 31, day_of_year: 365 }
expect Date.from_ymd(1972, Mar, 1)? == { year: 1972, month: Mar, day_of_month: 1, day_of_year: 61 }

# <---- from_yw ---->
expect Date.from_yw(2020, 53)? == Date.from_ymd(2020, Dec, 28)?
expect Date.from_yw(2024, 53) == Err(InvalidWeek)
expect Date.from_yw(2024, 0) == Err(InvalidWeek)
expect Date.from_yw(Const.max_year + 1, 1) == Err(YearOutOfRange)
expect Date.from_yw(1970, 1)? == { year: 1970, month: Jan, day_of_month: 1, day_of_year: 1 }
expect Date.from_yw(1971, 1)? == { year: 1971, month: Jan, day_of_month: 4, day_of_year: 4 }

# <---- from_ywd ---->
expect Date.from_ywd(2020, 53, 7)? == Date.from_ymd(2021, Jan, 3)?
expect Date.from_ywd(2024, 1, 0) == Err(InvalidWeekday)
expect Date.from_ywd(2024, 1, 8) == Err(InvalidWeekday)
expect Date.from_ywd(2024, 53, 1) == Err(InvalidWeek)
expect Date.from_ywd(Const.min_year - 1, 1, 1) == Err(YearOutOfRange)
expect Date.from_ywd(1970, 1, 1)? == { year: 1970, month: Jan, day_of_month: 1, day_of_year: 1 }
expect Date.from_ywd(1970, 52, 5)? == { year: 1971, month: Jan, day_of_month: 1, day_of_year: 1 }

# <---- num_days_since_epoch ---->
expect num_days_since_epoch(Date.from_ymd(2024, Jan, 1)?) == 19723 # Removed due to compiler bug with optional record fields
expect num_days_since_epoch(Date.from_ymd(1970, Dec, 31)?) == 365 - 1
expect num_days_since_epoch(Date.from_ymd(1971, Jan, 2)?) == 365 + 1
expect num_days_since_epoch(Date.from_ymd(2024, Jan, 1)?) == 19723
expect num_days_since_epoch(Date.from_ymd(2024, Feb, 1)?) == 19723 + 31
expect num_days_since_epoch(Date.from_ymd(2024, Dec, 31)?) == 19723 + 366 - 1
expect num_days_since_epoch(Date.from_ymd(1969, Dec, 31)?) == -1
expect num_days_since_epoch(Date.from_ymd(1969, Dec, 30)?) == -2
expect num_days_since_epoch(Date.from_ymd(1969, Jan, 1)?) == -365
expect num_days_since_epoch(Date.from_ymd(1968, Jan, 1)?) == -365 - 366

# <---- num_days_since_epoch_until_year ---->
expect num_days_since_epoch_until_year(1968) == -365 - 366
expect num_days_since_epoch_until_year(1970) == 0
expect num_days_since_epoch_until_year(1971) == 365
expect num_days_since_epoch_until_year(1972) == 365 + 365
expect num_days_since_epoch_until_year(1973) == 365 + 365 + 366
expect num_days_since_epoch_until_year(2024) == 19723

# <---- parse_month ---->
expect parse_month(['0', '1']) == Ok(Jan)
expect parse_month(['1', '2']) == Ok(Dec)
expect parse_month(['0', '0']) == Err(InvalidDateFormat)
expect parse_month(['1', '3']) == Err(InvalidDateFormat)
expect parse_month(['9', '9']) == Err(InvalidDateFormat)
expect parse_month(['1', 'a']) == Err(InvalidDateFormat)
expect parse_month([]) == Err(InvalidDateFormat)
expect Month.all.map(|m| parse_month(Utils.expand_int_with_zeros(m.to_u8().to_i64(), 2).to_utf8())) == Month.all.map(|m| Ok(m))

# <---- sub ---->
expect Date.sub(Date.from_ymd(2025, Jan, 1)?, Date.from_ymd(2025, Jan, 2)?) == Duration.from_days(-1.I128)
expect Date.sub(Date.from_ymd(1970, Jan, 1)?, Date.from_ymd(1968, Jan, 1)?) == Duration.from_days(731.I128)

# <---- to_nanos_since_epoch ---->
expect Date.to_nanos_since_epoch({ year: 1970, month: Jan, day_of_month: 1, day_of_year: 1 }) == 0
expect Date.to_nanos_since_epoch({ year: 1970, month: Dec, day_of_month: 31, day_of_year: 365 }) == Const.nanos_per_hour.to_i128() * 24 * 364
expect Date.to_nanos_since_epoch({ year: 1973, month: Jan, day_of_month: 1, day_of_year: 1 }) == Const.nanos_per_hour.to_i128() * 24 * 365 * 2 + Const.nanos_per_hour.to_i128() * 24 * 366
expect Date.to_nanos_since_epoch({ year: 1969, month: Dec, day_of_month: 31, day_of_year: 365 }) == Const.nanos_per_hour.to_i128() * 24 * (-1)
expect Date.to_nanos_since_epoch({ year: 1969, month: Jan, day_of_month: 1, day_of_year: 1 }) == Const.nanos_per_hour.to_i128() * 24 * (-365)
expect Date.to_nanos_since_epoch({ year: 1968, month: Jan, day_of_month: 1, day_of_year: 1 }) == Const.nanos_per_hour.to_i128() * 24 * (-365) - Const.nanos_per_hour.to_i128() * 24 * 366

# <---- to_iso_str ---->
expect Date.to_iso_str(Date.unix_epoch) == "1970-01-01"

# <---- weekday_help ---->
expect weekday_help(1964, Oct, 10) == 6
expect weekday_help(1964, Oct, 11) == 0
expect weekday_help(1964, Oct, 12) == 1
expect weekday_help(2024, Oct, 12) == 6

# <---- ymd_to_days_in_year ---->
expect ymd_to_days_in_year(1970, Jan, 1) == 1
expect ymd_to_days_in_year(1970, Dec, 31) == 365
expect ymd_to_days_in_year(1972, Mar, 1) == 61
expect ymd_to_days_in_year(2024, Dec, 31) == 366
expect ymd_to_days_in_year(2023, Dec, 31) == 365
expect ymd_to_days_in_year(2024, Mar, 1) == 61
expect ymd_to_days_in_year(2023, Mar, 1) == 60
