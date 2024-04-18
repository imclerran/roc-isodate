interface Date
    exposes [
        Date,
        fromYmd,
        fromYw,
        fromYwd,
        unixEpoch,
    ]
    imports [
        Utc,
        Utils.{
            isLeapYear,
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

fromUtc : Utc -> Date

toUtc : Date -> Utc
        


