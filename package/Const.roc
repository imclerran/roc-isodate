module [
    daysPerLeapYear,
    daysPerNonLeapYear,
    daysPerWeek,
    epochDay,
    epochMonth,
    epochWeekOffset,
    epochYear,
    hoursPerDay,
    leapException,
    leapInterval,
    leapNonException,
    minutesPerDay,
    minutesPerHour,
    monthDays,
    nanosPerDay,
    nanosPerHour,
    nanosPerMilli,
    nanosPerMinute,
    nanosPerSecond,
    nanosPerSecond,
    secondsPerDay,
    secondsPerHour,
    secondsPerMinute,
    weeksPerYear,
]

epochYear = 1970
epochMonth = 1
epochDay = 1
epochWeekOffset = 4

hoursPerDay = 24

minutesPerHour = 60
minutesPerDay = hoursPerDay * minutesPerHour

nanosPerMilli = 1_000_000
nanosPerSecond = 1_000_000_000
nanosPerMinute = 60 * nanosPerSecond
nanosPerHour = 60 * nanosPerMinute
nanosPerDay = 24 * nanosPerHour

secondsPerMinute = 60
secondsPerHour = 3600
secondsPerDay = 86_400

leapInterval = 4
leapException = 100
leapNonException = 400

daysPerNonLeapYear = 365
daysPerLeapYear = 366

daysPerWeek = 7
weeksPerYear = 52

monthDays : { month : Int *, isLeap ? Bool } -> U64
monthDays = \{ month, isLeap ? Bool.false } ->
    when month is
        1 | 3 | 5 | 7 | 8 | 10 | 12 -> 31
        4 | 6 | 9 | 11 -> 30
        2 if isLeap -> 29
        2 -> 28
        _ -> 0
