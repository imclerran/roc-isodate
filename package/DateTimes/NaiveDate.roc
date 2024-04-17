interface NaiveDate
    exposes [
        NaiveDate,
        fromYmd,
        toIsoStr,
        withNaiveTime,
        toYmd,
        unixEpoch,
        firstDayOfCE,
        fromOrdinalDate,
        fromDaysSinceCE,
        getDay,
        getYear,
        getMonth,
    ]
    imports [
        Utils,
        NaiveTime.{ NaiveTime, midnight },
    ]

## A date in the Gregorian calendar without a timezone.
##
## Stored as an ISO 8601 ordinal date, i.e. year and day of year
## Dates before the start of the Gregorian calendar are extrapolated, so be careful with historical dates.
## Years are 1 indexed to match the Common Era, i.e. year 1 is 1 CE, year 0 is 1 BCE, year -1 is 2 BCE, etc.
## Day of the year is 0 indexed, i.e. 0 is the first day of the year.
NaiveDate : { year : I64, dayOfYear : U16 }

# Constructors

## The Unix epoch, 1970-01-01.
unixEpoch : NaiveDate
unixEpoch = { year: 1970, dayOfYear: 0 }

## The first day of the common era, 0001-01-01.
firstDayOfCE : NaiveDate
firstDayOfCE = { year: 1, dayOfYear: 0 }

## Convert a year, month, and day to a NaiveDate.
fromYmd : I64, U8, U8 -> Result NaiveDate [InvalidMonth, InvalidDay]
fromYmd = \year, month, day ->
    if month == 0 || month > 12 then
        Err InvalidMonth
    else
        nDaysInMonth = Utils.nDaysInMonthOfYear month year |> Utils.unwrap "This should never happen, because we already checked that the month is valid."
        if day == 0 || day > nDaysInMonth then
            Err InvalidDay
        else
            dayOfYear =
                Utils.nDaysInEachMonthOfYear year
                |> List.map Num.toU16
                |> List.sublist { start: 0, len: Num.intCast month }
                |> List.sum
                |> Num.add (Num.toU16 day)
                |> Num.sub 1
            Ok { year, dayOfYear }

expect
    out = fromYmd 1970 1 1
    out == Ok unixEpoch

expect
    out = fromYmd 1 1 1
    out == Ok firstDayOfCE

expect
    out = fromYmd 2023 1 1
    out == Ok { year: 2023, dayOfYear: 0 }

expect
    out = fromYmd 1970 1 1
    out == Ok { year: 1970, dayOfYear: 0 }

expect
    out = fromYmd 2023 12 31
    out == Ok { year: 2023, dayOfYear: 364 }

expect
    out = fromYmd 2023 13 1
    out == Err InvalidMonth

## Convert a year and day of year to a NaiveDate.
##
## The first day of the year is 1st January.
## Trying to convert the 0th day of the year or a day after the last day of the year returns an InvalidDayOfYear error.
fromOrdinalDate : I64, U16 -> Result NaiveDate [InvalidDayOfYear]
fromOrdinalDate = \year, dayOfYear ->
    if dayOfYear == 0 || dayOfYear > (Utils.nDaysInYear year) then
        Err InvalidDayOfYear
    else
        Ok { year: year, dayOfYear: dayOfYear - 1 }

expect
    out = fromOrdinalDate 1970 1
    out == Ok unixEpoch

expect
    out = fromOrdinalDate 1 1
    out == Ok firstDayOfCE

expect
    out = fromOrdinalDate 1 0 # 0th day of 1 CE
    out == Err InvalidDayOfYear

expect
    out = fromOrdinalDate 1 365 # 31st December 1 CE
    out == Ok { year: 1, dayOfYear: 364 }

expect
    out = fromOrdinalDate 1 366 # Day after the last day of 1 CE
    out == Err InvalidDayOfYear

expect
    out = fromOrdinalDate 4 366 # 31st December 4 CE
    out == Ok { year: 4, dayOfYear: 365 }

expect
    out = fromOrdinalDate 4 367 # Day after the last day of 4 CE
    out == Err InvalidDayOfYear

expect
    out = fromOrdinalDate 1 59 # 28th February 1 CE
    out == Ok { year: 1, dayOfYear: 58 }

## Convert a number of days since the Common Era to a NaiveDate.
##
## The zeroth day of the Common Era is 31st December, 1 BCE, and the first day of the Common Era is 1st January, 1 CE.
fromDaysSinceCE : U64 -> NaiveDate
fromDaysSinceCE = \daysSinceCE ->
    if daysSinceCE == 0 then
        { year: 0, dayOfYear: 365 }
    else
        daysSinceCEIndex = daysSinceCE - 1 + 366
        yearUpperBound = (daysSinceCEIndex // 365) + 2 # Just to be safe
        daysInEachYear =
            List.range { start: At 0, end: At yearUpperBound }
            |> List.map Utils.nDaysInYear
            |> List.map Num.toU64
        { quotient: year, remainder: dayOfYearIndex } = Utils.subtractWhileGreaterThanZero daysSinceCEIndex daysInEachYear
        dayOfYear = dayOfYearIndex |> Num.add 1 |> Num.toU16
        fromOrdinalDate (Num.toI64 year) dayOfYear
        |> Utils.unwrap "This should never happen because we already checked that the day of the year is valid."

expect
    out = fromDaysSinceCE 0
    out
    == (
        fromYmd 0 12 31
        |> Utils.unwrap "This should never happen because the date was hardcoded."
    )

expect
    out = fromDaysSinceCE 1
    out
    == (
        fromYmd 1 1 1
        |> Utils.unwrap "This should never happen because the date was hardcoded."
    )

expect
    out = fromDaysSinceCE 365
    out
    == (
        fromYmd 1 12 31
        |> Utils.unwrap "This should never happen because the date was hardcoded."
    )

expect
    out = fromDaysSinceCE 366
    out
    == (
        fromYmd 2 1 1
        |> Utils.unwrap "This should never happen because the date was hardcoded."
    )

expect
    nDaysInFirstFourYearsOfCE =
        List.range { start: At 1, end: At 4 }
        |> List.map Utils.nDaysInYear
        |> List.map Num.toU64
        |> List.sum
    out = fromDaysSinceCE nDaysInFirstFourYearsOfCE
    out == (fromYmd 4 12 31 |> Result.withDefault unixEpoch)

# Serialise

## Serialise a date to ISO format.
toIsoStr : NaiveDate -> Str
toIsoStr = \naiveDate ->
    { year, month, day } = toYmd naiveDate
    yearStr = year |> Utils.padIntegerToLength 4
    monthStr = month |> Utils.padIntegerToLength 2
    dayStr = day |> Utils.padIntegerToLength 2
    "\(yearStr)-\(monthStr)-\(dayStr)"

expect
    out = toIsoStr unixEpoch
    out == "1970-01-01"

expect
    out = toIsoStr firstDayOfCE
    out == "0001-01-01"

# Methods

## Convert a NaiveDate to a year, month, and day.
toYmd : NaiveDate -> { year : I64, month : U8, day : U8 }
toYmd = \naiveDate ->
    { quotient: month, remainder: dayIndex } = Utils.subtractWhileGreaterThanZero naiveDate.dayOfYear (Utils.nDaysInEachMonthOfYear naiveDate.year |> List.map Num.toU16)
    { year: naiveDate.year, month: Num.toU8 month, day: Num.toU8 dayIndex + 1 }

expect
    out = toYmd unixEpoch
    out == { year: 1970, month: 1, day: 1 }

expect
    out = toYmd firstDayOfCE
    out == { year: 1, month: 1, day: 1 }

expect
    out = toYmd { year: 1, dayOfYear: 364 } # 31st December 1 CE
    out == { year: 1, month: 12, day: 31 }

expect
    out = toYmd { year: 4, dayOfYear: 365 } # 31st December 4 CE
    out == { year: 4, month: 12, day: 31 }

expect
    out = toYmd { year: 1, dayOfYear: 58 } # 28th February 1 CE
    out == { year: 1, month: 2, day: 28 }

## Get the year of a NaiveDate.
getYear : NaiveDate -> I64
getYear = \naiveDate -> naiveDate.year

expect
    out = getYear unixEpoch
    out == 1970

expect
    out = getYear firstDayOfCE
    out == 1

## Get the month of a NaiveDate.
getMonth : NaiveDate -> U8
getMonth = \naiveDate -> (toYmd naiveDate).month

expect
    out = getMonth unixEpoch
    out == 1

expect
    out = getMonth firstDayOfCE
    out == 1

## Get the day of a NaiveDate.
getDay : NaiveDate -> U8
getDay = \naiveDate -> (toYmd naiveDate).day

expect
    out = getDay unixEpoch
    out == 1

expect
    out = getDay firstDayOfCE
    out == 1

## Add a NaiveTime to a NaiveDate.
withNaiveTime : NaiveDate, NaiveTime -> _
withNaiveTime = \naiveDate, naiveTime -> { naiveDate: naiveDate, naiveTime: naiveTime }

expect
    out = withNaiveTime unixEpoch midnight
    out == { naiveDate: unixEpoch, naiveTime: midnight }

expect
    out = withNaiveTime firstDayOfCE midnight
    out == { naiveDate: firstDayOfCE, naiveTime: midnight }
