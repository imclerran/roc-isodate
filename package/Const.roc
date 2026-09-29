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
	weeks_per_year = 52.U8

	month_days : { month : _, is_leap : Bool } -> Try(U8, [InvalidMonth])
	month_days = |{ month, is_leap }| {
		match month {
			1 | 3 | 5 | 7 | 8 | 10 | 12 => Ok(31)
			4 | 6 | 9 | 11 => Ok(30)
			2 if is_leap => Ok(29)
			2 => Ok(28)
			_ => Err(InvalidMonth)
		}
	}
}

expect Const.month_days({ month: 1, is_leap: Bool.False }) == Ok(31)
expect Const.month_days({ month: 2, is_leap: Bool.False }) == Ok(28)
expect Const.month_days({ month: 2, is_leap: Bool.True }) == Ok(29)
