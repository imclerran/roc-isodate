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
        monthDaysNonLeap,
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

monthDaysNonLeap = 
    Dict.empty {}
    |> Dict.insert 1 31
    |> Dict.insert 2 28
    |> Dict.insert 3 31
    |> Dict.insert 4 30
    |> Dict.insert 5 31
    |> Dict.insert 6 30
    |> Dict.insert 7 31
    |> Dict.insert 8 31
    |> Dict.insert 9 30
    |> Dict.insert 10 31
    |> Dict.insert 11 30
    |> Dict.insert 12 31