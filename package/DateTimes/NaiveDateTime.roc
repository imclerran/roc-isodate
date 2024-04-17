interface NaiveDateTime
    exposes [
        NaiveDateTime,
        unixEpoch,
        fromYmdhmsn,
        fromYmdhms,
    ]
    imports [
        NaiveDate,
        NaiveDate.{ NaiveDate },
        NaiveTime,
        NaiveTime.{ NaiveTime },
        Utils,
    ]

## A date and time without a timezone.
NaiveDateTime : { naiveDate : NaiveDate.NaiveDate, naiveTime : NaiveTime.NaiveTime }

## The Unix epoch, 1970-01-01T00:00:00.
unixEpoch : NaiveDateTime
unixEpoch = { naiveDate: NaiveDate.unixEpoch, naiveTime: NaiveTime.midnight }

# Constructors

## Convert a year, month, day, hour, minute, second, and nanosecond to a NaiveDateTime.
fromYmdhmsn : I64, U8, U8, U8, U8, U8, U32 -> Result NaiveDateTime [InvalidDateTime]
fromYmdhmsn = \year, month, day, hour, minute, second, nanosecond ->
    naiveTime = NaiveTime.fromHmsn hour minute second nanosecond
    naiveDate = NaiveDate.fromYmd year month day
    if (Result.isOk naiveTime) && (Result.isOk naiveDate) then
        Ok {
            naiveDate: naiveDate |> Result.withDefault NaiveDate.unixEpoch,
            naiveTime: naiveTime |> Result.withDefault NaiveTime.midnight,
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
        naiveDate: NaiveDate.fromYmd year month day |> Utils.unwrap "This should never happen because the date was hardcoded.",
        naiveTime: NaiveTime.fromHmsn hour minute second nanosecond |> Utils.unwrap "This should never happen because the date was hardcoded.",
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
        naiveDate: NaiveDate.fromYmd year month day
        |> Utils.unwrap "This should never happen because the date was hardcoded.",
        naiveTime: NaiveTime.fromHms hour minute second
        |> Utils.unwrap "This should never happen because the date was hardcoded.",
    }

# Methods

# ## add
# add : NaiveDateTime, Duration -> NaiveDateTime
# add = \naiveDateTime, duration ->
