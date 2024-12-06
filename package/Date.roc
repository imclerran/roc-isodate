## The Date module provides the `Date` type, as well as various functions for working with dates.
##
## These functions include functions for creating dates from varioius numeric values, converting dates to and from ISO 8601 strings, and performing arithmetic operations on dates.
module [
    addDateAndDuration,
    addDays,
    addDurationAndDate,
    addMonths,
    addYears,
    Date,
    daysInMonth,
    fromIsoStr,
    fromIsoU8,
    fromNanosSinceEpoch,
    fromYd,
    fromYmd,
    fromYw,
    fromYwd,
    isLeapYear,
    toIsoStr,
    toIsoU8,
    toNanosSinceEpoch,
    unixEpoch,
    weekday,
]

import Const
import Duration exposing [Duration, toNanoseconds, fromDays]
import Utils exposing [
    expandIntWithZeros,
    splitListAtIndices,
    utf8ToInt,
    utf8ToIntSigned,
    validateUtf8SingleBytes,
]
import Unsafe exposing [unwrap] # for unit testing only

## ```
## Date : { 
##     year: I64, 
##     month: U8, 
##     dayOfMonth: U8, 
##     dayOfYear: U16 
## }
## ```
Date : { 
    year : I64,
    month : U8, 
    dayOfMonth : U8, 
    dayOfYear : U16 
}

## `Date` object representing the Unix epoch (1970-01-01).
unixEpoch : Date
unixEpoch = { year: 1970, month: 1, dayOfMonth: 1, dayOfYear: 1 }

## Create a `Date` object from the given year and day of the year.
fromYd : Int *, Int * -> Date
fromYd = \year, dayOfYear ->
    List.range { start: At 1, end: At 12 }
    |> List.map \m -> Const.monthDays { month: Num.toU64 m, isLeap: isLeapYear year }
    |> List.walkUntil { daysRemaining: Num.toU16 dayOfYear, month: 1 } walkUntilMonthFunc
    |> \result -> { year: Num.toI64 year, month: Num.toU8 result.month, dayOfMonth: Num.toU8 result.daysRemaining, dayOfYear: Num.toU16 dayOfYear }

## Check whether the given year is a leap year.
isLeapYear = \year ->
    (
        year
        % Const.leapInterval
        == 0
        && year
        % Const.leapException
        != 0
    )
    || year
    % Const.leapNonException
    == 0

## Walk through the months of a year to find the month and day of the month
walkUntilMonthFunc : { daysRemaining : U16, month : U8 }, U64 -> [Break { daysRemaining : U16, month : U8 }, Continue { daysRemaining : U16, month : U8 }]
walkUntilMonthFunc = \state, currMonthDays ->
    if state.daysRemaining <= Num.toU16 currMonthDays then
        Break { daysRemaining: state.daysRemaining, month: state.month }
    else
        Continue { daysRemaining: state.daysRemaining - Num.toU16 currMonthDays, month: state.month + 1 }

## Create a `Date` object from the given year, month, and day of the month.
fromYmd : Int *, Int *, Int * -> Date
fromYmd = \year, month, day ->
    { year: Num.toI64 year, month: Num.toU8 month, dayOfMonth: Num.toU8 day, dayOfYear: ymdToDaysInYear year month day }

## Convert the given year, month, and day of the month to the day of the year.
ymdToDaysInYear : Int *, Int *, Int * -> U16
ymdToDaysInYear = \year, month, day ->
    List.range { start: At 0, end: Before month }
    |> List.map \m -> Const.monthDays { month: Num.toU64 m, isLeap: isLeapYear year }
    |> List.sum
    |> Num.add (Num.toU64 day)
    |> Num.toU16

## Create a `Date` object from the given year, week, and day of the week.
fromYwd : Int *, Int *, Int * -> Date
fromYwd = \year, week, day ->
    daysInYear = if isLeapYear year then 366 else 365
    d = calendarWeekToDaysInYear week year |> Num.add (Num.toU64 day)
    if d > daysInYear then
        fromYd (year + 1) (d - daysInYear)
    else
        fromYd year d

## Convert the given calendar week and year to the day of the year.
calendarWeekToDaysInYear : Int *, Int * -> U64
calendarWeekToDaysInYear = \week, year ->
    # Week 1 of a year is the first week with a majority of its days in that year
    # https://en.wikipedia.org/wiki/ISO_week_date#First_week
    y = year |> Num.toU64
    w = week |> Num.toU64
    lengthOfMaybeFirstWeek =
        if y >= Const.epochYear then
            Const.epochWeekOffset - (numDaysSinceEpochUntilYear (Num.toI64 y) |> Num.toU64) % 7
        else
            (Const.epochWeekOffset + (numDaysSinceEpochUntilYear (Num.toI64 y) |> Num.abs |> Num.toU64)) % 7
    if lengthOfMaybeFirstWeek >= 4 && w == 1 then
        0
    else
        (w - 1) * Const.daysPerWeek + lengthOfMaybeFirstWeek

## Calculate the number of leap years since the epoch.
numLeapYearsSinceEpoch : I64, [IncludeCurrent, ExcludeCurrent] -> I64
numLeapYearsSinceEpoch = \year, inclusive ->
    leapIncr = isLeapYear year |> \isLeap -> if isLeap && inclusive == IncludeCurrent then 1 else 0
    nextYear = if year > Const.epochYear then year - 1 else year + 1
    when inclusive is
        ExcludeCurrent if year != Const.epochYear -> numLeapYearsSinceEpoch nextYear IncludeCurrent
        ExcludeCurrent -> 0
        IncludeCurrent if year != Const.epochYear -> leapIncr + numLeapYearsSinceEpoch nextYear inclusive
        IncludeCurrent -> leapIncr

## Calculate the number of days since the epoch.
numDaysSinceEpoch : Date -> I64
numDaysSinceEpoch = \date ->
    numLeapYears = numLeapYearsSinceEpoch date.year ExcludeCurrent
    getMonthDays = \m -> Const.monthDays { month: m, isLeap: isLeapYear date.year }
    if date.year >= Const.epochYear then
        daysInYears = numLeapYears * 366 + (date.year - Const.epochYear - numLeapYears) * 365
        List.map (List.range { start: At 1, end: Before date.month }) getMonthDays
        |> List.sum
        |> Num.toI64
        |> Num.add (daysInYears + Num.toI64 date.dayOfMonth - 1)
    else
        daysInYears = numLeapYears * 366 + (Const.epochYear - date.year - numLeapYears - 1) * 365
        List.map (List.range { start: After date.month, end: At 12 }) getMonthDays
        |> List.sum
        |> Num.toI64
        |> Num.add (daysInYears + Num.toI64 (getMonthDays date.month) - Num.toI64 date.dayOfMonth + 1)
        |> Num.mul -1

## Calculate the number of days since the epoch until the given year.
numDaysSinceEpochUntilYear = \year ->
    numDaysSinceEpoch { year, month: 1, dayOfMonth: 1, dayOfYear: 1 }

## Return the day of the week, from 0=Sunday to 6=Saturday
weekday : I64, U8, U8 -> U8
weekday = \year, month, day ->
    year2xxx = (year % 400) + 2400 # to handle years before the epoch
    date = Date.fromYmd year2xxx month day
    daysSinceEpoch = Date.toNanosSinceEpoch date // Const.nanosPerDay
    (daysSinceEpoch + 4) % 7 |> Num.toU8

## Returns the number of days in the given month of the given year.
daysInMonth : I64, U8 -> U8
daysInMonth = \year, month ->
    Const.monthDays { month, isLeap: (isLeapYear year) } |> Num.toU8

## Create a `Date` object from the given year and week.
fromYw : Int *, Int * -> Date
fromYw = \year, week ->
    fromYwd year week 1

## Convert the given `Date` to nanoseconds since the epoch.
toNanosSinceEpoch : Date -> I128
toNanosSinceEpoch = \date ->
    days = numDaysSinceEpoch date
    days |> Num.toI128 |> Num.mul Const.nanosPerDay

## Create a `Date` object from the given nanoseconds since the epoch.
fromNanosSinceEpoch : Int * -> Date
fromNanosSinceEpoch = \nanos ->
    days = nanos // Const.nanosPerDay |> \d -> if nanos % Const.nanosPerDay < 0 then d - 1 else d
    fromNanosHelper (Num.toI128 days) 1970

fromNanosHelper : I128, I64 -> Date
fromNanosHelper = \days, year ->
    if days < 0 then
        fromNanosHelper (days + if isLeapYear (year - 1) then 366 else 365) (year - 1)
    else
        daysInYear = if isLeapYear year then 366 else 365
        if days >= daysInYear then
            fromNanosHelper (days - daysInYear) (year + 1)
        else
            fromYd year (days + 1)

# TODO: allow for negative years
## Add the given number of years to the given `Date`.
addYears : Date, Int * -> Date
addYears = \date, years -> fromYmd (date.year + Num.toI64 years) date.month date.dayOfMonth

# TODO: allow for negative months
## Add the given number of months to the given `Date`.
addMonths : Date, Int * -> Date
addMonths = \date, months ->
    newMonthWithOverflow = date.month + Num.toU8 months
    newYear = date.year + Num.toI64 (newMonthWithOverflow // 12)
    newMonth = newMonthWithOverflow % 12
    newDay = (
        if date.dayOfMonth > Num.toU8 (Const.monthDays { month: newMonth, isLeap: isLeapYear newYear }) then
            Num.toU8 (Const.monthDays { month: newMonth, isLeap: isLeapYear newYear })
        else
            date.dayOfMonth
    )
    fromYmd newYear newMonth newDay

## Add the given number of days to the given `Date`.
addDays : Date, Int * -> Date
addDays = \date, days ->
    addDaysHelper date (Num.toI16 days)

addDaysHelper : Date, I16 -> Date
addDaysHelper = \date, days ->
    daysInYear = if isLeapYear date.year then 366 else 365
    newDayOfYear = (Num.toI16 date.dayOfYear) + days
    if newDayOfYear > daysInYear then
        addDaysHelper { year: date.year + 1, month: 1, dayOfMonth: 1, dayOfYear: 0 } (newDayOfYear - daysInYear)
    else if newDayOfYear < 1 then
        daysInPrevYear = if isLeapYear (date.year - 1) then 366 else 365
        addDaysHelper { year: date.year - 1, month: 12, dayOfMonth: 31, dayOfYear: 0 } (newDayOfYear + Num.toI16 daysInPrevYear)
    else
        fromYd date.year newDayOfYear

## Add the given `Duration` to the given `Date`.
addDurationAndDate : Duration, Date -> Date
addDurationAndDate = \duration, date ->
    durationNanos = toNanoseconds duration
    dateNanos = toNanosSinceEpoch date |> Num.toI128
    durationNanos + dateNanos |> fromNanosSinceEpoch

## Add the given `Date` and `Duration`.
addDateAndDuration : Date, Duration -> Date
addDateAndDuration = \date, duration -> addDurationAndDate duration date

## Convert the given `Date` to an ISO 8601 string.
toIsoStr : Date -> Str
toIsoStr = \date ->
    expandIntWithZeros date.year 4
    |> Str.concat "-"
    |> Str.concat (expandIntWithZeros date.month 2)
    |> Str.concat "-"
    |> Str.concat (expandIntWithZeros date.dayOfMonth 2)

## Convert the `Date` to an ISO 8601 string as a list of UTF-8 bytes.
toIsoU8 : Date -> List U8
toIsoU8 = \date -> toIsoStr date |> Str.toUtf8

## Convert the given ISO 8601 string to a `Date`.
fromIsoStr : Str -> Result Date [InvalidDateFormat]
fromIsoStr = \str -> Str.toUtf8 str |> fromIsoU8

# TODO: More efficient parsing method?
## Convert the given ISO 8601 list of UTF-8 bytes to a `Date`.
fromIsoU8 : List U8 -> Result Date [InvalidDateFormat]
fromIsoU8 = \bytes ->
    if validateUtf8SingleBytes bytes then
        when bytes is
            [_, _] -> parseCalendarDateCentury bytes # YY
            [_, _, _, _] -> parseCalendarDateYear bytes # YYYY
            [_, _, _, _, 'W', _, _] -> parseWeekDateReducedBasic bytes # YYYYWww
            [_, _, _, _, '-', _, _] -> parseCalendarDateMonth bytes # YYYY-MM
            [_, _, _, _, _, _, _] -> parseOrdinalDateBasic bytes # YYYYDDD
            [_, _, _, _, '-', 'W', _, _] -> parseWeekDateReducedExtended bytes # YYYY-Www
            [_, _, _, _, 'W', _, _, _] -> parseWeekDateBasic bytes # YYYYWwwD
            [_, _, _, _, '-', _, _, _] -> parseOrdinalDateExtended bytes # YYYY-DDD
            [_, _, _, _, _, _, _, _] -> parseCalendarDateBasic bytes # YYYYMMDD
            [_, _, _, _, '-', 'W', _, _, '-', _] -> parseWeekDateExtended bytes # YYYY-Www-D
            [_, _, _, _, '-', _, _, '-', _, _] -> parseCalendarDateExtended bytes # YYYY-MM-DD
            _ -> Err InvalidDateFormat
    else
        Err InvalidDateFormat

parseCalendarDateBasic : List U8 -> Result Date [InvalidDateFormat]
parseCalendarDateBasic = \bytes ->
    when splitListAtIndices bytes [4, 6] is
        [yearBytes, monthBytes, dayBytes] ->
            when (utf8ToInt yearBytes, utf8ToInt monthBytes, utf8ToInt dayBytes) is
                (Ok y, Ok m, Ok d) if m >= 1 && m <= 12 && d >= 1 && d <= 31 ->
                    Date.fromYmd y m d |> Ok

                (_, _, _) -> Err InvalidDateFormat

        _ -> Err InvalidDateFormat

parseCalendarDateExtended : List U8 -> Result Date [InvalidDateFormat]
parseCalendarDateExtended = \bytes ->
    when splitListAtIndices bytes [4, 5, 7, 8] is
        [yearBytes, _, monthBytes, _, dayBytes] ->
            when (utf8ToIntSigned yearBytes, utf8ToInt monthBytes, utf8ToInt dayBytes) is
                (Ok y, Ok m, Ok d) if m >= 1 && m <= 12 && d >= 1 && d <= 31 ->
                    Date.fromYmd y m d |> Ok

                (_, _, _) -> Err InvalidDateFormat

        _ -> Err InvalidDateFormat

parseCalendarDateCentury : List U8 -> Result Date [InvalidDateFormat]
parseCalendarDateCentury = \bytes ->
    when utf8ToIntSigned bytes is
        Ok century -> Date.fromYmd (century * 100) 1 1 |> Ok
        Err _ -> Err InvalidDateFormat

parseCalendarDateYear : List U8 -> Result Date [InvalidDateFormat]
parseCalendarDateYear = \bytes ->
    when utf8ToIntSigned bytes is
        Ok year -> Date.fromYmd year 1 1 |> Ok
        Err _ -> Err InvalidDateFormat

parseCalendarDateMonth : List U8 -> Result Date [InvalidDateFormat]
parseCalendarDateMonth = \bytes ->
    when splitListAtIndices bytes [4, 5] is
        [yearBytes, _, monthBytes] ->
            when (utf8ToIntSigned yearBytes, utf8ToInt monthBytes) is
                (Ok year, Ok month) if month >= 1 && month <= 12 ->
                    Date.fromYmd year month 1 |> Ok

                (_, _) -> Err InvalidDateFormat

        _ -> Err InvalidDateFormat

parseOrdinalDateBasic : List U8 -> Result Date [InvalidDateFormat]
parseOrdinalDateBasic = \bytes ->
    when splitListAtIndices bytes [4] is
        [yearBytes, dayBytes] ->
            when (utf8ToIntSigned yearBytes, utf8ToInt dayBytes) is
                (Ok year, Ok day) if day >= 1 && day <= 366 ->
                    Date.fromYd year day |> Ok

                (_, _) -> Err InvalidDateFormat

        _ -> Err InvalidDateFormat

parseOrdinalDateExtended : List U8 -> Result Date [InvalidDateFormat]
parseOrdinalDateExtended = \bytes ->
    when splitListAtIndices bytes [4, 5] is
        [yearBytes, _, dayBytes] ->
            when (utf8ToIntSigned yearBytes, utf8ToInt dayBytes) is
                (Ok year, Ok day) if day >= 1 && day <= 366 ->
                    Date.fromYd year day |> Ok

                (_, _) -> Err InvalidDateFormat

        _ -> Err InvalidDateFormat

parseWeekDateBasic : List U8 -> Result Date [InvalidDateFormat]
parseWeekDateBasic = \bytes ->
    when splitListAtIndices bytes [4, 5, 7] is
        [yearBytes, _, weekBytes, dayBytes] ->
            when (utf8ToInt yearBytes, utf8ToInt weekBytes, utf8ToInt dayBytes) is
                (Ok y, Ok w, Ok d) if w >= 1 && w <= 52 && d >= 1 && d <= 7 ->
                    Date.fromYwd y w d |> Ok

                (_, _, _) -> Err InvalidDateFormat

        _ -> Err InvalidDateFormat

parseWeekDateExtended : List U8 -> Result Date [InvalidDateFormat]
parseWeekDateExtended = \bytes ->
    when splitListAtIndices bytes [4, 6, 8, 9] is
        [yearBytes, _, weekBytes, _, dayBytes] ->
            when (utf8ToInt yearBytes, utf8ToInt weekBytes, utf8ToInt dayBytes) is
                (Ok y, Ok w, Ok d) if w >= 1 && w <= 52 && d >= 1 && d <= 7 ->
                    Date.fromYwd y w d |> Ok

                (_, _, _) -> Err InvalidDateFormat

        _ -> Err InvalidDateFormat

parseWeekDateReducedBasic : List U8 -> Result Date [InvalidDateFormat]
parseWeekDateReducedBasic = \bytes ->
    when splitListAtIndices bytes [4, 5] is
        [yearBytes, _, weekBytes] ->
            when (utf8ToInt yearBytes, utf8ToInt weekBytes) is
                (Ok year, Ok week) if week >= 1 && week <= 52 ->
                    Date.fromYw year week |> Ok

                (_, _) -> Err InvalidDateFormat

        _ -> Err InvalidDateFormat

parseWeekDateReducedExtended : List U8 -> Result Date [InvalidDateFormat]
parseWeekDateReducedExtended = \bytes ->
    when splitListAtIndices bytes [4, 6] is
        [yearBytes, _, weekBytes] ->
            when (utf8ToInt yearBytes, utf8ToInt weekBytes) is
                (Ok year, Ok week) if week >= 1 && week <= 52 ->
                    Date.fromYw year week |> Ok

                (_, _) -> Err InvalidDateFormat

        _ -> Err InvalidDateFormat

# <==== TESTS ====>
# <---- fromYd ---->
expect fromYd 1970 1 == { year: 1970, month: 1, dayOfMonth: 1, dayOfYear: 1 }
expect fromYd 1970 31 == { year: 1970, month: 1, dayOfMonth: 31, dayOfYear: 31 }
expect fromYd 1970 32 == { year: 1970, month: 2, dayOfMonth: 1, dayOfYear: 32 }
expect fromYd 1970 60 == { year: 1970, month: 3, dayOfMonth: 1, dayOfYear: 60 }
expect fromYd 1972 61 == { year: 1972, month: 3, dayOfMonth: 1, dayOfYear: 61 }

# <---- calendarWeekToDaysInYear ---->
expect calendarWeekToDaysInYear 1 1965 == 3
expect calendarWeekToDaysInYear 1 1964 == 0
expect calendarWeekToDaysInYear 1 1970 == 0
expect calendarWeekToDaysInYear 1 1971 == 3
expect calendarWeekToDaysInYear 1 1972 == 2
expect calendarWeekToDaysInYear 1 1973 == 0
expect calendarWeekToDaysInYear 2 2024 == 7

# <---- numDaysSinceEpoch ---->
expect numDaysSinceEpoch (fromYmd 2024 1 1) == 19723 # Removed due to compiler bug with optional record fields
expect numDaysSinceEpoch (fromYmd 1970 12 31) == 365 - 1
expect numDaysSinceEpoch (fromYmd 1971 1 2) == 365 + 1
expect numDaysSinceEpoch (fromYmd 2024 1 1) == 19723
expect numDaysSinceEpoch (fromYmd 2024 2 1) == 19723 + 31
expect numDaysSinceEpoch (fromYmd 2024 12 31) == 19723 + 366 - 1
expect numDaysSinceEpoch (fromYmd 1969 12 31) == -1
expect numDaysSinceEpoch (fromYmd 1969 12 30) == -2
expect numDaysSinceEpoch (fromYmd 1969 1 1) == -365
expect numDaysSinceEpoch (fromYmd 1968 1 1) == -365 - 366

# <---- numDaysSinceEpochToYear ---->
expect numDaysSinceEpochUntilYear 1968 == -365 - 366
expect numDaysSinceEpochUntilYear 1970 == 0
expect numDaysSinceEpochUntilYear 1971 == 365
expect numDaysSinceEpochUntilYear 1972 == 365 + 365
expect numDaysSinceEpochUntilYear 1973 == 365 + 365 + 366
expect numDaysSinceEpochUntilYear 2024 == 19723

# <---- fromYmd ---->
expect fromYmd 1970 1 1 == { year: 1970, month: 1, dayOfMonth: 1, dayOfYear: 1 }
expect fromYmd 1970 12 31 == { year: 1970, month: 12, dayOfMonth: 31, dayOfYear: 365 }
expect fromYmd 1972 3 1 == { year: 1972, month: 3, dayOfMonth: 1, dayOfYear: 61 }

# <---- fromYwd ---->
expect fromYwd 1970 1 1 == { year: 1970, month: 1, dayOfMonth: 1, dayOfYear: 1 }
expect fromYwd 1970 52 5 == { year: 1971, month: 1, dayOfMonth: 1, dayOfYear: 1 }

# <---- fromYw ---->
expect fromYw 1970 1 == { year: 1970, month: 1, dayOfMonth: 1, dayOfYear: 1 }
expect fromYw 1971 1 == { year: 1971, month: 1, dayOfMonth: 4, dayOfYear: 4 }

# <---- fromNanosSinceEpoch ---->
expect fromNanosSinceEpoch 0 == { year: 1970, month: 1, dayOfMonth: 1, dayOfYear: 1 }
expect fromNanosSinceEpoch (Const.nanosPerDay * 365) == { year: 1971, month: 1, dayOfMonth: 1, dayOfYear: 1 }
expect fromNanosSinceEpoch (Const.nanosPerDay * 365 * 2 + Const.nanosPerDay * 366) == { year: 1973, month: 1, dayOfMonth: 1, dayOfYear: 1 }
expect fromNanosSinceEpoch (-Const.nanosPerDay) == { year: 1969, month: 12, dayOfMonth: 31, dayOfYear: 365 }
expect fromNanosSinceEpoch (-Const.nanosPerDay * 365) == { year: 1969, month: 1, dayOfMonth: 1, dayOfYear: 1 }
expect fromNanosSinceEpoch (-Const.nanosPerDay * 365 - Const.nanosPerDay * 366) == { year: 1968, month: 1, dayOfMonth: 1, dayOfYear: 1 }
expect fromNanosSinceEpoch -1 == { year: 1969, month: 12, dayOfMonth: 31, dayOfYear: 365 }

# <---- toNanosSinceEpoch ---->
expect toNanosSinceEpoch { year: 1970, month: 1, dayOfMonth: 1, dayOfYear: 1 } == 0
expect toNanosSinceEpoch { year: 1970, month: 12, dayOfMonth: 31, dayOfYear: 365 } == Const.nanosPerHour * 24 * 364
expect toNanosSinceEpoch { year: 1973, month: 1, dayOfMonth: 1, dayOfYear: 1 } == Const.nanosPerHour * 24 * 365 * 2 + Const.nanosPerHour * 24 * 366
expect toNanosSinceEpoch { year: 1969, month: 12, dayOfMonth: 31, dayOfYear: 365 } == Const.nanosPerHour * 24 * -1
expect toNanosSinceEpoch { year: 1969, month: 1, dayOfMonth: 1, dayOfYear: 1 } == Const.nanosPerHour * 24 * -365
expect toNanosSinceEpoch { year: 1968, month: 1, dayOfMonth: 1, dayOfYear: 1 } == Const.nanosPerHour * 24 * -365 - Const.nanosPerHour * 24 * 366

# <---- toIsoStr ---->
expect toIsoStr unixEpoch == "1970-01-01"

# <---- addMonths ---->
expect addMonths unixEpoch 12 == fromYmd 1971 1 1
expect addMonths (fromYmd 1970 1 31) 1 == fromYmd 1970 2 28
expect addMonths (fromYmd 1972 2 29) 12 == fromYmd 1973 2 28

# <---- addDays ---->
expect addDays unixEpoch 365 == fromYmd 1971 1 1
expect addDays unixEpoch (365 * 2) == fromYmd 1972 1 1
expect addDays unixEpoch (365 * 2 + 366) == fromYmd 1973 1 1
expect addDays unixEpoch (-1) == fromYmd 1969 12 31
expect addDays unixEpoch (-365) == fromYmd 1969 1 1
expect addDays unixEpoch (-365 - 1) == fromYmd 1968 12 31
expect addDays unixEpoch (-365 - 366) == fromYmd 1968 1 1

# <---- addDateAndDuration ---->
expect
    addDateAndDuration unixEpoch (fromDays 1 |> unwrap "will not overflow") == fromYmd 1970 1 2

# <---- ymdToDaysInYear ---->
expect ymdToDaysInYear 1970 1 1 == 1
expect ymdToDaysInYear 1970 12 31 == 365
expect ymdToDaysInYear 1972 3 1 == 61

# <---- weekday ---->
expect weekday 1964 10 10 == 6
expect weekday 1964 10 11 == 0
expect weekday 1964 10 12 == 1
expect weekday 2024 10 12 == 6

# <---- daysInMonth ---->
expect daysInMonth 1969 1 == 31
expect daysInMonth 1969 2 == 28
expect daysInMonth 1969 3 == 31
expect daysInMonth 1969 4 == 30
expect daysInMonth 1969 5 == 31
expect daysInMonth 1969 6 == 30
expect daysInMonth 1969 7 == 31
expect daysInMonth 1969 8 == 31
expect daysInMonth 1969 9 == 30
expect daysInMonth 1969 10 == 31
expect daysInMonth 1969 11 == 30
expect daysInMonth 1969 12 == 31
expect daysInMonth 2024 2 == 29
