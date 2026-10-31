## The Month module provides the `Month` type, representing one of the twelve calendar months.
##
## A `Month` is always valid, so functions that take a `Month` never need to handle an out-of-range value.
## Use [`from_u8`](Month#from_u8) to validate a number at the boundary of your program, and
## [`to_u8`](Month#to_u8) to get the number back for display or storage.
## ```
## Month := [Jan, Feb, Mar, Apr, May, Jun, Jul, Aug, Sep, Oct, Nov, Dec]
## ```
Month := [Jan, Feb, Mar, Apr, May, Jun, Jul, Aug, Sep, Oct, Nov, Dec].{

	## Are two Months equal?
	is_eq : _

	## All twelve months, in calendar order.
	all : List(Month)
	all = [Jan, Feb, Mar, Apr, May, Jun, Jul, Aug, Sep, Oct, Nov, Dec]

	## The number of days in the month. February has 29 days when `is_leap` is true.
	days : Month, { is_leap : Bool } -> U8
	days = |month, { is_leap }| {
		match month {
			Jan | Mar | May | Jul | Aug | Oct | Dec => 31
			Apr | Jun | Sep | Nov => 30
			Feb if is_leap => 29
			Feb => 28
		}
	}

	## Convert a month number (1 = January, 12 = December) to a `Month`.
	from_u8 : U8 -> Try(Month, [InvalidMonth])
	from_u8 = |n| {
		match n {
			1 => Ok(Jan)
			2 => Ok(Feb)
			3 => Ok(Mar)
			4 => Ok(Apr)
			5 => Ok(May)
			6 => Ok(Jun)
			7 => Ok(Jul)
			8 => Ok(Aug)
			9 => Ok(Sep)
			10 => Ok(Oct)
			11 => Ok(Nov)
			12 => Ok(Dec)
			_ => Err(InvalidMonth)
		}
	}

	## The month after this one. December wraps around to January.
	next : Month -> Month
	next = |month| {
		match month {
			Jan => Feb
			Feb => Mar
			Mar => Apr
			Apr => May
			May => Jun
			Jun => Jul
			Jul => Aug
			Aug => Sep
			Sep => Oct
			Oct => Nov
			Nov => Dec
			Dec => Jan
		}
	}

	## The month before this one. January wraps around to December.
	prev : Month -> Month
	prev = |month| {
		match month {
			Jan => Dec
			Feb => Jan
			Mar => Feb
			Apr => Mar
			May => Apr
			Jun => May
			Jul => Jun
			Aug => Jul
			Sep => Aug
			Oct => Sep
			Nov => Oct
			Dec => Nov
		}
	}

	## Convert a `Month` to its month number (1 = January, 12 = December).
	to_u8 : Month -> U8
	to_u8 = |month| {
		match month {
			Jan => 1
			Feb => 2
			Mar => 3
			Apr => 4
			May => 5
			Jun => 6
			Jul => 7
			Aug => 8
			Sep => 9
			Oct => 10
			Nov => 11
			Dec => 12
		}
	}
}

# <===== TESTS ====>
# <---- all ---->
expect Month.all.len() == 12
expect Month.all.map(Month.to_u8) == [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]

# <---- days ---->
expect Month.all.map(|m| m.days({ is_leap: Bool.False })) == [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
expect Month.all.map(|m| m.days({ is_leap: Bool.True })) == [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]

# <---- from_u8 / to_u8 round trip ---->
expect Month.all.map(|m| Month.from_u8(m.to_u8())) == Month.all.map(|m| Ok(m))
expect Month.from_u8(0) == Err(InvalidMonth)
expect Month.from_u8(13) == Err(InvalidMonth)
expect Month.from_u8(255) == Err(InvalidMonth)

# <---- next / prev ---->
expect Month.all.map(Month.next) == [Feb, Mar, Apr, May, Jun, Jul, Aug, Sep, Oct, Nov, Dec, Jan]
expect Month.all.map(Month.prev) == [Dec, Jan, Feb, Mar, Apr, May, Jun, Jul, Aug, Sep, Oct, Nov]
expect Month.all.map(|m| m.next().prev()) == Month.all
