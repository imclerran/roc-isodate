Const :: {}.{
	epoch_year = 1970.I64
	epoch_month = 1.U8
	epoch_day = 1.U8
	epoch_week_offset = 4.U8

	hours_per_day = 24.U16
	minutes_per_hour = 60.U16
	minutes_per_day = hours_per_day * minutes_per_hour

	nanos_per_milli = 1_000_000.I64
	nanos_per_second = 1_000_000_000.I64
	nanos_per_minute = 60 * nanos_per_second
	nanos_per_hour = 60 * nanos_per_minute
	nanos_per_day = 24 * nanos_per_hour

	seconds_per_minute = 60.U32
	seconds_per_hour = 3600.U32
	seconds_per_day = 86_400.U32

	leap_interval = 4.U16
	leap_exception = 100.U16
	leap_non_exception = 400.U16

	days_per_non_leap_year = 365.U16
	days_per_leap_year = 366.U16

	days_per_week = 7.U8

	## The range of years a `Date` can represent.
	## Arithmetic that would leave this range saturates to the nearest bound, matching `Duration`.
	min_year = -999_999_999.I64
	max_year = 999_999_999.I64
}
