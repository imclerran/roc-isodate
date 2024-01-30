interface UtcTime
    exposes [
        UtcTime,
        toMillisSinceMidnight,
        fromMillisSinceMidnight,
        toNanosSinceMidnight,
        fromNanosSinceMidnight,
        deltaAsMillis,
        deltaAsNanos,
    ]
    imports []

## Stores a timestamp as nanoseconds since 00:00:00 of a given day
UtcTime := U64 implements [Inspect, Eq]

## Constant number of nanoseconds in a millisecond
nanosPerMilli = 1_000_000

## Convert UtcTime timestamp to milliseconds
toMillisSinceMidnight : UtcTime -> U64
toMillisSinceMidnight = \@UtcTime nanos ->
    nanos // nanosPerMilli

## Convert milliseconds to UtcTime timestamp
fromMillisSinceMidnight : U64 -> UtcTime
fromMillisSinceMidnight = \millis ->
    @UtcTime (millis * nanosPerMilli)

## Convert UtcTime timestamp to nanoseconds
toNanosSinceMidnight : UtcTime -> U64
toNanosSinceMidnight = \@UtcTime nanos -> 
    nanos

## Convert nanoseconds to UtcTime timestamp
fromNanosSinceMidnight : U64 -> UtcTime
fromNanosSinceMidnight = @UtcTime

## Calculate milliseconds between two UtcTime timestamps
deltaAsMillis : UtcTime, UtcTime -> U64
deltaAsMillis = \@UtcTime first, @UtcTime second ->
    (Num.absDiff first second) // nanosPerMilli

## Calculate nanoseconds between two UtcTime timestamps
deltaAsNanos : UtcTime, UtcTime -> U64
deltaAsNanos = \@UtcTime first, @UtcTime second ->
    Num.absDiff first second