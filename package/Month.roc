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

	## Hash a `Month`, so it can be used as a `Dict` key or `Set` element.
	to_hash : _

	## Does the first `Month` come earlier in the year than the second? Backs the `<` operator.
	is_lt : Month, Month -> Bool
	is_lt = |a, b| a.order_relative_to(b) == Before

	## Does the first `Month` come later in the year than the second? Backs the `>` operator.
	is_gt : Month, Month -> Bool
	is_gt = |a, b| a.order_relative_to(b) == After

	## Does the first `Month` come earlier in the year than, or equal, the second? Backs the `<=` operator.
	is_lte : Month, Month -> Bool
	is_lte = |a, b| a.order_relative_to(b) != After

	## Does the first `Month` come later in the year than, or equal, the second? Backs the `>=` operator.
	is_gte : Month, Month -> Bool
	is_gte = |a, b| a.order_relative_to(b) != Before

	## Compare two `Month`s by calendar order. Lets `List.sort` work on a `List(Month)`.
	order_relative_to : Month, Month -> [Before, Same, After]
	order_relative_to = |a, b| a.to_u8().order_relative_to(b.to_u8())

	## The earlier of two `Month`s. Lets `List.min` work on a `List(Month)`.
	min : Month, Month -> Month
	min = |a, b| if b.is_lt(a) { b } else { a }

	## The later of two `Month`s. Lets `List.max` work on a `List(Month)`.
	max : Month, Month -> Month
	max = |a, b| if b.is_gt(a) { b } else { a }

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

	## Let a string literal be used where a `Month` is expected. Both the three-letter abbreviation and the full English name are accepted.
	## ```
	## start : Month
	## start = "March"
	## ```
	## An invalid literal is a compile-time error.
	from_quote : Str -> Try(Month, [BadQuotedBytes(Str)])
	from_quote = |raw| {
		match raw {
			"Jan" | "January" => Ok(Jan)
			"Feb" | "February" => Ok(Feb)
			"Mar" | "March" => Ok(Mar)
			"Apr" | "April" => Ok(Apr)
			"May" => Ok(May)
			"Jun" | "June" => Ok(Jun)
			"Jul" | "July" => Ok(Jul)
			"Aug" | "August" => Ok(Aug)
			"Sep" | "September" => Ok(Sep)
			"Oct" | "October" => Ok(Oct)
			"Nov" | "November" => Ok(Nov)
			"Dec" | "December" => Ok(Dec)
			_ => Err(BadQuotedBytes("expected a month name such as Mar or March, but got ${raw}"))
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

# <---- to_hash ---->
expect Dict.empty().insert(Month.from_u8(3)?, "spring").get(Mar) == Ok("spring")
expect Set.from_list(Month.all).len() == 12
expect Set.from_list([Jan, Jan, Dec]).len() == 2

# <---- from_quote ---->
expect {
	m : Month
	m = "March"
	m == Mar
}
expect {
	m : Month
	m = "Sep"
	m == Sep
}
expect Month.all.map(|m| Month.from_quote(Str.inspect(m))) == Month.all.map(|m| Ok(m))
expect Month.from_quote("Smarch").is_err()
expect Month.from_quote("march").is_err()
expect Month.from_quote("Sept").is_err()
expect Month.from_quote("").is_err()
# The round trip above relies on Month's native inspect output being the short tag name.
expect Str.inspect(Mar) == "Mar"

# <---- ordering ---->
expect {
	a : Month
	a = Jan
	b : Month
	b = Dec
	a < b and b > a and a <= a and a >= a and !(b < a) and a.order_relative_to(b) == Before and b.order_relative_to(b) == Same
}
expect Month.all.drop_first(6).concat(Month.all.take_first(6)).sort() == Month.all
expect Month.all.min() == Ok(Jan)
expect Month.all.max() == Ok(Dec)
expect {
	a : Month
	a = Mar
	a.min(Sep) == Mar and a.max(Sep) == Sep
}
