interface DateTime
    exposes [
        fromNanosSinceEpoch,
        fromUtc,
        fromYd,
        fromYmd,
        fromYw,
        fromYwd,
        fromYmdhms,
        fromYmdhmsn,
        toNanosSinceEpoch,
        toUtc,
        unixEpoch,
    ]
    imports [
        Const,
        Date,
        Time,
        Utc,
        Utc.{ Utc },
        UtcTime,
    ]

DateTime : { date : Date.Date, time : Time.Time }

unixEpoch : DateTime
unixEpoch = { date: Date.unixEpoch, time: Time.midnight }

fromYd : Int *, Int * -> DateTime
fromYd = \year, day -> { date: Date.fromYd year day, time: Time.midnight }

fromYmd : Int *, Int *, Int * -> DateTime
fromYmd = \year, month, day -> { date: Date.fromYmd year month day, time: Time.midnight }

fromYwd : Int *, Int *, Int * -> DateTime
fromYwd = \year, week, day -> { date: Date.fromYwd year week day, time: Time.midnight }

fromYw : Int *, Int * -> DateTime
fromYw = \year, week -> { date: Date.fromYw year week, time: Time.midnight }

fromYmdhms : Int *, Int *, Int *, Int *, Int *, Int * -> DateTime
fromYmdhms = \year, month, day, hour, minute, second ->
    { date: Date.fromYmd year month day, time: Time.fromHms hour minute second }

fromYmdhmsn : Int *, Int *, Int *, Int *, Int *, Int *, Int * -> DateTime
fromYmdhmsn = \year, month, day, hour, minute, second, nanosecond ->
    { date: Date.fromYmd year month day, time: Time.fromHmsn hour minute second nanosecond }

toUtc : DateTime -> Utc
toUtc =\ dateTime ->
    dateNanos = Date.toUtc dateTime.date |> Utc.toNanosSinceEpoch
    timeNanos = Time.toUtcTime dateTime.time |> UtcTime.toNanosSinceMidnight |> Num.toI128
    Utc.fromNanosSinceEpoch (dateNanos + timeNanos)

expect
    utc = toUtc (fromYmdhmsn 1970 12 31 12 34 56 5)
    utc == Utc.fromNanosSinceEpoch (364 * 24 * 60 * 60 * 1_000_000_000 + 12 * 60 * 60 * 1_000_000_000 + 34 * 60 * 1_000_000_000 + 56 * 1_000_000_000 + 5)

fromUtc : Utc -> DateTime
fromUtc = \utc ->
    nanos = Utc.toNanosSinceEpoch utc
    timeNanos = if nanos < 0 && nanos % (Const.nanosPerHour * 24) != 0 then
        nanos % (Const.nanosPerHour * 24) + Const.nanosPerHour * 24 else nanos % (Const.nanosPerHour * 24)
    dateNanos = nanos - timeNanos |> Num.toI128
    date = dateNanos |> Num.toI128 |> Utc.fromNanosSinceEpoch |> Date.fromUtc
    time = timeNanos |> Num.toI64 |> UtcTime.fromNanosSinceMidnight |> Time.fromUtcTime
    { date, time }

toNanosSinceEpoch : DateTime -> I128
toNanosSinceEpoch = \dateTime -> toUtc dateTime |> Utc.toNanosSinceEpoch

fromNanosSinceEpoch : Int * -> DateTime
fromNanosSinceEpoch = \nanos -> Utc.fromNanosSinceEpoch (Num.toI128 nanos) |> fromUtc

expect
    dateTime = fromUtc (Utc.fromNanosSinceEpoch (364 * 24 * Const.nanosPerHour + 12 * Const.nanosPerHour + 34 * Const.nanosPerMinute + 56 * Const.nanosPerSecond + 5))
    dateTime == fromYmdhmsn 1970 12 31 12 34 56 5

expect
    dateTime = fromUtc (Utc.fromNanosSinceEpoch (-1))
    dateTime == fromYmdhmsn 1969 12 31 23 59 59 (Const.nanosPerSecond - 1)