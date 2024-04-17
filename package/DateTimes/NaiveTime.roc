interface NaiveTime
    exposes [
        NaiveTime,
        fromHms,
        fromHmsn,
        toIsoStr,
        midnight,
    ]
    imports [
        Utils.{ flooredIntegerDivisionAndModulus },
        Conversion,
    ]

## A time of day, without a timezone.
NaiveTime : { hour : U8, minute : U8, second : U8, nanosecond : U32 }

# Constructors

## Y'know, the time of day, or rather time of night.
midnight : NaiveTime
midnight = { hour: 0u8, minute: 0u8, second: 0u8, nanosecond: 0u32 }

## Convert a number of hours, minutes, seconds, and nanoseconds into a NaiveTime.
fromHmsn : U8, U8, U8, U32 -> Result NaiveTime [InvalidTime]
fromHmsn = \hour, minute, second, nanosecond ->
    if
        (0 <= hour && hour < 24)
        && (0 <= minute && minute < 60)
        && (0 <= second && second < 60)
        && (0 <= nanosecond && nanosecond < 1_000_000_000)
    then
        Ok { hour: hour, minute: minute, second: second, nanosecond: nanosecond }
    else
        Err InvalidTime

expect
    out = fromHmsn 4u8 3u8 2u8 1u32
    out == Ok { hour: 4, minute: 3, second: 2, nanosecond: 1 }

## Convert a number of hours, minutes, seconds, and milliseconds into a NaiveTime.
fromHmsm : U8, U8, U8, U32 -> Result NaiveTime [InvalidTime]
fromHmsm = \hour, minute, second, millisecond -> fromHmsn hour minute second (1_000_000 * millisecond)

expect
    out = fromHmsm 4 3 2 1
    out == Ok { hour: 4, minute: 3, second: 2, nanosecond: 1_000_000u32 }

## Convert a number of hours, minutes, seconds, and microseconds into a NaiveTime.
fromHmsμ : U8, U8, U8, U32 -> Result NaiveTime [InvalidTime]
fromHmsμ = \hour, minute, second, microsecond -> fromHmsn hour minute second (1000 * microsecond)

expect
    out = fromHmsμ 4 3 2 1
    out == Ok { hour: 4, minute: 3, second: 2, nanosecond: 1000 }

## Convert a number of hours, minutes, and seconds into a NaiveTime.
fromHms : U8, U8, U8 -> Result NaiveTime [InvalidTime]
fromHms = \hour, minute, second -> fromHmsn hour minute second 0u32

expect
    out = fromHms 4 3 2
    out == Ok { hour: 4, minute: 3, second: 2, nanosecond: 0 }

## Convert a number of seconds after midnight into a NaiveTime.
fromSecondsAfterMidnight : U32, U32 -> Result NaiveTime [InvalidNumberOfSeconds, InvalidNanosecond]
fromSecondsAfterMidnight = \seconds, nanoseconds ->
    if (seconds >= (Conversion.daysToSeconds 1)) then
        Err InvalidNumberOfSeconds
    else if (nanoseconds >= (Conversion.secondsToNanoseconds 1)) then
        Err InvalidNanosecond
    else
        (hour, remainingSeconds) = flooredIntegerDivisionAndModulus seconds 24
        (minute, second) = flooredIntegerDivisionAndModulus remainingSeconds 60
        Ok { hour: Num.toU8 hour, minute: Num.toU8 minute, second: Num.toU8 second, nanosecond: nanoseconds }

expect fromSecondsAfterMidnight 0 0 == Ok midnight
expect fromSecondsAfterMidnight 123_456_789 0 == Err InvalidNumberOfSeconds
expect fromSecondsAfterMidnight 0 1_000_000_001 == Err InvalidNanosecond

## Parses a string in the format "T?[HH]:?[MM]:?[SS].[sss]" to a NaiveTime.
parseIsoStr : Str -> Result NaiveTime [InvalidIsoStr, InvalidTime]
parseIsoStr = \isoStr ->
    if Str.isEmpty isoStr then
        Err InvalidIsoStr
    else
        startsWithT = isoStr |> Str.startsWith "T"
        segments = (if startsWithT then (isoStr |> Str.replaceFirst "T" "") else isoStr) |> Str.split ":"
        nSegments = List.len segments
        (hours, minutes, seconds) =
            if nSegments == 1 then
                (Ok 1, Ok 2, Ok 3)
            else if nSegments == 3 then
                ((List.get segments 0) |> Result.try Str.toU8, (List.get segments 1) |> Result.try Str.toU8, (List.get segments 2) |> Result.try Str.toU8)
            else
                (Err InvalidIsoStr, Err InvalidIsoStr, Err InvalidIsoStr)
        if (Result.isOk hours) && (Result.isOk minutes) && (Result.isOk seconds) then
            fromHms (Result.withDefault hours 0) (Result.withDefault minutes 0) (Result.withDefault seconds 0)
        else
            Err InvalidIsoStr

expect
    out = parseIsoStr "01:02:03"
    out == (fromHms 1 2 3)

expect
    out = parseIsoStr "T01:02:03"
    out == (fromHms 1 2 3)

expect
    out = parseIsoStr "01:02:03:04"
    out == Err InvalidIsoStr

expect
    out = parseIsoStr "T01:02:03:04"
    out == Err InvalidIsoStr

# expect
#     out = parseIsoStr "01:02:03.456"
#     out == (fromHmsm 1 2 3 456)

# expect
#     out = parseIsoStr "T01:02:03.456"
#     out == (fromHmsm 1 2 3 456)

expect
    out = parseIsoStr "010203"
    out == (fromHms 1 2 3)

expect
    out = parseIsoStr "T010203"
    out == (fromHms 1 2 3)

# Methods

## withHour
withHour : NaiveTime, U8 -> Result NaiveTime [InvalidNumberOfHours]
withHour = \naiveTime, hour ->
    if (hour >= 24) then
        Err InvalidNumberOfHours
    else
        Ok {
            hour: hour,
            minute: naiveTime.minute,
            second: naiveTime.second,
            nanosecond: naiveTime.nanosecond,
        }

expect
    out = { hour: 1, minute: 2, second: 3, nanosecond: 4 } |> withHour 7
    out == Ok { hour: 7, minute: 2, second: 3, nanosecond: 4 }

expect
    out = midnight |> withHour 24
    out == Err InvalidNumberOfHours

## withMinute
withMinute : NaiveTime, U8 -> Result NaiveTime [InvalidNumberOfMinutes]
withMinute = \naiveTime, minute ->
    if (minute >= 60) then
        Err InvalidNumberOfMinutes
    else
        Ok {
            hour: naiveTime.hour,
            minute: minute,
            second: naiveTime.second,
            nanosecond: naiveTime.nanosecond,
        }

expect
    out = { hour: 1, minute: 2, second: 3, nanosecond: 4 } |> withMinute 7
    out == Ok { hour: 1, minute: 7, second: 3, nanosecond: 4 }

expect
    out = midnight |> withMinute 60
    out == Err InvalidNumberOfMinutes

## withSecond
withSecond : NaiveTime, U8 -> Result NaiveTime [InvalidNumberOfSeconds]
withSecond = \naiveTime, second ->
    if (second >= 60) then
        Err InvalidNumberOfSeconds
    else
        Ok {
            hour: naiveTime.hour,
            minute: naiveTime.minute,
            second: second,
            nanosecond: naiveTime.nanosecond,
        }

expect
    out = { hour: 1, minute: 2, second: 3, nanosecond: 4 } |> withSecond 7
    out == Ok { hour: 1, minute: 2, second: 7, nanosecond: 4 }

expect
    out = midnight |> withSecond 60
    out == Err InvalidNumberOfSeconds

## withMicrosecond
withMicrosecond : NaiveTime, U32 -> Result NaiveTime [InvalidNumberOfMicroseconds]
withMicrosecond = \naiveTime, microsecond ->
    if (microsecond >= (Conversion.secondsToMicroseconds 1)) then
        Err InvalidNumberOfMicroseconds
    else
        Ok {
            hour: naiveTime.hour,
            minute: naiveTime.minute,
            second: naiveTime.second,
            nanosecond: Conversion.microsecondsToNanoseconds microsecond,
        }

expect
    out = { hour: 1, minute: 2, second: 3, nanosecond: 4 } |> withMicrosecond 7
    out == Ok { hour: 1, minute: 2, second: 3, nanosecond: 7_000 }

expect
    out = midnight |> withMicrosecond 1_000_000
    out == Err InvalidNumberOfMicroseconds

## withNanosecond
withNanosecond : NaiveTime, U32 -> Result NaiveTime [InvalidNanosecond]
withNanosecond = \naiveTime, nanosecond ->
    if (nanosecond >= 1_000_000_000) then
        Err InvalidNanosecond
    else
        Ok {
            hour: naiveTime.hour,
            minute: naiveTime.minute,
            second: naiveTime.second,
            nanosecond: nanosecond,
        }

expect
    out = { hour: 1, minute: 2, second: 3, nanosecond: 4 } |> withNanosecond 7
    out == Ok { hour: 1, minute: 2, second: 3, nanosecond: 7 }

expect
    out = midnight |> withNanosecond 1_000_000_000
    out == Err InvalidNanosecond

## withNaiveDate
withNaiveDate : NaiveTime, _ -> _
withNaiveDate = \naiveTime, naiveDate -> { naiveDate: naiveDate, naiveTime: naiveTime }

expect
    out = midnight |> withNaiveDate { year: 1970, month: 1, day: 1 }
    out == { naiveDate: { year: 1970, month: 1, day: 1 }, naiveTime: midnight }

# ## add
# add : NaiveTime, Duration -> NaiveTime
# add = \naiveTime, duration -> {
#     hour: naiveTime.hour + (Duration.getHours duration),
#     minute: naiveTime.minute + Duration.getMinutes duration,
#     second: naiveTime.second + Duration.getSeconds duration,
#     nanosecond: naiveTime.nanosecond + Duration.getNanoseconds duration,
# }

# Serialise

## toIsoStr
toIsoStr : NaiveTime -> Str
toIsoStr = \naiveTime ->
    { hour, minute, second } = naiveTime
    hourStr = hour |> Utils.padIntegerToLength 2
    minuteStr = minute |> Utils.padIntegerToLength 2
    secondStr = second |> Utils.padIntegerToLength 2
    "\(hourStr):\(minuteStr):\(secondStr)"

expect
    out = midnight |> toIsoStr
    out == "00:00:00"

expect
    out = { hour: 1, minute: 2, second: 3, nanosecond: 4 } |> toIsoStr
    out == "01:02:03"
