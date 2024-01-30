interface IsoToUtc
    exposes [
        parseDateFromStr,
        parseDateFromU8,
    ]
    imports [
        Utils.{
            daysToNanos,
            numDaysSinceEpoch,
            numDaysSinceEpochToYear,
            calendarWeekToDaysInYear,
            splitListAtIndices,
            validateUtf8SingleBytes,
            utf8ToInt,
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

parseDateFromStr: Str -> Result Utc [InvalidDateFormat]
parseDateFromStr = \str ->
    Str.toUtf8 str |> parseDateFromU8

# TODO: More efficient parsing method?
parseDateFromU8 : List U8 -> Result Utc [InvalidDateFormat]
parseDateFromU8 = \bytes ->
    if validateUtf8SingleBytes bytes then
        when bytes is
            [_,_] -> parseCalendarDateCentury bytes # YY
            [_,_,_,_] -> parseCalendarDateYear bytes # YYYY
            [_,_,_,_,'W',_,_] -> parseWeekDateReducedBasic bytes # YYYYWww
            [_,_,_,_,'-',_,_] -> parseCalendarDateMonth bytes # YYYY-MM
            [_,_,_,_,_,_,_] -> parseOrdinalDateBasic bytes # YYYYDDD
            [_,_,_,_,'-','W',_,_] -> parseWeekDateReducedExtended bytes # YYYY-Www
            [_,_,_,_,'W',_,_,_] -> parseWeekDateBasic bytes # YYYYWwwD
            [_,_,_,_,'-',_,_,_] -> parseOrdinalDateExtended bytes # YYYY-DDD
            [_,_,_,_,_,_,_,_] -> parseCalendarDateBasic bytes # YYYYMMDD
            [_,_,_,_,'-','W',_,_,'-',_] -> parseWeekDateExtended bytes # YYYY-Www-D
            [_,_,_,_,'-',_,_,'-',_,_] -> parseCalendarDateExtended bytes # YYYY-MM-DD
            _ -> Err InvalidDateFormat
    else
        Err InvalidDateFormat


parseCalendarDateBasic : List U8 -> Result Utc [InvalidDateFormat]
parseCalendarDateBasic = \bytes ->
    when splitListAtIndices bytes [4, 6] is
        [yearBytes, monthBytes, dayBytes] -> 
            when (utf8ToInt yearBytes, utf8ToInt monthBytes, utf8ToInt dayBytes) is
            (Ok y, Ok m, Ok d) if y >= epochYear && m >= 1 && m <= 12 && d >= 1 && d <= 31 ->
                numDaysSinceEpoch {year: y, month: m, day: d} 
                    |> daysToNanos |> @Utc |> Ok
            (_, _, _) -> Err InvalidDateFormat
        _ -> Err InvalidDateFormat

parseCalendarDateExtended  : List U8 -> Result Utc [InvalidDateFormat]
parseCalendarDateExtended = \bytes -> 
    when splitListAtIndices bytes [4,5,7,8] is
        [yearBytes, _, monthBytes, _, dayBytes] -> 
            when (utf8ToInt yearBytes, utf8ToInt monthBytes, utf8ToInt dayBytes) is
            (Ok y, Ok m, Ok d) if y >= epochYear && m >= 1 && m <= 12 && d >= 1 && d <= 31 ->
                numDaysSinceEpoch {year: y, month: m, day: d} 
                    |> daysToNanos |> @Utc |> Ok
            (_, _, _) -> Err InvalidDateFormat
        _ -> Err InvalidDateFormat

parseCalendarDateCentury : List U8 -> Result Utc [InvalidDateFormat]
parseCalendarDateCentury = \bytes ->
    when utf8ToInt bytes is
        Ok century if century >= 20 ->
            nanos = century * 100
                |> numDaysSinceEpochToYear
                |> daysToNanos
            nanos |> @Utc |> Ok
        Ok _ -> Err InvalidDateFormat
        Err _ -> Err InvalidDateFormat

parseCalendarDateYear : List U8 -> Result Utc [InvalidDateFormat]
parseCalendarDateYear = \bytes ->
    when utf8ToInt bytes is
        Ok year if year >= epochYear ->
            nanos = year
                |> numDaysSinceEpochToYear
                |> daysToNanos
            nanos |> @Utc |> Ok
        Ok _ -> Err InvalidDateFormat
        Err _ -> Err InvalidDateFormat

parseCalendarDateMonth : List U8 -> Result Utc [InvalidDateFormat]
parseCalendarDateMonth = \bytes -> 
    when splitListAtIndices bytes [4,5] is
        [yearBytes, _, monthBytes] -> 
            when (utf8ToInt yearBytes, utf8ToInt monthBytes) is
            (Ok year, Ok month) if year >= epochYear && month >= 1 && month <= 12 ->
                numDaysSinceEpoch { year, month, day: 1} 
                    |> daysToNanos |> @Utc |> Ok
            (_, _) -> Err InvalidDateFormat
        _ -> Err InvalidDateFormat

parseOrdinalDateBasic : List U8 -> Result Utc [InvalidDateFormat]
parseOrdinalDateBasic = \bytes -> 
    when splitListAtIndices bytes [4] is
        [yearBytes, dayBytes] -> 
            when (utf8ToInt yearBytes, utf8ToInt dayBytes) is
            (Ok year, Ok day) if year >= epochYear && day >= 1 && day <= 366 ->
                numDaysSinceEpoch {year, month: 1, day} 
                    |> daysToNanos |> @Utc |> Ok
            (_, _) -> Err InvalidDateFormat
        _ -> Err InvalidDateFormat

parseOrdinalDateExtended : List U8 -> Result Utc [InvalidDateFormat]
parseOrdinalDateExtended = \bytes -> 
    when splitListAtIndices bytes [4,5] is
        [yearBytes, _, dayBytes] -> 
            when (utf8ToInt yearBytes, utf8ToInt dayBytes) is
            (Ok year, Ok day) if year >= epochYear && day >= 1 && day <= 366 ->
                numDaysSinceEpoch {year, month: 1, day} 
                    |> daysToNanos |> @Utc |> Ok
            (_, _) -> Err InvalidDateFormat
        _ -> Err InvalidDateFormat

parseWeekDateBasic : List U8 -> Result Utc [InvalidDateFormat]
parseWeekDateBasic = \bytes -> 
    when splitListAtIndices bytes [4,5,7] is
        [yearBytes, _, weekBytes, dayBytes] -> 
            when (utf8ToInt yearBytes, utf8ToInt weekBytes, utf8ToInt dayBytes) is
            (Ok y, Ok w, Ok d) if y >= epochYear && w >= 1 && w <= 52 && d >= 1 && d <= 7 ->
                calendarWeekToUtc {year: y, week: w, day: d}
            (_, _, _) -> Err InvalidDateFormat
        _ -> Err InvalidDateFormat

parseWeekDateExtended : List U8 -> Result Utc [InvalidDateFormat]
parseWeekDateExtended = \bytes -> 
    when splitListAtIndices bytes [4,6,8,9] is
        [yearBytes, _, weekBytes, _, dayBytes] -> 
            when (utf8ToInt yearBytes, utf8ToInt weekBytes, utf8ToInt dayBytes) is
            (Ok y, Ok w, Ok d) if y >= epochYear && w >= 1 && w <= 52 && d >= 1 && d <= 7 ->
                calendarWeekToUtc {year: y, week: w, day: d}
            (_, _, _) -> Err InvalidDateFormat
        _ -> Err InvalidDateFormat

parseWeekDateReducedBasic : List U8 -> Result Utc [InvalidDateFormat]
parseWeekDateReducedBasic = \bytes -> 
    when splitListAtIndices bytes [4,5] is
        [yearBytes, _, weekBytes] -> 
            when (utf8ToInt yearBytes, utf8ToInt weekBytes) is
            (Ok year, Ok week) if year >= epochYear && week >= 1 && week <= 52 ->
                calendarWeekToUtc {year, week, day: 1}
            (_, _) -> Err InvalidDateFormat
        _ -> Err InvalidDateFormat

parseWeekDateReducedExtended : List U8 -> Result Utc [InvalidDateFormat]
parseWeekDateReducedExtended = \bytes -> 
    when splitListAtIndices bytes [4,6] is
        [yearBytes, _, weekBytes] -> 
            when (utf8ToInt yearBytes, utf8ToInt weekBytes) is
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
expect parseDateFromStr "20" == (10_957) * secondsPerDay * nanosPerSecond |> Num.toU128 |> @Utc |> Ok
expect parseDateFromStr "19" == Err InvalidDateFormat
expect parseDateFromStr "ab" == Err InvalidDateFormat

# CalendarDateYear
expect parseDateFromStr "2024" == (19_723) * secondsPerDay * nanosPerSecond |> Num.toU128 |> @Utc |> Ok
expect parseDateFromStr "1970" == 0 |> Num.toU128 |> @Utc |> Ok
expect parseDateFromStr "1969" == Err InvalidDateFormat
expect parseDateFromStr "202f" == Err InvalidDateFormat

# WeekDateReducedBasic
expect parseDateFromStr "2024W04" == (19_723 + 21) * secondsPerDay * nanosPerSecond |> Num.toU128 |> @Utc |> Ok
expect parseDateFromStr "1970W01" == 0 |> Num.toU128 |> @Utc |> Ok
expect parseDateFromStr "1969W01" == Err InvalidDateFormat
expect parseDateFromStr "2024W53" == Err InvalidDateFormat
expect parseDateFromStr "2024W00" == Err InvalidDateFormat
expect parseDateFromStr "2024Www" == Err InvalidDateFormat

# CalendarDateMonth
expect parseDateFromStr "2024-02" == (19_723 + 31) * secondsPerDay * nanosPerSecond |> Num.toU128 |> @Utc |> Ok
expect parseDateFromStr "1970-01" == 0 |> Num.toU128 |> @Utc |> Ok
expect parseDateFromStr "1969-01" == Err InvalidDateFormat
expect parseDateFromStr "2024-13" == Err InvalidDateFormat
expect parseDateFromStr "2024-00" == Err InvalidDateFormat
expect parseDateFromStr "2024-0a" == Err InvalidDateFormat

# OrdinalDateBasic
expect parseDateFromStr "2024023" == (19_723 + 22) * secondsPerDay * nanosPerSecond |> Num.toU128 |> @Utc |> Ok
expect parseDateFromStr "1970001" == 0 |> Num.toU128 |> @Utc |> Ok
expect parseDateFromStr "1969001" == Err InvalidDateFormat
expect parseDateFromStr "2024000" == Err InvalidDateFormat
expect parseDateFromStr "2024367" == Err InvalidDateFormat
expect parseDateFromStr "2024a23" == Err InvalidDateFormat

# WeekDateReducedExtended
expect parseDateFromStr "2024-W04" == (19_723 + 21) * secondsPerDay * nanosPerSecond |> Num.toU128 |> @Utc |> Ok
expect parseDateFromStr "1970-W01" == 0 |> Num.toU128 |> @Utc |> Ok
expect parseDateFromStr "1969-W01" == Err InvalidDateFormat
expect parseDateFromStr "2024-W53" == Err InvalidDateFormat
expect parseDateFromStr "2024-W00" == Err InvalidDateFormat
expect parseDateFromStr "2024-Ww1" == Err InvalidDateFormat

# WeekDateBasic
expect parseDateFromStr "2024W042" == (19_723 + 22) * secondsPerDay * nanosPerSecond |> Num.toU128 |> @Utc |> Ok
expect parseDateFromStr "1970W011" == 0 |> Num.toU128 |> @Utc |> Ok
expect parseDateFromStr "1969W001" == Err InvalidDateFormat
expect parseDateFromStr "2024W000" == Err InvalidDateFormat
expect parseDateFromStr "2024W531" == Err InvalidDateFormat
expect parseDateFromStr "2024W010" == Err InvalidDateFormat
expect parseDateFromStr "2024W018" == Err InvalidDateFormat
expect parseDateFromStr "2024W0a2" == Err InvalidDateFormat

# OrdinalDateExtended
expect parseDateFromStr "2024-023" == (19_723 + 22) * secondsPerDay * nanosPerSecond |> Num.toU128 |> @Utc |> Ok
expect parseDateFromStr "1970-001" == 0 |> Num.toU128 |> @Utc |> Ok
expect parseDateFromStr "1969-001" == Err InvalidDateFormat
expect parseDateFromStr "2024-000" == Err InvalidDateFormat
expect parseDateFromStr "2024-367" == Err InvalidDateFormat
expect parseDateFromStr "2024-0a3" == Err InvalidDateFormat

# CalendarDateBasic
expect parseDateFromStr "20240123" == (19_723 + 22) * secondsPerDay * nanosPerSecond |> Num.toU128 |> @Utc |> Ok
expect parseDateFromStr "19700101" == 0 |> Num.toU128 |> @Utc |> Ok
expect parseDateFromStr "19690101" == Err InvalidDateFormat
expect parseDateFromStr "20240100" == Err InvalidDateFormat
expect parseDateFromStr "20240132" == Err InvalidDateFormat
expect parseDateFromStr "20240001" == Err InvalidDateFormat
expect parseDateFromStr "20241301" == Err InvalidDateFormat
expect parseDateFromStr "2024a123" == Err InvalidDateFormat

# WeekDateExtended
expect parseDateFromStr "2024-W04-2" == (19_723 + 22) * secondsPerDay * nanosPerSecond |> Num.toU128 |> @Utc |> Ok
expect parseDateFromStr "1970-W01-1" == 0 |> Num.toU128 |> @Utc |> Ok
expect parseDateFromStr "1969-W01-1" == Err InvalidDateFormat
expect parseDateFromStr "2024-W53-1" == Err InvalidDateFormat
expect parseDateFromStr "2024-W00-1" == Err InvalidDateFormat
expect parseDateFromStr "2024-W01-0" == Err InvalidDateFormat
expect parseDateFromStr "2024-W01-8" == Err InvalidDateFormat
expect parseDateFromStr "2024-Ww1-1" == Err InvalidDateFormat

# CalendarDateExtended
expect parseDateFromStr "2024-01-23" == (19_723 + 22) * secondsPerDay * nanosPerSecond |> Num.toU128 |> @Utc |> Ok
expect parseDateFromStr "1970-01-01" == 0 |> Num.toU128 |> @Utc |> Ok
expect parseDateFromStr "1969-01-01" == Err InvalidDateFormat
expect parseDateFromStr "2024-01-00" == Err InvalidDateFormat
expect parseDateFromStr "2024-01-32" == Err InvalidDateFormat
expect parseDateFromStr "2024-00-01" == Err InvalidDateFormat
expect parseDateFromStr "2024-13-01" == Err InvalidDateFormat
expect parseDateFromStr "2024-0a-01" == Err InvalidDateFormat