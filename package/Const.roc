interface Const
    exposes [
        epochYear,
        epochMonth,
        epochDay,
        epochWeekOffset,
        nanosPerSecond,
        nanosPerMilisecond,
        secondsPerMinute,
        secondsPerHour,
        secondsPerDay,
        leapInterval,
        leapException,
        leapNonException,
        daysPerNonLeapYear,
        daysPerLeapYear,
        daysPerWeek,
        monthDays,
        weeksPerYear,
    ]
    imports []


epochYear = 1970
epochMonth = 1
epochDay = 1
epochWeekOffset = 4

nanosPerSecond = 1_000_000_000
nanosPerMilisecond = 1_000_000

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

monthDays : {month: U64, isLeap? Bool} -> U64
monthDays = \{month, isLeap? Bool.false} ->
    when month is
        1 | 3 | 5 | 7 | 8 | 10 | 12 -> 31
        4 | 6 | 9 | 11 -> 30
        2 if isLeap -> 29
        2 -> 28
        _ -> 0