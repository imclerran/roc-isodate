interface IsoToUtc
    exposes [parseDate]
    imports [
        Utils.{
            daysToNanos,
            numDaysSinceEpoch,
            numDaysSinceEpochToYear,
            calendarWeekToDaysInYear,
            splitStrAtIndices,
            validateUtf8SingleBytes,
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
    when Str.toUtf8 str |> validateUtf8SingleBytes is
        Ok bytes ->
            when bytes is
                [_,_] -> parseCalendarDateCentury str # YY
                [_,_,_,_] -> parseCalendarDateYear str # YYYY
                [_,_,_,_,'W',_,_] -> parseWeekDateReducedBasic str # YYYYWww
                [_,_,_,_,'-',_,_] -> parseCalendarDateMonth str # YYYY-MM
                [_,_,_,_,_,_,_] -> parseOrdinalDateBasic str # YYYYDDD
                [_,_,_,_,'-','W',_,_] -> parseWeekDateReducedExtended str # YYYY-Www
                [_,_,_,_,'W',_,_,_] -> parseWeekDateBasic str # YYYYWwwD
                [_,_,_,_,'-',_,_,_] -> parseOrdinalDateExtended str # YYYY-DDD
                [_,_,_,_,_,_,_,_] -> parseCalendarDateBasic str # YYYYMMDD
                [_,_,_,_,'-','W',_,_,'-',_] -> parseWeekDateExtended str # YYYY-Www-D
                [_,_,_,_,'-',_,_,'-',_,_] -> parseCalendarDateExtended str # YYYY-MM-DD
                _ -> Err InvalidDateFormat
        Err MultibyteCharacters -> Err InvalidDateFormat
        

parseCalendarDateBasic : Str -> Result Utc [InvalidDateFormat]
parseCalendarDateBasic = \str ->
    when splitStrAtIndices str [4, 6] is
        [yearStr, monthStr, dayStr] -> 
            when (Str.toU64 yearStr, Str.toU64 monthStr, Str.toU64 dayStr) is
            (Ok y, Ok m, Ok d) if y >= epochYear && m >= 1 && m <= 12 && d >= 1 && d <= 31 ->
                numDaysSinceEpoch {year: y, month: m, day: d} 
                    |> daysToNanos |> @Utc |> Ok
            (_, _, _) -> Err InvalidDateFormat
        _ -> Err InvalidDateFormat

parseCalendarDateExtended  : Str -> Result Utc [InvalidDateFormat]
parseCalendarDateExtended = \str -> 
    when Str.split str "-" is
        [yearStr, monthStr, dayStr] -> 
            when (Str.toU64 yearStr, Str.toU64 monthStr, Str.toU64 dayStr) is
            (Ok y, Ok m, Ok d) if y >= epochYear && m >= 1 && m <= 12 && d >= 1 && d <= 31 ->
                numDaysSinceEpoch { year: y, month: m, day: d} 
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
            (Ok year, Ok month) if year >= epochYear && month >= 1 && month <= 12 ->
                numDaysSinceEpoch { year, month, day: 1} 
                    |> daysToNanos |> @Utc |> Ok
            (_, _) -> Err InvalidDateFormat
        _ -> Err InvalidDateFormat

parseOrdinalDateBasic : Str -> Result Utc [InvalidDateFormat]
parseOrdinalDateBasic = \str -> 
    when splitStrAtIndices str [4] is
        [yearStr, dayStr] -> 
            when (Str.toU64 yearStr, Str.toU64 dayStr) is
            (Ok year, Ok day) if year >= epochYear && day >= 1 && day <= 366 ->
                numDaysSinceEpoch {year, month: 1, day} 
                    |> daysToNanos |> @Utc |> Ok
            (_, _) -> Err InvalidDateFormat
        _ -> Err InvalidDateFormat

parseOrdinalDateExtended : Str -> Result Utc [InvalidDateFormat]
parseOrdinalDateExtended = \str -> 
    when Str.split str "-" is
        [yearStr, dayStr] -> 
            when (Str.toU64 yearStr, Str.toU64 dayStr) is
            (Ok year, Ok day) if year >= epochYear && day >= 1 && day <= 366 ->
                numDaysSinceEpoch {year, month: 1, day} 
                    |> daysToNanos |> @Utc |> Ok
            (_, _) -> Err InvalidDateFormat
        _ -> Err InvalidDateFormat

parseWeekDateBasic : Str -> Result Utc [InvalidDateFormat]
parseWeekDateBasic = \str -> 
    when splitStrAtIndices str [4,5,7] is
        [yearStr, _, weekStr, dayStr] -> 
            when (Str.toU64 yearStr, Str.toU64 weekStr, Str.toU64 dayStr) is
            (Ok y, Ok w, Ok d) if y >= epochYear && w >= 1 && w <= 52 && d >= 1 && d <= 7 ->
                calendarWeekToUtc {year: y, week: w, day: d}
            (_, _, _) -> Err InvalidDateFormat
        _ -> Err InvalidDateFormat

parseWeekDateExtended : Str -> Result Utc [InvalidDateFormat]
parseWeekDateExtended = \str -> 
    when splitStrAtIndices str [4,6,8,9] is
        [yearStr, _, weekStr, _, dayStr] -> 
            when (Str.toU64 yearStr, Str.toU64 weekStr, Str.toU64 dayStr) is
            (Ok y, Ok w, Ok d) if y >= epochYear && w >= 1 && w <= 52 && d >= 1 && d <= 7 ->
                calendarWeekToUtc {year: y, week: w, day: d}
            (_, _, _) -> Err InvalidDateFormat
        _ -> Err InvalidDateFormat

parseWeekDateReducedBasic : Str -> Result Utc [InvalidDateFormat]
parseWeekDateReducedBasic = \str -> 
    when splitStrAtIndices str [4,5] is
        [yearStr, _, weekStr] -> 
            when (Str.toU64 yearStr, Str.toU64 weekStr) is
            (Ok year, Ok week) if year >= epochYear && week >= 1 && week <= 52 ->
                calendarWeekToUtc {year, week, day: 1}
            (_, _) -> Err InvalidDateFormat
        _ -> Err InvalidDateFormat

parseWeekDateReducedExtended : Str -> Result Utc [InvalidDateFormat]
parseWeekDateReducedExtended = \str -> 
    when splitStrAtIndices str [4,6] is
        [yearStr, _, weekStr] -> 
            when (Str.toU64 yearStr, Str.toU64 weekStr) is
            (Ok year, Ok week) if year >= epochYear && week >= 1 && week <= 52  ->
                calendarWeekToUtc {year, week, day: 1}
            (_, _) -> Err InvalidDateFormat
        _ -> Err InvalidDateFormat

calendarWeekToUtc : {year: U64, week: U64, day? U64} -> Result Utc [InvalidDateFormat]
calendarWeekToUtc = \{week, year, day? 1} ->
    if week >= 1 && week <= weeksPerYear && year >= epochYear then
        weekDaysSoFar = (calendarWeekToDaysInYear week year)
        numDaysSinceEpoch {year, month: 1, day: (day + weekDaysSoFar)} |> daysToNanos |> @Utc |> Ok # month field should be optional, bug compiler bug prevents this
    else
        Err InvalidDateFormat

# TESTS:
# CalendarDateCentury
expect parseDate "20" == (10_957) * secondsPerDay * nanosPerSecond |> Num.toU128 |> @Utc |> Ok
expect parseDate "19" == Err InvalidDateFormat
expect parseDate "ab" == Err InvalidDateFormat

# CalendarDateYear
expect parseDate "2024" == (19_723) * secondsPerDay * nanosPerSecond |> Num.toU128 |> @Utc |> Ok
expect parseDate "1970" == 0 |> Num.toU128 |> @Utc |> Ok
expect parseDate "1969" == Err InvalidDateFormat
expect parseDate "202f" == Err InvalidDateFormat

# WeekDateReducedBasic
expect parseDate "2024W04" == (19_723 + 21) * secondsPerDay * nanosPerSecond |> Num.toU128 |> @Utc |> Ok
expect parseDate "1970W01" == 0 |> Num.toU128 |> @Utc |> Ok
expect parseDate "1969W01" == Err InvalidDateFormat
expect parseDate "2024W53" == Err InvalidDateFormat
expect parseDate "2024W00" == Err InvalidDateFormat
expect parseDate "2024Www" == Err InvalidDateFormat

# CalendarDateMonth
expect parseDate "2024-02" == (19_723 + 31) * secondsPerDay * nanosPerSecond |> Num.toU128 |> @Utc |> Ok
expect parseDate "1970-01" == 0 |> Num.toU128 |> @Utc |> Ok
expect parseDate "1969-01" == Err InvalidDateFormat
expect parseDate "2024-13" == Err InvalidDateFormat
expect parseDate "2024-00" == Err InvalidDateFormat
expect parseDate "2024-0a" == Err InvalidDateFormat

# OrdinalDateBasic
expect parseDate "2024023" == (19_723 + 22) * secondsPerDay * nanosPerSecond |> Num.toU128 |> @Utc |> Ok
expect parseDate "1970001" == 0 |> Num.toU128 |> @Utc |> Ok
expect parseDate "1969001" == Err InvalidDateFormat
expect parseDate "2024000" == Err InvalidDateFormat
expect parseDate "2024367" == Err InvalidDateFormat
expect parseDate "2024a23" == Err InvalidDateFormat

# WeekDateReducedExtended
expect parseDate "2024-W04" == (19_723 + 21) * secondsPerDay * nanosPerSecond |> Num.toU128 |> @Utc |> Ok
expect parseDate "1970-W01" == 0 |> Num.toU128 |> @Utc |> Ok
expect parseDate "1969-W01" == Err InvalidDateFormat
expect parseDate "2024-W53" == Err InvalidDateFormat
expect parseDate "2024-W00" == Err InvalidDateFormat
expect parseDate "2024-Ww1" == Err InvalidDateFormat

# WeekDateBasic
expect parseDate "2024W042" == (19_723 + 22) * secondsPerDay * nanosPerSecond |> Num.toU128 |> @Utc |> Ok
expect parseDate "1970W011" == 0 |> Num.toU128 |> @Utc |> Ok
expect parseDate "1969W001" == Err InvalidDateFormat
expect parseDate "2024W000" == Err InvalidDateFormat
expect parseDate "2024W531" == Err InvalidDateFormat
expect parseDate "2024W010" == Err InvalidDateFormat
expect parseDate "2024W018" == Err InvalidDateFormat
expect parseDate "2024W0a2" == Err InvalidDateFormat

# OrdinalDateExtended
expect parseDate "2024-023" == (19_723 + 22) * secondsPerDay * nanosPerSecond |> Num.toU128 |> @Utc |> Ok
expect parseDate "1970-001" == 0 |> Num.toU128 |> @Utc |> Ok
expect parseDate "1969-001" == Err InvalidDateFormat
expect parseDate "2024-000" == Err InvalidDateFormat
expect parseDate "2024-367" == Err InvalidDateFormat
expect parseDate "2024-0a3" == Err InvalidDateFormat

# CalendarDateBasic
expect parseDate "20240123" == (19_723 + 22) * secondsPerDay * nanosPerSecond |> Num.toU128 |> @Utc |> Ok
expect parseDate "19700101" == 0 |> Num.toU128 |> @Utc |> Ok
expect parseDate "19690101" == Err InvalidDateFormat
expect parseDate "20240100" == Err InvalidDateFormat
expect parseDate "20240132" == Err InvalidDateFormat
expect parseDate "20240001" == Err InvalidDateFormat
expect parseDate "20241301" == Err InvalidDateFormat
expect parseDate "2024a123" == Err InvalidDateFormat

# WeekDateExtended
expect parseDate "2024-W04-2" == (19_723 + 22) * secondsPerDay * nanosPerSecond |> Num.toU128 |> @Utc |> Ok
expect parseDate "1970-W01-1" == 0 |> Num.toU128 |> @Utc |> Ok
expect parseDate "1969-W01-1" == Err InvalidDateFormat
expect parseDate "2024-W53-1" == Err InvalidDateFormat
expect parseDate "2024-W00-1" == Err InvalidDateFormat
expect parseDate "2024-W01-0" == Err InvalidDateFormat
expect parseDate "2024-W01-8" == Err InvalidDateFormat
expect parseDate "2024-Ww1-1" == Err InvalidDateFormat

# CalendarDateExtended
expect parseDate "2024-01-23" == (19_723 + 22) * secondsPerDay * nanosPerSecond |> Num.toU128 |> @Utc |> Ok
expect parseDate "1970-01-01" == 0 |> Num.toU128 |> @Utc |> Ok
expect parseDate "1969-01-01" == Err InvalidDateFormat
expect parseDate "2024-01-00" == Err InvalidDateFormat
expect parseDate "2024-01-32" == Err InvalidDateFormat
expect parseDate "2024-00-01" == Err InvalidDateFormat
expect parseDate "2024-13-01" == Err InvalidDateFormat
expect parseDate "2024-0a-01" == Err InvalidDateFormat