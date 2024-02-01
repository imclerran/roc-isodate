interface UtcTime
    exposes [
        UtcTime,
        addTimes,
        deltaAsMillis,
        deltaAsNanos,
        toMillisSinceMidnight,
        toNanosSinceMidnight,
        fromMillisSinceMidnight,
        fromNanosSinceMidnight,
    ]
    imports []

## Stores a timestamp as nanoseconds since 00:00:00 of a given day
UtcTime := I64 implements [Inspect, Eq]

## Constant number of nanoseconds in a millisecond
nanosPerMilli = 1_000_000

## Convert UtcTime timestamp to milliseconds
toMillisSinceMidnight : UtcTime -> I64
toMillisSinceMidnight = \@UtcTime nanos ->
    nanos // nanosPerMilli

## Convert milliseconds to UtcTime timestamp
fromMillisSinceMidnight : I64 -> UtcTime
fromMillisSinceMidnight = \millis ->
    @UtcTime (millis * nanosPerMilli)

## Convert UtcTime timestamp to nanoseconds
toNanosSinceMidnight : UtcTime -> I64
toNanosSinceMidnight = \@UtcTime nanos -> 
    nanos

## Convert nanoseconds to UtcTime timestamp
fromNanosSinceMidnight : I64 -> UtcTime
fromNanosSinceMidnight = @UtcTime

## Calculate milliseconds between two UtcTime timestamps
deltaAsMillis : UtcTime, UtcTime -> U64
deltaAsMillis = \@UtcTime first, @UtcTime second ->
    firstCast = Num.bitwiseXor (Num.toU64 first) (Num.shiftLeftBy 1 63)
    secondCast = Num.bitwiseXor (Num.toU64 second) (Num.shiftLeftBy 1 63)
    (Num.absDiff firstCast secondCast) // nanosPerMilli

## Calculate nanoseconds between two UtcTime timestamps
deltaAsNanos : UtcTime, UtcTime -> U64
deltaAsNanos = \@UtcTime first, @UtcTime second ->
    firstCast = Num.bitwiseXor (Num.toU64 first) (Num.shiftLeftBy 1 63)
    secondCast = Num.bitwiseXor (Num.toU64 second) (Num.shiftLeftBy 1 63)
    Num.absDiff firstCast secondCast

addTimes : UtcTime, UtcTime -> UtcTime
addTimes = \@UtcTime first, @UtcTime second ->
    @UtcTime (first + second)


# TESTS
expect deltaAsNanos (fromNanosSinceMidnight 0) (fromNanosSinceMidnight 0) == 0
expect deltaAsNanos (fromNanosSinceMidnight 1) (fromNanosSinceMidnight 2) == 1
expect deltaAsNanos (fromNanosSinceMidnight -1) (fromNanosSinceMidnight 1) == 2
expect deltaAsNanos (fromNanosSinceMidnight Num.minI64) (fromNanosSinceMidnight Num.maxI64) == Num.maxU64

expect deltaAsMillis (fromMillisSinceMidnight 0) (fromMillisSinceMidnight 0) == 0
expect deltaAsMillis (fromNanosSinceMidnight 1) (fromNanosSinceMidnight 2) == 0
expect deltaAsMillis (fromMillisSinceMidnight 1) (fromMillisSinceMidnight 2) == 1
expect deltaAsMillis (fromMillisSinceMidnight -1) (fromMillisSinceMidnight 1) == 2
expect deltaAsMillis (fromNanosSinceMidnight Num.minI64) (fromNanosSinceMidnight Num.maxI64) == Num.maxU64 // nanosPerMilli