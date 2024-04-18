interface DateTimes.NaiveDateTime
    exposes [
        NaiveDateTime,
        unixEpoch,
        fromYmdhmsn,
        fromYmdhms,
    ]
    imports [
        DateTimes.NaiveDate,
        DateTimes.NaiveDate.{ NaiveDate },
        DateTimes.NaiveTime,
        DateTimes.NaiveTime.{ NaiveTime },
        DateTimes.Utils,
    ]

## A date and time without a timezone.
NaiveDateTime : { naiveDate : NaiveDate, naiveTime : NaiveTime }

## The Unix epoch, 1970-01-01T00:00:00.
unixEpoch : NaiveDateTime
unixEpoch = { naiveDate: DateTimes.NaiveDate.unixEpoch, naiveTime: DateTimes.NaiveTime.midnight }

# Constructors

## Convert a year, month, day, hour, minute, second, and nanosecond to a NaiveDateTime.
fromYmdhmsn : I64, U8, U8, U8, U8, U8, U32 -> Result NaiveDateTime [InvalidDateTime]
fromYmdhmsn = \year, month, day, hour, minute, second, nanosecond ->
    naiveTime = DateTimes.NaiveTime.fromHmsn hour minute second nanosecond
    naiveDate = DateTimes.NaiveDate.fromYmd year month day
    if (Result.isOk naiveTime) && (Result.isOk naiveDate) then
        Ok {
            naiveDate: naiveDate |> Result.withDefault DateTimes.NaiveDate.unixEpoch,
            naiveTime: naiveTime |> Result.withDefault DateTimes.NaiveTime.midnight,
        }
    else
        Err InvalidDateTime

expect
    year = 7
    month = 6
    day = 5
    hour = 4
    minute = 3
    second = 2
    nanosecond = 1
    out = fromYmdhmsn year month day hour minute second nanosecond
    out
    == Ok {
        naiveDate: DateTimes.NaiveDate.fromYmd year month day |> DateTimes.Utils.unwrap "This should never happen because the date was hardcoded.",
        naiveTime: DateTimes.NaiveTime.fromHmsn hour minute second nanosecond |> DateTimes.Utils.unwrap "This should never happen because the date was hardcoded.",
    }

## Convert a year, month, day, hour, minute, and second to a NaiveDateTime.
fromYmdhms : I64, U8, U8, U8, U8, U8 -> Result NaiveDateTime [InvalidDateTime]
fromYmdhms = \year, month, day, hour, minute, second ->
    fromYmdhmsn year month day hour minute second 0

expect
    year = 6
    month = 5
    day = 4
    hour = 3
    minute = 2
    second = 1
    out = fromYmdhms year month day hour minute second
    out
    == Ok {
        naiveDate: DateTimes.NaiveDate.fromYmd year month day
        |> DateTimes.Utils.unwrap "This should never happen because the date was hardcoded.",
        naiveTime: DateTimes.NaiveTime.fromHms hour minute second
        |> DateTimes.Utils.unwrap "This should never happen because the date was hardcoded.",
    }

# Methods

# ## add
# add : NaiveDateTime, Duration -> NaiveDateTime
# add = \naiveDateTime, duration ->
