interface Date
    exposes [
        addDateAndDuration,
        addDays,
        addDurationAndDate,
        addMonths,
        addYears,
        Date,
        fromNanosSinceEpoch,
        fromUtc,
        fromYd,
        fromYmd,
        fromYw,
        fromYwd,
        toNanosSinceEpoch,
        toUtc,
        unixEpoch,
    ]
    imports [
        Const,
        Duration,
        Duration.{ Duration },
        Utc,
        Utils.{
            isLeapYear,
            numDaysSinceEpoch,
            ymdToDaysInYear,
            calendarWeekToDaysInYear,
        },
        Unsafe.{ unwrap }, # for unit testing only
    ]

Date : { year: I64, month: U8, dayOfMonth: U8, dayOfYear: U16 }

unixEpoch : Date
unixEpoch = { year: 1970, month: 1, dayOfMonth: 1, dayOfYear: 1 }

fromYd : Int *, Int * -> Date
fromYd = \year, dayOfYear -> 
    ydToYmdd year dayOfYear

ydToYmdd : Int *, Int * -> Date
ydToYmdd = \year, dayOfYear ->
    List.range { start: At 1, end: At 12 }
    |> List.map \m -> Const.monthDays { month: Num.toU64 m, isLeap: isLeapYear year }
    |> List.walkUntil { daysRemaining: Num.toU16 dayOfYear, month: 1 } walkUntilMonthFunc
    |> \result -> { year: Num.toI64 year, month: Num.toU8 result.month, dayOfMonth: Num.toU8 result.daysRemaining, dayOfYear: Num.toU16 dayOfYear }

walkUntilMonthFunc : { daysRemaining: U16, month: U8 }, U64 -> [Break { daysRemaining: U16, month: U8 }, Continue { daysRemaining: U16, month: U8 }]
walkUntilMonthFunc = \state, currMonthDays ->
    if state.daysRemaining <= Num.toU16 currMonthDays then
        Break { daysRemaining: state.daysRemaining, month: state.month }
    else
        Continue { daysRemaining: state.daysRemaining - Num.toU16 currMonthDays, month: state.month + 1 }

fromYmd : Int *, Int *, Int * -> Date
fromYmd =\year, month, day -> 
    { year: Num.toI64 year, month: Num.toU8 month, dayOfMonth: Num.toU8 day, dayOfYear: ymdToDaysInYear year month day }

fromYwd : Int *, Int *, Int * -> Date
fromYwd = \year, week, day ->
    daysInYear = if isLeapYear year then 366 else 365
    d = calendarWeekToDaysInYear week year |> Num.add (Num.toU64 day)
    if d > daysInYear then
        ydToYmdd (year + 1) (d - daysInYear)
    else
        ydToYmdd year d

fromYw : Int *, Int * -> Date
fromYw = \year, week ->
    fromYwd year week 1

fromUtc : Utc.Utc -> Date
fromUtc =\utc ->
    days = Utc.toNanosSinceEpoch utc |> Num.divTrunc (Const.nanosPerHour * 24) |> \d -> 
        if Utc.toNanosSinceEpoch utc |> Num.rem (Const.nanosPerHour * 24) < 0 then d - 1 else d
    fromUtcHelper days 1970

fromUtcHelper : I128, I64 -> Date
fromUtcHelper =\days, year ->
    if days < 0 then
        fromUtcHelper (days + if Utils.isLeapYear (year - 1) then 366 else 365) (year - 1)
    else
        daysInYear = if Utils.isLeapYear year then 366 else 365
        if days >= daysInYear then
            fromUtcHelper (days - daysInYear) (year + 1)
        else
            ydToYmdd year (days + 1)

toUtc : Date -> Utc.Utc
toUtc =\date ->
    days = numDaysSinceEpoch {year: date.year |> Num.toU64, month: 1, day: 1} + (date.dayOfYear - 1 |> Num.toI64)
    Utc.fromNanosSinceEpoch (days |> Num.toI128 |> Num.mul (Const.nanosPerHour * 24))

toNanosSinceEpoch : Date -> I128
toNanosSinceEpoch = \date -> Date.toUtc date |> Utc.toNanosSinceEpoch

fromNanosSinceEpoch : Int * -> Date
fromNanosSinceEpoch = \nanos -> Utc.fromNanosSinceEpoch (Num.toI128 nanos) |> fromUtc

# TODO: allow for negative years
addYears : Date, Int * -> Date
addYears = \date, years -> fromYmd (date.year + Num.toI64 years) date.month date.dayOfMonth

# TODO: allow for negative months
addMonths : Date, Int * -> Date
addMonths = \date, months -> 
    newMonthWithOverflow = date.month + Num.toU8 months
    newYear = date.year + Num.toI64 (newMonthWithOverflow // 12)
    newMonth = newMonthWithOverflow % 12
    newDay = if date.dayOfMonth > Num.toU8 (Const.monthDays { month: newMonth, isLeap: isLeapYear newYear } )
        then Num.toU8 (Const.monthDays { month: newMonth, isLeap: isLeapYear newYear } )
        else date.dayOfMonth
    fromYmd newYear newMonth newDay

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

addDurationAndDate : Duration, Date -> Date
addDurationAndDate = \duration, date -> 
    durationNanos = Duration.toNanoseconds duration
    dateNanos = toNanosSinceEpoch date |> Num.toI128
    durationNanos + dateNanos |> fromNanosSinceEpoch

addDateAndDuration : Date, Duration -> Date
addDateAndDuration = \date, duration -> addDurationAndDate duration date


# <==== TESTS ====>
# <---- ydToYmdd ---->
expect ydToYmdd 1970 1 == { year: 1970, month: 1, dayOfMonth: 1, dayOfYear: 1 }
expect ydToYmdd 1970 31 == { year: 1970, month: 1, dayOfMonth: 31, dayOfYear: 31 }
expect ydToYmdd 1970 32 == { year: 1970, month: 2, dayOfMonth: 1, dayOfYear: 32 }
expect ydToYmdd 1970 60 == { year: 1970, month: 3, dayOfMonth: 1, dayOfYear: 60 }
expect ydToYmdd 1972 61 == { year: 1972, month: 3, dayOfMonth: 1, dayOfYear: 61 }

# <---- fromYmd ---->
expect fromYmd 1970 1 1 == { year: 1970, month: 1, dayOfMonth: 1, dayOfYear: 1 }
expect fromYmd 1970 12 31 == { year: 1970, month: 12, dayOfMonth: 31,  dayOfYear: 365 }
expect fromYmd 1972 3 1 == { year: 1972, month: 3, dayOfMonth: 1, dayOfYear: 61 }

# <---- fromYwd ---->
expect fromYwd 1970 1 1 == { year: 1970, month: 1, dayOfMonth: 1, dayOfYear: 1 }
expect fromYwd 1970 52 5 == { year: 1971, month: 1, dayOfMonth: 1, dayOfYear: 1 }

# <---- fromYw ---->
expect fromYw 1970 1 == { year: 1970, month: 1, dayOfMonth: 1, dayOfYear: 1 }
expect fromYw 1971 1 == { year: 1971, month: 1, dayOfMonth: 4, dayOfYear: 4 }

# <---- fromUtc ---->
expect
    utc = Utc.fromNanosSinceEpoch 0
    fromUtc utc == { year: 1970, month: 1, dayOfMonth: 1, dayOfYear: 1 }

expect
    utc = Utc.fromNanosSinceEpoch (Const.nanosPerHour * 24 * 365)
    fromUtc utc == { year: 1971, month: 1, dayOfMonth: 1, dayOfYear: 1 }

expect
    utc = Utc.fromNanosSinceEpoch (Const.nanosPerHour * 24 * 365 * 2 + Const.nanosPerHour * 24 * 366)
    fromUtc utc == { year: 1973, month: 1, dayOfMonth: 1, dayOfYear: 1 }

expect
    utc = Utc.fromNanosSinceEpoch (Const.nanosPerHour * 24 * -1)
    fromUtc utc == { year: 1969, month: 12, dayOfMonth: 31, dayOfYear: 365 }

expect
    utc = Utc.fromNanosSinceEpoch (Const.nanosPerHour * 24 * -365)
    fromUtc utc == { year: 1969, month: 1, dayOfMonth: 1, dayOfYear: 1 }

expect
    utc = Utc.fromNanosSinceEpoch (Const.nanosPerHour * 24 * -365 - Const.nanosPerHour * 24 * 366)
    fromUtc utc == { year: 1968, month: 1, dayOfMonth: 1, dayOfYear: 1 }

expect
    utc = Utc.fromNanosSinceEpoch -1
    fromUtc utc == { year: 1969, month: 12, dayOfMonth: 31, dayOfYear: 365 }

# <---- toUtc ---->
expect 
    utc = toUtc { year: 1970, month: 1, dayOfMonth: 1, dayOfYear: 1 } 
    utc == Utc.fromNanosSinceEpoch 0

expect 
    utc = toUtc { year: 1970, month: 12, dayOfMonth: 31, dayOfYear: 365 }
    utc == Utc.fromNanosSinceEpoch (Const.nanosPerHour * 24 * 364)

expect
    utc = toUtc { year: 1973, month: 1, dayOfMonth: 1, dayOfYear: 1 }
    utc == Utc.fromNanosSinceEpoch (Const.nanosPerHour * 24 * 365 * 2 + Const.nanosPerHour * 24 * 366)

expect
    utc = toUtc { year: 1969, month: 12, dayOfMonth: 31, dayOfYear: 365 }
    utc == Utc.fromNanosSinceEpoch (Const.nanosPerHour * 24 * -1)

expect
    utc = toUtc { year: 1969, month: 1, dayOfMonth: 1, dayOfYear: 1 }
    utc == Utc.fromNanosSinceEpoch (Const.nanosPerHour * 24 * -365)

expect
    utc = toUtc { year: 1968, month: 1, dayOfMonth: 1, dayOfYear: 1 }
    utc == Utc.fromNanosSinceEpoch (Const.nanosPerHour * 24 * -365 - Const.nanosPerHour * 24 * 366)

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
expect addDateAndDuration unixEpoch (Duration.fromDays 1 |> unwrap "will not overflow") == fromYmd 1970 1 2