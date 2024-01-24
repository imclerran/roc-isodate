interface IsoToUtc
    exposes [parseDate]
    imports [
        Utils.{
            unwrap, 
            daysToNanos,
            numDaysSinceEpoch,
            numDaysSinceEpochToYear,
            calendarWeekToDaysInYear,
            splitStrAtIndices,
        },
        Const.{
            epochYear,
            secondsPerDay,
            nanosPerSecond,
            weeksPerYear,
        }
    ]

## Stores a timestamp as nanoseconds since UNIX EPOCH
## Note that this implementation only supports dates after 1970
Utc := U128 implements [Inspect, Eq]

# TODO: use regex - library?
parseDate : Str -> Result Utc [InvalidDateFormat]
parseDate = \str ->
    when Str.countUtf8Bytes str is
        2 -> parseCalendarDateCentury str # YY
        4 -> parseCalendarDateYear str # YYYY
        7 if Str.contains str "W" -> 
            parseWeekDateReducedBasic str # YYYYWww
        7 if Str.contains str "-" -> 
            parseCalendarDateMonth str # YYYY-MM
        7 -> parseOrdinalDateBasic str # YYYYDDD
        8 if Str.contains str "W" && Str.contains str "-" ->
            parseWeekDateReducedExtended str # YYYY-Www
        8 if Str.contains str "W" ->
            parseWeekDateBasic str # YYYYWwwD
        8 if Str.contains str "-" ->
            parseOrdinalDateExtended str # YYYY-DDD
        8 -> parseCalendarDateBasic str # YYYYMMDD
        10 if Str.contains str "W" -> 
            parseWeekDateExtended str # YYYY-Www-D
        10 if Str.contains str "-" ->
            parseCalendarDateExtended str # YYYY-MM-DD
        _ -> Err InvalidDateFormat

# CalendarDateExtended
expect unwrap (parseDate "2024-01-23") "Could not parse!" == @Utc (Num.toU128 ((19_723 + 22) * secondsPerDay * nanosPerSecond))
# CalendarDateBasic
expect unwrap (parseDate "20240123") "Could not parse!" == @Utc (Num.toU128 ((19_723 + 22) * secondsPerDay * nanosPerSecond))
# OrdinalDateBasic
expect unwrap (parseDate "2024023") "Could not parse!" == @Utc (Num.toU128 ((19_723 + 22) * secondsPerDay * nanosPerSecond))
# OrdinalDateExtended
expect unwrap (parseDate "2024-023") "Could not parse!" == @Utc (Num.toU128 ((19_723 + 22) * secondsPerDay * nanosPerSecond))
# WeekDateBasic
expect unwrap (parseDate "2024W042") "Could not parse!" == @Utc (Num.toU128 ((19_723 + 22) * secondsPerDay * nanosPerSecond))
# WeekDateExtended
expect unwrap (parseDate "2024-W04-2") "Could not parse!" == @Utc (Num.toU128 ((19_723 + 22) * secondsPerDay * nanosPerSecond))
# WeekDateReducedBasic
expect unwrap (parseDate "2024W04") "Could not parse!" == @Utc (Num.toU128 ((19_723 + 21) * secondsPerDay * nanosPerSecond))
# WeekDateReducedExtended
expect unwrap (parseDate "2024-W04") "Could not parse!" == @Utc (Num.toU128 ((19_723 + 21) * secondsPerDay * nanosPerSecond))
# CalendarDateCentury
expect unwrap (parseDate "20") "Could not parse!" == @Utc (Num.toU128 (10_957 * secondsPerDay * nanosPerSecond))
# CalendarDateYear
expect unwrap (parseDate "2024") "Could not parse!" == @Utc (Num.toU128 (19_723 * secondsPerDay * nanosPerSecond))
# CalendarDateMonth
expect unwrap (parseDate "2024-02") "Could not parse!" == @Utc (Num.toU128 ((19_723 + 31) * secondsPerDay * nanosPerSecond))



parseCalendarDateBasic : Str -> Result Utc [InvalidDateFormat]
parseCalendarDateBasic = \str ->
    when splitStrAtIndices str [4, 6] is
        [yearStr, monthStr, dayStr] -> 
            year = Str.toNat yearStr
            month = Str.toNat monthStr
            day = Str.toNat dayStr
            when (year, month, day) is
            (Ok y, Ok m, Ok d) ->
                numDaysSinceEpoch { year: y, month: m, day: d} 
                    |> daysToNanos |> @Utc |> Ok
            (_, _, _) -> Err InvalidDateFormat
        _ -> Err InvalidDateFormat

parseCalendarDateExtended  : Str -> Result Utc [InvalidDateFormat]
parseCalendarDateExtended = \str -> 
    when Str.split str "-" is
        [yearStr, monthStr, dayStr] -> 
            year = Str.toNat yearStr
            month = Str.toNat monthStr
            day = Str.toNat dayStr
            when (year, month, day) is
            (Ok y, Ok m, Ok d) ->
                numDaysSinceEpoch { year: y, month: m, day: d} 
                    |> daysToNanos |> @Utc |> Ok
            (_, _, _) -> Err InvalidDateFormat
        _ -> Err InvalidDateFormat

parseCalendarDateCentury : Str -> Result Utc [InvalidDateFormat]
parseCalendarDateCentury = \str ->
    when Str.toNat str is
        Ok century if century >= 20 ->
            nanos = century * 100
                |> numDaysSinceEpochToYear
                |> daysToNanos
            nanos |> @Utc |> Ok
        Ok _ -> Err InvalidDateFormat
        Err _ -> Err InvalidDateFormat

parseCalendarDateYear : Str -> Result Utc [InvalidDateFormat]
parseCalendarDateYear = \str ->
    when Str.toNat str is
        Ok year if year >= epochYear ->
            nanos = year
                |> numDaysSinceEpochToYear
                |> daysToNanos
            Ok (@Utc nanos)
        Ok _ -> Err InvalidDateFormat
        Err _ -> Err InvalidDateFormat

parseCalendarDateMonth : Str -> Result Utc [InvalidDateFormat]
parseCalendarDateMonth = \str -> 
    when Str.split str "-" is
        [yearStr, monthStr] -> 
            year = Str.toNat yearStr
            month = Str.toNat monthStr
            when (year, month) is
            (Ok y, Ok m) ->
                numDaysSinceEpoch { year: y, month: m, day: 1} 
                    |> daysToNanos |> @Utc |> Ok
            (_, _) -> Err InvalidDateFormat
        _ -> Err InvalidDateFormat

parseOrdinalDateBasic : Str -> Result Utc [InvalidDateFormat]
parseOrdinalDateBasic = \str -> 
    when splitStrAtIndices str [4] is
        [yearStr, dayStr] -> 
            year = Str.toNat yearStr
            day = Str.toNat dayStr
            when (year, day) is
            (Ok y, Ok d) ->
                numDaysSinceEpoch {year: y, month: 1, day: d} 
                    |> daysToNanos |> @Utc |> Ok
            (_, _) -> Err InvalidDateFormat
        _ -> Err InvalidDateFormat

parseOrdinalDateExtended : Str -> Result Utc [InvalidDateFormat]
parseOrdinalDateExtended = \str -> 
    when Str.split str "-" is
        [yearStr, dayStr] -> 
            year = Str.toNat yearStr
            day = Str.toNat dayStr
            when (year, day) is
            (Ok y, Ok d) ->
                numDaysSinceEpoch {year: y, month: 1, day: d} 
                    |> daysToNanos |> @Utc |> Ok
            (_, _) -> Err InvalidDateFormat
        _ -> Err InvalidDateFormat

parseWeekDateBasic : Str -> Result Utc [InvalidDateFormat]
parseWeekDateBasic = \str -> 
    when splitStrAtIndices str [4,5,7] is
        [yearStr, _, weekStr, dayStr] -> 
            year = Str.toNat yearStr
            week = Str.toNat weekStr
            day = Str.toNat dayStr
            when (year, week, day) is
            (Ok y, Ok w, Ok d) ->
                calendarWeekToUtc {year: y, week: w, day: d}
            (_, _, _) -> Err InvalidDateFormat
        _ -> Err InvalidDateFormat

parseWeekDateExtended : Str -> Result Utc [InvalidDateFormat]
parseWeekDateExtended = \str -> 
    when splitStrAtIndices str [4,6,8,9] is
        [yearStr, _, weekStr, _, dayStr] -> 
            year = Str.toNat yearStr
            week = Str.toNat weekStr
            day = Str.toNat dayStr
            when (year, week, day) is
            (Ok y, Ok w, Ok d) ->
                calendarWeekToUtc {year: y, week: w, day: d}
            (_, _, _) -> Err InvalidDateFormat
        _ -> Err InvalidDateFormat

parseWeekDateReducedBasic : Str -> Result Utc [InvalidDateFormat]
parseWeekDateReducedBasic = \str -> 
    when splitStrAtIndices str [4,5] is
        [yearStr, _, weekStr] -> 
            year = Str.toNat yearStr
            week = Str.toNat weekStr
            when (year, week) is
            (Ok y, Ok w) ->
                calendarWeekToUtc {year: y, week: w, day: 1}
            (_, _) -> Err InvalidDateFormat
        _ -> Err InvalidDateFormat

parseWeekDateReducedExtended : Str -> Result Utc [InvalidDateFormat]
parseWeekDateReducedExtended = \str -> 
    when splitStrAtIndices str [4,6] is
        [yearStr, _, weekStr] -> 
            year = Str.toNat yearStr
            week = Str.toNat weekStr
            when (year, week) is
            (Ok y, Ok w) ->
                calendarWeekToUtc {year: y, week: w, day: 1}
            (_, _) -> Err InvalidDateFormat
        _ -> Err InvalidDateFormat

calendarWeekToUtc : {year: Nat, week: Nat, day? Nat} -> Result Utc [InvalidDateFormat]
calendarWeekToUtc = \{week, year, day? 1} ->
    if week >= 1 && week <= weeksPerYear && year > epochYear then
        weekDaysSoFar = (calendarWeekToDaysInYear week year)
        numDaysSinceEpoch {year, day: (day + weekDaysSoFar)} |> daysToNanos |> @Utc |> Ok
    else
        Err InvalidDateFormat