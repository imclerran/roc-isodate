interface Conversion
    exposes [
        daysInAWeek,
        daysToSeconds,
        hoursInADay,
        hoursToSeconds,
        microsecondsInAMillisecond,
        microsecondsInASecond,
        microsecondsToNanoseconds,
        microsecondsToWholeMilliseconds,
        microsecondsToWholeSeconds,
        millisecondsInASecond,
        millisecondsToMicroseconds,
        millisecondsToNanoseconds,
        millisecondsToWholeSeconds,
        minutesInAnHour,
        minutesToSeconds,
        nanosecondsInAMicrosecond,
        nanosecondsInAMillisecond,
        nanosecondsInASecond,
        nanosecondsToWholeMilliseconds,
        nanosecondsToWholeSeconds,
        nanosecondsToWholeMicroseconds,
        secondsInAMinute,
        secondsInAWeek,
        secondsInADay,
        secondsInAnHour,
        secondsToMicroseconds,
        secondsToMilliseconds,
        secondsToNanoseconds,
        secondsToWholeDays,
        secondsToWholeHours,
        secondsToWholeMinutes,
        secondsToWholeWeeks,
        weeksToSeconds,
    ]
    imports []

# Constants

nanosecondsInAMicrosecond = 1_000
microsecondsInAMillisecond = 1_000
millisecondsInASecond = 1_000
secondsInAMinute = 60
minutesInAnHour = 60
hoursInADay = 24
daysInAWeek = 7

microsecondsInASecond = microsecondsInAMillisecond * millisecondsInASecond
nanosecondsInAMillisecond = nanosecondsInAMicrosecond * microsecondsInAMillisecond
nanosecondsInASecond = nanosecondsInAMicrosecond * microsecondsInASecond
secondsInADay = secondsInAMinute * minutesInAnHour * hoursInADay
secondsInAnHour = secondsInAMinute * minutesInAnHour
secondsInAWeek = secondsInAMinute * minutesInAnHour * hoursInADay * daysInAWeek

# Nanoseconds

nanosecondsToWholeMilliseconds = \nanoseconds -> nanoseconds // nanosecondsInAMillisecond
nanosecondsToWholeSeconds = \nanoseconds -> nanoseconds // nanosecondsInASecond
nanosecondsToWholeMicroseconds = \nanoseconds -> nanoseconds // nanosecondsInAMicrosecond

# Microseconds

microsecondsToNanoseconds = \microseconds -> microseconds * nanosecondsInAMicrosecond
microsecondsToWholeMilliseconds = \microseconds -> microseconds // microsecondsInAMillisecond
microsecondsToWholeSeconds = \microseconds -> microseconds // microsecondsInASecond

# Milliseconds

millisecondsToMicroseconds = \milliseconds -> milliseconds * microsecondsInAMillisecond
millisecondsToNanoseconds = \milliseconds -> milliseconds * nanosecondsInAMillisecond
millisecondsToWholeSeconds = \milliseconds -> milliseconds // millisecondsInASecond

# Seconds

secondsToMicroseconds = \seconds -> seconds * microsecondsInASecond
secondsToMilliseconds = \seconds -> seconds * millisecondsInASecond
secondsToNanoseconds = \seconds -> seconds * nanosecondsInASecond
secondsToWholeDays = \seconds -> seconds // secondsInADay
secondsToWholeHours = \seconds -> seconds // secondsInAnHour
secondsToWholeMinutes = \seconds -> seconds // secondsInAMinute
secondsToWholeWeeks = \seconds -> seconds // secondsInAWeek

# Minutes

minutesToSeconds = \minutes -> minutes * secondsInAMinute

# Hours

hoursToSeconds = \hours -> hours * secondsInAnHour

# Days

daysToSeconds = \days -> days * secondsInADay

# Weeks

weeksToSeconds = \weeks -> (Num.toI64 weeks) * secondsInAWeek
