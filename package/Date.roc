interface Date
    exposes [
        Date,
        fromUtc,
        fromYmd,
        fromYw,
        fromYwd,
        toUtc,
        unixEpoch,
    ]
    imports [
        Const,
        Utc,
        Utils.{
            isLeapYear,
            numDaysSinceEpoch,
            ymdToDaysInYear,
            calendarWeekToDaysInYear,
        }
    ]

Date : { year: I64, dayOfYear: U16 }

unixEpoch : Date
unixEpoch = { year: 1970, dayOfYear: 1 }

fromYmd : Int *, Int *, Int * -> Date
fromYmd =\year, month, day -> 
    { year: Num.toI64 year, dayOfYear: ymdToDaysInYear year month day }

expect 
    fromYmd 1970 1 1 == { year: 1970, dayOfYear: 1 }

fromYwd : Int *, Int *, Int * -> Date
fromYwd = \year, week, day ->
    daysInYear = if isLeapYear year then 366 else 365
    d = calendarWeekToDaysInYear week year |> Num.add (Num.toU64 day)
    if d > daysInYear then
        { year: Num.toI64 (year + 1), dayOfYear: Num.toU16 (d - daysInYear) }
    else
        { year: Num.toI64 year, dayOfYear: Num.toU16 d }

expect fromYwd 1970 1 1 == { year: 1970, dayOfYear: 1 }
expect fromYwd 1970 52 5 == { year: 1971, dayOfYear: 1 }

fromYw : Int *, Int * -> Date
fromYw = \year, week ->
    fromYwd year week 1

expect fromYw 1970 1 == { year: 1970, dayOfYear: 1 }

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
            { year: year, dayOfYear: days + 1 |> Num.toU16 }

expect
    utc = Utc.fromNanosSinceEpoch 0
    fromUtc utc == { year: 1970, dayOfYear: 1 }

expect
    utc = Utc.fromNanosSinceEpoch (Const.nanosPerHour * 24 * 365)
    fromUtc utc == { year: 1971, dayOfYear: 1 }

expect
    utc = Utc.fromNanosSinceEpoch (Const.nanosPerHour * 24 * 365 * 2 + Const.nanosPerHour * 24 * 366)
    fromUtc utc == { year: 1973, dayOfYear: 1 }

expect
    utc = Utc.fromNanosSinceEpoch (Const.nanosPerHour * 24 * -1)
    fromUtc utc == { year: 1969, dayOfYear: 365 }

expect
    utc = Utc.fromNanosSinceEpoch (Const.nanosPerHour * 24 * -365)
    fromUtc utc == { year: 1969, dayOfYear: 1 }

expect
    utc = Utc.fromNanosSinceEpoch (Const.nanosPerHour * 24 * -365 - Const.nanosPerHour * 24 * 366)
    fromUtc utc == { year: 1968, dayOfYear: 1 }

expect
    utc = Utc.fromNanosSinceEpoch -1
    fromUtc utc == { year: 1969, dayOfYear: 365 }

toUtc : Date -> Utc.Utc
toUtc =\date ->
    days = numDaysSinceEpoch {year: date.year |> Num.toU64, month: 1, day: 1} + (date.dayOfYear - 1 |> Num.toI64)
    Utc.fromNanosSinceEpoch (days |> Num.toI128 |> Num.mul (Const.nanosPerHour * 24))

expect 
    utc = toUtc { year: 1970, dayOfYear: 1 } 
    utc == Utc.fromNanosSinceEpoch 0

expect 
    utc = toUtc { year: 1970, dayOfYear: 365 }
    utc == Utc.fromNanosSinceEpoch (Const.nanosPerHour * 24 * 364)

expect
    utc = toUtc { year: 1973, dayOfYear: 1 }
    utc == Utc.fromNanosSinceEpoch (Const.nanosPerHour * 24 * 365 * 2 + Const.nanosPerHour * 24 * 366)

expect
    utc = toUtc { year: 1969, dayOfYear: 365 }
    utc == Utc.fromNanosSinceEpoch (Const.nanosPerHour * 24 * -1)

expect
    utc = toUtc { year: 1969, dayOfYear: 1 }
    utc == Utc.fromNanosSinceEpoch (Const.nanosPerHour * 24 * -365)

expect
    utc = toUtc { year: 1968, dayOfYear: 1 }
    utc == Utc.fromNanosSinceEpoch (Const.nanosPerHour * 24 * -365 - Const.nanosPerHour * 24 * 366)
