interface IsoToUtc
    exposes [parseDate]
    imports [
        Utils.{
            daysToNanos,
            numDaysSinceEpoch,
            numDaysSinceEpochToYear,
            calendarWeekToDaysInYear,
            splitStrAtIndices,
            validateUtf8,
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

# TODO: More efficient parsing method?
parseDate : Str -> Result Utc [InvalidDateFormat]
parseDate = \str ->
    when Str.toUtf8 str |> validateUtf8 is
        Ok bytes ->
            when List.len bytes is
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
        Err MultibyteCharacters -> Err InvalidDateFormat
    

# CalendarDateCentury
expect parseDate "20" == (10_957) * secondsPerDay * nanosPerSecond |> Num.toU128 |> @Utc |> Ok
# CalendarDateYear
expect parseDate "2024" == (19_723) * secondsPerDay * nanosPerSecond |> Num.toU128 |> @Utc |> Ok
# WeekDateReducedBasic
expect parseDate "2024W04" == (19_723 + 21) * secondsPerDay * nanosPerSecond |> Num.toU128 |> @Utc |> Ok
# CalendarDateMonth
expect parseDate "2024-02" == (19_723 + 31) * secondsPerDay * nanosPerSecond |> Num.toU128 |> @Utc |> Ok
# OrdinalDateBasic
expect parseDate "2024023" == (19_723 + 22) * secondsPerDay * nanosPerSecond |> Num.toU128 |> @Utc |> Ok
# WeekDateReducedExtended
expect parseDate "2024-W04" == (19_723 + 21) * secondsPerDay * nanosPerSecond |> Num.toU128 |> @Utc |> Ok
# WeekDateBasic
expect parseDate "2024W042" == (19_723 + 22) * secondsPerDay * nanosPerSecond |> Num.toU128 |> @Utc |> Ok
# OrdinalDateExtended
expect parseDate "2024-023" == (19_723 + 22) * secondsPerDay * nanosPerSecond |> Num.toU128 |> @Utc |> Ok
# CalendarDateBasic
expect parseDate "20240123" == (19_723 + 22) * secondsPerDay * nanosPerSecond |> Num.toU128 |> @Utc |> Ok
# WeekDateExtended
expect parseDate "2024-W04-2" == (19_723 + 22) * secondsPerDay * nanosPerSecond |> Num.toU128 |> @Utc |> Ok
# CalendarDateExtended
expect parseDate "2024-01-23" == (19_723 + 22) * secondsPerDay * nanosPerSecond |> Num.toU128 |> @Utc |> Ok


parseCalendarDateBasic : Str -> Result Utc [InvalidDateFormat]
parseCalendarDateBasic = \str ->
    when splitStrAtIndices str [4, 6] is
        [yearStr, monthStr, dayStr] -> 
            when (Str.toU64 yearStr, Str.toU64 monthStr, Str.toU64 dayStr) is
            (Ok year, Ok month, Ok day) ->
                numDaysSinceEpoch {year, month, day} 
                    |> daysToNanos |> @Utc |> Ok
            (_, _, _) -> Err InvalidDateFormat
        _ -> Err InvalidDateFormat

parseCalendarDateExtended  : Str -> Result Utc [InvalidDateFormat]
parseCalendarDateExtended = \str -> 
    when Str.split str "-" is
        [yearStr, monthStr, dayStr] -> 
            when (Str.toU64 yearStr, Str.toU64 monthStr, Str.toU64 dayStr) is
            (Ok year, Ok month, Ok day) ->
                numDaysSinceEpoch { year, month, day} 
                    |> daysToNanos |> @Utc |> Ok
            (_, _, _) -> Err InvalidDateFormat
        _ -> Err InvalidDateFormat

parseCalendarDateCentury : Str -> Result Utc [InvalidDateFormat]
parseCalendarDateCentury = \str ->
    when Str.toU64 str is
        Ok century if century >= 20 ->
            nanos = century * 100
                |> numDaysSinceEpochToYear
                |> daysToNanos
            nanos |> @Utc |> Ok
        Ok _ -> Err InvalidDateFormat
        Err _ -> Err InvalidDateFormat

parseCalendarDateYear : Str -> Result Utc [InvalidDateFormat]
parseCalendarDateYear = \str ->
    when Str.toU64 str is
        Ok year if year >= epochYear ->
            nanos = year
                |> numDaysSinceEpochToYear
                |> daysToNanos
            nanos |> @Utc |> Ok
        Ok _ -> Err InvalidDateFormat
        Err _ -> Err InvalidDateFormat

parseCalendarDateMonth : Str -> Result Utc [InvalidDateFormat]
parseCalendarDateMonth = \str -> 
    when Str.split str "-" is
        [yearStr, monthStr] -> 
            when (Str.toU64 yearStr, Str.toU64 monthStr) is
            (Ok year, Ok month) ->
                numDaysSinceEpoch { year, month, day: 1} 
                    |> daysToNanos |> @Utc |> Ok
            (_, _) -> Err InvalidDateFormat
        _ -> Err InvalidDateFormat

parseOrdinalDateBasic : Str -> Result Utc [InvalidDateFormat]
parseOrdinalDateBasic = \str -> 
    when splitStrAtIndices str [4] is
        [yearStr, dayStr] -> 
            when (Str.toU64 yearStr, Str.toU64 dayStr) is
            (Ok year, Ok day) ->
                numDaysSinceEpoch {year, month: 1, day} 
                    |> daysToNanos |> @Utc |> Ok
            (_, _) -> Err InvalidDateFormat
        _ -> Err InvalidDateFormat

parseOrdinalDateExtended : Str -> Result Utc [InvalidDateFormat]
parseOrdinalDateExtended = \str -> 
    when Str.split str "-" is
        [yearStr, dayStr] -> 
            when (Str.toU64 yearStr, Str.toU64 dayStr) is
            (Ok year, Ok day) ->
                numDaysSinceEpoch {year, month: 1, day} 
                    |> daysToNanos |> @Utc |> Ok
            (_, _) -> Err InvalidDateFormat
        _ -> Err InvalidDateFormat

parseWeekDateBasic : Str -> Result Utc [InvalidDateFormat]
parseWeekDateBasic = \str -> 
    when splitStrAtIndices str [4,5,7] is
        [yearStr, _, weekStr, dayStr] -> 
            when (Str.toU64 yearStr, Str.toU64 weekStr, Str.toU64 dayStr) is
            (Ok year, Ok week, Ok day) ->
                calendarWeekToUtc {year, week, day}
            (_, _, _) -> Err InvalidDateFormat
        _ -> Err InvalidDateFormat

parseWeekDateExtended : Str -> Result Utc [InvalidDateFormat]
parseWeekDateExtended = \str -> 
    when splitStrAtIndices str [4,6,8,9] is
        [yearStr, _, weekStr, _, dayStr] -> 
            when (Str.toU64 yearStr, Str.toU64 weekStr, Str.toU64 dayStr) is
            (Ok year, Ok week, Ok day) ->
                calendarWeekToUtc {year, week, day}
            (_, _, _) -> Err InvalidDateFormat
        _ -> Err InvalidDateFormat

parseWeekDateReducedBasic : Str -> Result Utc [InvalidDateFormat]
parseWeekDateReducedBasic = \str -> 
    when splitStrAtIndices str [4,5] is
        [yearStr, _, weekStr] -> 
            when (Str.toU64 yearStr, Str.toU64 weekStr) is
            (Ok year, Ok week) ->
                calendarWeekToUtc {year, week, day: 1}
            (_, _) -> Err InvalidDateFormat
        _ -> Err InvalidDateFormat

parseWeekDateReducedExtended : Str -> Result Utc [InvalidDateFormat]
parseWeekDateReducedExtended = \str -> 
    when splitStrAtIndices str [4,6] is
        [yearStr, _, weekStr] -> 
            when (Str.toU64 yearStr, Str.toU64 weekStr) is
            (Ok year, Ok week) ->
                calendarWeekToUtc {year, week, day: 1}
            (_, _) -> Err InvalidDateFormat
        _ -> Err InvalidDateFormat

calendarWeekToUtc : {year: U64, week: U64, day? U64} -> Result Utc [InvalidDateFormat]
calendarWeekToUtc = \{week, year, day? 1} ->
    if week >= 1 && week <= weeksPerYear && year > epochYear then
        weekDaysSoFar = (calendarWeekToDaysInYear week year)
        numDaysSinceEpoch {year, month: 1, day: (day + weekDaysSoFar)} |> daysToNanos |> @Utc |> Ok # month field should be optional, bug compiler bug prevents this
    else
        Err InvalidDateFormat