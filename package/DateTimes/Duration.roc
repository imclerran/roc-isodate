interface Duration
    exposes [
        add,
        Duration,
        fromDays,
        fromHours,
        fromMicroseconds,
        fromMilliseconds,
        fromMinutes,
        fromNanoseconds,
        fromSeconds,
        fromWeeks,
        max,
        min,
        toNanoseconds,
        toWholeDays,
        toWholeHours,
        toWholeMinutes,
        toWholeSeconds,
        toWholeWeeks,
        zero,
    ]
    imports [
        Utils,
        Conversion,
    ]

## An amount of time measured to the nanosecond.
##
## The maximum value of this type is Num.maxI64 seconds + 999_999_999 nanoseconds, approximately 292 billion years.
## The minimum value of this type is Num.minI64 seconds, approximately -292 billion years.
Duration : { seconds : I64, nanoseconds : U32 }

# Constructors

## Zero duration.
zero = { seconds: 0, nanoseconds: 0 }

## The maximum possible duration, approximately 292 billion years
max : Duration
max = { seconds: Num.maxI64, nanoseconds: 999_999_999 }

## The minimum possible duration, approximately -292 billion years.
min : Duration
min = { seconds: Num.minI64, nanoseconds: 0 }

## Convert a number of nanoseconds to a duration.
fromNanoseconds : I64 -> Duration
fromNanoseconds = \nanoseconds ->
    (seconds, nanosecondsRemainder) = Utils.flooredIntegerDivisionAndModulus nanoseconds Conversion.nanosecondsInASecond
    if Num.isNegative nanosecondsRemainder then
        {
            seconds: (seconds - 1),
            nanoseconds: Num.toU32 (Conversion.nanosecondsInASecond + nanosecondsRemainder),
        }
    else
        {
            seconds: seconds,
            nanoseconds: Num.toU32 nanosecondsRemainder,
        }

expect
    out = fromNanoseconds 123
    out == { seconds: 0, nanoseconds: 123 }

expect
    out = fromNanoseconds -123
    out == { seconds: -1, nanoseconds: 999_999_877 }

expect
    out = fromNanoseconds Num.maxI64
    out == { seconds: 9_223_372_036, nanoseconds: 854_775_807 }

expect
    out = fromNanoseconds Num.minI64
    out == { seconds: -9_223_372_037, nanoseconds: 145_224_192 }

## Convert a number of milliseconds to a duration.
fromMilliseconds : I64 -> Duration
fromMilliseconds = \milliseconds ->
    (seconds, millisecondsRemainder) = Utils.flooredIntegerDivisionAndModulus milliseconds Conversion.nanosecondsInAMillisecond
    if Num.isNegative millisecondsRemainder then
        {
            seconds: (seconds - 1),
            nanoseconds: Num.toU32 (Conversion.nanosecondsInASecond + (Conversion.millisecondsToNanoseconds millisecondsRemainder)),
        }
    else
        {
            seconds: seconds,
            nanoseconds: Num.toU32 (Conversion.millisecondsToNanoseconds millisecondsRemainder),
        }

expect
    out = fromMilliseconds 123
    out == { seconds: 0, nanoseconds: 123_000_000 }

expect
    out = fromMilliseconds -123
    out == { seconds: -1, nanoseconds: 877_000_000 }

expect
    out = fromMilliseconds Num.maxI64
    out == { seconds: 9_223_372_036_854, nanoseconds: 2_712_886_720 }

expect
    out = fromMilliseconds Num.minI64
    out == { seconds: -9_223_372_036_855, nanoseconds: 2_581_080_576 }

## Convert a number of microseconds to a duration.
fromMicroseconds : I64 -> Duration
fromMicroseconds = \microseconds ->
    (seconds, microsecondsRemainder) = Utils.flooredIntegerDivisionAndModulus microseconds Conversion.microsecondsInASecond
    if Num.isNegative microsecondsRemainder then
        {
            seconds: (seconds - 1),
            nanoseconds: Num.toU32 (Conversion.nanosecondsInASecond + (Conversion.microsecondsToNanoseconds microsecondsRemainder)),
        }
    else
        {
            seconds: seconds,
            nanoseconds: Num.toU32 (Conversion.microsecondsToNanoseconds microsecondsRemainder),
        }

expect
    out = fromMicroseconds 123
    out == { seconds: 0, nanoseconds: 123_000 }

expect
    out = fromMicroseconds -123
    out == { seconds: -1, nanoseconds: 999_877_000 }

expect
    out = fromMicroseconds Num.maxI64
    out == { seconds: 9_223_372_036_854, nanoseconds: 775_807_000 }

expect
    out = fromMicroseconds Num.minI64
    out == { seconds: -9_223_372_036_855, nanoseconds: 224_192_000 }

## Convert a number of seconds to a duration.
fromSeconds : I64 -> Duration
fromSeconds = \seconds -> { seconds, nanoseconds: 0 }

expect
    out = fromSeconds 123
    out == { seconds: 123, nanoseconds: 0 }

expect
    out = fromSeconds Num.maxI64
    out == { seconds: Num.maxI64, nanoseconds: 0 }

expect
    out = fromSeconds Num.minI64
    out == { seconds: Num.minI64, nanoseconds: 0 }

## Convert a number of minutes to a duration.
fromMinutes : I32 -> Duration
fromMinutes = \minutes -> { seconds: Conversion.minutesToSeconds (Num.toI64 minutes), nanoseconds: 0 }

expect
    out = fromMinutes 123
    out == { seconds: 7380, nanoseconds: 0 }

expect
    out = fromMinutes Num.maxI32
    out == { seconds: 128_849_018_820, nanoseconds: 0 }

expect
    out = fromMinutes Num.minI32
    out == { seconds: -128_849_018_880, nanoseconds: 0 }

## Convert a number of hours to a duration.
fromHours : I32 -> Duration
fromHours = \hours -> { seconds: Conversion.hoursToSeconds (Num.toI64 hours), nanoseconds: 0 }

expect
    out = fromHours 123
    out == { seconds: 442_800, nanoseconds: 0 }

expect
    out = fromHours Num.maxI32
    out == { seconds: 7_730_941_129_200, nanoseconds: 0 }

expect
    out = fromHours Num.minI32
    out == { seconds: -7_730_941_132_800, nanoseconds: 0 }

## Convert a number of days to a duration.
fromDays : I32 -> Duration
fromDays = \days -> { seconds: Conversion.daysToSeconds (Num.toI64 days), nanoseconds: 0 }

expect
    out = fromDays 123
    out == { seconds: 10_627_200, nanoseconds: 0 }

expect
    out = fromDays Num.maxI32
    out == { seconds: 185_542_587_100_800, nanoseconds: 0 }

expect
    out = fromDays Num.minI32
    out == { seconds: -185_542_587_187_200, nanoseconds: 0 }

## Convert a number of weeks to a duration.
fromWeeks : I32 -> Duration
fromWeeks = \weeks -> { seconds: Conversion.weeksToSeconds (Num.toI64 weeks), nanoseconds: 0 }

expect
    out = fromWeeks 123
    out == { seconds: 74_390_400, nanoseconds: 0 }

expect
    out = fromWeeks Num.maxI32
    out == { seconds: 1_298_798_109_705_600, nanoseconds: 0 }

expect
    out = fromWeeks Num.minI32
    out == { seconds: -1_298_798_110_310_400, nanoseconds: 0 }

# Methods

## Get the number of nanoseconds in the duration.
toNanoseconds : Duration -> I128
toNanoseconds = \duration -> Conversion.secondsToNanoseconds (Num.toI128 duration.seconds) + Num.toI128 duration.nanoseconds

expect
    out = toNanoseconds zero
    out == 0

expect
    halfASecond = { seconds: 0, nanoseconds: 500_000_000 }
    out = toNanoseconds halfASecond
    out == 500_000_000

expect
    oneSecond = { seconds: 1, nanoseconds: 0 }
    out = toNanoseconds oneSecond
    out == 1_000_000_000

expect
    negativeOneSecond = { seconds: -1, nanoseconds: 0 }
    out = toNanoseconds negativeOneSecond
    out == -1_000_000_000

expect
    oneAndAHalfSeconds = { seconds: 1, nanoseconds: 500_000_000 }
    out = toNanoseconds oneAndAHalfSeconds
    out == 1_500_000_000

expect
    negativeHalfASecond = { seconds: -1, nanoseconds: 500_000_000 }
    out = toNanoseconds negativeHalfASecond
    out == -500_000_000

expect
    out = toNanoseconds min
    out == Num.minI64 |> Num.toI128 |> Conversion.secondsToNanoseconds

expect
    out = toNanoseconds max
    out == Num.maxI64 |> Num.toI128 |> Conversion.secondsToNanoseconds |> Num.add 999_999_999

## Get the number of whole microseconds in the duration, rounded towards zero.
toWholeMicroseconds : Duration -> I64
toWholeMicroseconds = \duration ->
    Conversion.secondsToMicroseconds duration.seconds + Num.toI64 (Conversion.nanosecondsToWholeMicroseconds duration.nanoseconds)

expect
    out = toWholeMicroseconds zero
    out == 0

expect
    halfASecond = { seconds: 0, nanoseconds: 500_000_000 }
    out = toWholeMicroseconds halfASecond
    out == 500_000

expect
    oneSecond = { seconds: 1, nanoseconds: 0 }
    out = toWholeMicroseconds oneSecond
    out == 1_000_000

expect
    oneAndAHalfSeconds = { seconds: 1, nanoseconds: 500_000_000 }
    out = toWholeMicroseconds oneAndAHalfSeconds
    out == 1_500_000

expect
    negativeOneSecond = { seconds: -1, nanoseconds: 0 }
    out = toWholeMicroseconds negativeOneSecond
    out == -1_000_000

expect
    negativeHalfASecond = { seconds: -1, nanoseconds: 500_000_000 }
    out = toWholeMicroseconds negativeHalfASecond
    out == -500_000

## Get the number of whole milliseconds in the duration, rounded towards zero.
toWholeMilliseconds : Duration -> I64
toWholeMilliseconds = \duration ->
    Conversion.secondsToMilliseconds duration.seconds + Conversion.nanosecondsToWholeMilliseconds (Num.toI64 duration.nanoseconds)

expect
    out = toWholeMilliseconds zero
    out == 0

expect
    halfASecond = { seconds: 0, nanoseconds: 500_000_000 }
    out = toWholeMilliseconds halfASecond
    out == 500

expect
    oneSecond = { seconds: 1, nanoseconds: 0 }
    out = toWholeMilliseconds oneSecond
    out == 1_000

expect
    oneAndAHalfSeconds = { seconds: 1, nanoseconds: 500_000_000 }
    out = toWholeMilliseconds oneAndAHalfSeconds
    out == 1_500

expect
    negativeOneSecond = { seconds: -1, nanoseconds: 0 }
    out = toWholeMilliseconds negativeOneSecond
    out == -1_000

expect
    negativeHalfASecond = { seconds: -1, nanoseconds: 500_000_000 }
    out = toWholeMilliseconds negativeHalfASecond
    out == -500

## Get the number of whole seconds in the duration, rounded towards zero.
toWholeSeconds : Duration -> I64
toWholeSeconds = \duration ->
    if (Num.isNegative duration.seconds) && (Num.isPositive duration.nanoseconds) then
        duration.seconds + 1
    else
        duration.seconds

expect
    out = toWholeSeconds zero
    out == 0

expect
    halfASecond = { seconds: 0, nanoseconds: 500_000_000 }
    out = toWholeSeconds halfASecond
    out == 0

expect
    oneSecond = { seconds: 1, nanoseconds: 0 }
    out = toWholeSeconds oneSecond
    out == 1

expect
    oneAndAHalfSeconds = { seconds: 1, nanoseconds: 500_000_000 }
    out = toWholeSeconds oneAndAHalfSeconds
    out == 1

expect
    negativeOneSecond = { seconds: -1, nanoseconds: 0 }
    out = toWholeSeconds negativeOneSecond
    out == -1

expect
    negativeHalfASecond = { seconds: -1, nanoseconds: 500_000_000 }
    out = toWholeSeconds negativeHalfASecond
    out == 0

expect
    out = toWholeSeconds min
    out == Num.minI64

## Get the number of whole minutes in the duration, rounded towards zero.
toWholeMinutes : Duration -> I64
toWholeMinutes = \duration -> duration |> toWholeSeconds |> Conversion.secondsToWholeMinutes

expect
    out = toWholeMinutes zero
    out == 0

expect
    zeroAndABit = { seconds: 0, nanoseconds: 1 }
    out = toWholeMinutes zeroAndABit
    out == 0

expect
    oneMinute = { seconds: 60, nanoseconds: 0 }
    out = toWholeMinutes oneMinute
    out == 1

expect
    oneMinuteAndABit = { seconds: 90, nanoseconds: 1 }
    out = toWholeMinutes oneMinuteAndABit
    out == 1

expect
    negativeOneMinute = { seconds: -60, nanoseconds: 0 }
    out = toWholeMinutes negativeOneMinute
    out == -1

expect
    negativeOneMinutePlusABit = { seconds: -60, nanoseconds: 1 }
    out = toWholeMinutes negativeOneMinutePlusABit
    out == 0

## Get the number of whole hours in the duration, rounded towards zero.
toWholeHours : Duration -> I64
toWholeHours = \duration -> duration |> toWholeSeconds |> Conversion.secondsToWholeHours

expect
    out = toWholeHours zero
    out == 0

expect
    zeroAndABit = { seconds: 0, nanoseconds: 1 }
    out = toWholeHours zeroAndABit
    out == 0

expect
    oneHour = { seconds: 3_600, nanoseconds: 0 }
    out = toWholeHours oneHour
    out == 1

expect
    oneHourAndABit = { seconds: 3_600, nanoseconds: 1 }
    out = toWholeHours oneHourAndABit
    out == 1

expect
    negativeOneHour = { seconds: -3_600, nanoseconds: 0 }
    out = toWholeHours negativeOneHour
    out == -1

expect
    negativeOneHourPlusABit = { seconds: -3_600, nanoseconds: 1 }
    out = toWholeHours negativeOneHourPlusABit
    out == 0

## Get the number of whole days in the duration, rounded towards zero.
toWholeDays : Duration -> I64
toWholeDays = \duration -> duration |> toWholeSeconds |> Conversion.secondsToWholeDays

expect
    out = toWholeDays zero
    out == 0

expect
    zeroAndABit = { seconds: 0, nanoseconds: 1 }
    out = toWholeDays zeroAndABit
    out == 0

expect
    oneDay = { seconds: 86_400, nanoseconds: 0 }
    out = toWholeDays oneDay
    out == 1

expect
    oneDayAndABit = { seconds: 86_400, nanoseconds: 1 }
    out = toWholeDays oneDayAndABit
    out == 1

expect
    negativeOneDay = { seconds: -86_400, nanoseconds: 0 }
    out = toWholeDays negativeOneDay
    out == -1

expect
    negativeOneDayPlusABit = { seconds: -86_400, nanoseconds: 1 }
    out = toWholeDays negativeOneDayPlusABit
    out == 0

## Get the number of whole weeks in the duration, rounded towards zero.
toWholeWeeks : Duration -> I64
toWholeWeeks = \duration -> duration |> toWholeSeconds |> Conversion.secondsToWholeWeeks

expect
    out = toWholeWeeks zero
    out == 0

expect
    zeroAndABit = { seconds: 0, nanoseconds: 1 }
    out = toWholeWeeks zeroAndABit
    out == 0

expect
    oneWeek = { seconds: 604_800, nanoseconds: 0 }
    out = toWholeWeeks oneWeek
    out == 1

expect
    oneWeekAndABit = { seconds: 604_800, nanoseconds: 1 }
    out = toWholeWeeks oneWeekAndABit
    out == 1

expect
    negativeOneWeek = { seconds: -604_800, nanoseconds: 0 }
    out = toWholeWeeks negativeOneWeek
    out == -1

expect
    negativeOneWeekPlusABit = { seconds: -604_800, nanoseconds: 1 }
    out = toWholeWeeks negativeOneWeekPlusABit
    out == 0

## Add two durations together.
add : Duration, Duration -> Duration
add = \a, b ->
    seconds = a.seconds + b.seconds
    nanoseconds = a.nanoseconds + b.nanoseconds
    if (nanoseconds >= (Conversion.secondsToNanoseconds 1)) then
        { seconds: seconds + 1, nanoseconds: nanoseconds - (Conversion.secondsToNanoseconds 1) }
    else
        { seconds, nanoseconds }

expect
    oneSecond = { seconds: 1, nanoseconds: 0 }
    twoSeconds = { seconds: 2, nanoseconds: 0 }
    threeSeconds = { seconds: 3, nanoseconds: 0 }
    out = add oneSecond twoSeconds
    out == threeSeconds

expect
    oneAndAHalfSeconds = { seconds: 1, nanoseconds: 500_000_000 }
    threeSeconds = { seconds: 3, nanoseconds: 0 }
    out = add oneAndAHalfSeconds oneAndAHalfSeconds
    out == threeSeconds

expect
    oneSecond = { seconds: 1, nanoseconds: 0 }
    negativeTwoSeconds = { seconds: -2, nanoseconds: 0 }
    negativeOneSecond = { seconds: -1, nanoseconds: 0 }
    out = add oneSecond negativeTwoSeconds
    out == negativeOneSecond
