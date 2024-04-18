interface DateTime
    exposes [
        fromYmd,
        fromYw,
        fromYwd,
    ]
    imports [
        Date,
        Time,
    ]

DateTime : { date: Date.Date, time: Time.Time }

fromYmd : Int *, Int *, Int * -> DateTime
fromYmd =\year, month, day -> 
    { date: Date.fromYmd year month day, time: Time.midnight }

expect 
    dateTime = fromYmd 1970 1 1
    dateTime.date.year == 1970 &&
    dateTime.date.dayOfYear == 1 &&
    dateTime.time == Time.midnight

expect 
    dateTime = fromYmd 1970 12 31
    dateTime.date.year == 1970 &&
    dateTime.date.dayOfYear == 365 &&
    dateTime.time == Time.midnight

fromYwd : Int *, Int *, Int * -> DateTime
fromYwd = \year, week, day ->
    { date: Date.fromYwd year week day, time: Time.midnight }

expect 
    dateTime = fromYwd 1970 1 1
    dateTime.date.year == 1970 &&
    dateTime.date.dayOfYear == 1 &&
    dateTime.time == Time.midnight

expect
    dateTime = fromYwd 1970 52 4
    dateTime.date.year == 1970 &&
    dateTime.date.dayOfYear == 365 &&
    dateTime.time == Time.midnight

fromYw : Int *, Int * -> DateTime
fromYw = \year, week ->
    { date: Date.fromYw year week, time: Time.midnight }

expect 
    dateTime = fromYw 1970 1 
    dateTime.date.year == 1970 &&
    dateTime.date.dayOfYear == 1 &&
    dateTime.time == Time.midnight


