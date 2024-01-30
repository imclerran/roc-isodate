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
            weeksPerYear,
        },
        Utc.{
            Utc,
            fromNanosSinceEpoch,
        }
    ]

## Stores a timestamp as nanoseconds since UNIX EPOCH
#Utc := I128 implements [Inspect, Eq]

## Stores a timestamp as nanoseconds since 00:00:00 of a given day
UtcTime := U64 implements [Inspect, Eq]

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
                    |> daysToNanos |> fromNanosSinceEpoch |> Ok
            (_, _, _) -> Err InvalidDateFormat
        _ -> Err InvalidDateFormat

parseCalendarDateExtended  : List U8 -> Result Utc [InvalidDateFormat]
parseCalendarDateExtended = \bytes -> 
    when splitListAtIndices bytes [4,5,7,8] is
        [yearBytes, _, monthBytes, _, dayBytes] -> 
            when (utf8ToInt yearBytes, utf8ToInt monthBytes, utf8ToInt dayBytes) is
            (Ok y, Ok m, Ok d) if y >= epochYear && m >= 1 && m <= 12 && d >= 1 && d <= 31 ->
                numDaysSinceEpoch {year: y, month: m, day: d} 
                    |> daysToNanos |> fromNanosSinceEpoch |> Ok
            (_, _, _) -> Err InvalidDateFormat
        _ -> Err InvalidDateFormat

parseCalendarDateCentury : List U8 -> Result Utc [InvalidDateFormat]
parseCalendarDateCentury = \bytes ->
    when utf8ToInt bytes is
        Ok century if century >= 20 ->
            nanos = century * 100
                |> numDaysSinceEpochToYear
                |> daysToNanos
            nanos |> fromNanosSinceEpoch |> Ok
        Ok _ -> Err InvalidDateFormat
        Err _ -> Err InvalidDateFormat

parseCalendarDateYear : List U8 -> Result Utc [InvalidDateFormat]
parseCalendarDateYear = \bytes ->
    when utf8ToInt bytes is
        Ok year if year >= epochYear ->
            nanos = year
                |> numDaysSinceEpochToYear
                |> daysToNanos
            nanos |> fromNanosSinceEpoch |> Ok
        Ok _ -> Err InvalidDateFormat
        Err _ -> Err InvalidDateFormat

parseCalendarDateMonth : List U8 -> Result Utc [InvalidDateFormat]
parseCalendarDateMonth = \bytes -> 
    when splitListAtIndices bytes [4,5] is
        [yearBytes, _, monthBytes] -> 
            when (utf8ToInt yearBytes, utf8ToInt monthBytes) is
            (Ok year, Ok month) if year >= epochYear && month >= 1 && month <= 12 ->
                numDaysSinceEpoch { year, month, day: 1} 
                    |> daysToNanos |> fromNanosSinceEpoch |> Ok
            (_, _) -> Err InvalidDateFormat
        _ -> Err InvalidDateFormat

parseOrdinalDateBasic : List U8 -> Result Utc [InvalidDateFormat]
parseOrdinalDateBasic = \bytes -> 
    when splitListAtIndices bytes [4] is
        [yearBytes, dayBytes] -> 
            when (utf8ToInt yearBytes, utf8ToInt dayBytes) is
            (Ok year, Ok day) if year >= epochYear && day >= 1 && day <= 366 ->
                numDaysSinceEpoch {year, month: 1, day} 
                    |> daysToNanos |> fromNanosSinceEpoch |> Ok
            (_, _) -> Err InvalidDateFormat
        _ -> Err InvalidDateFormat

parseOrdinalDateExtended : List U8 -> Result Utc [InvalidDateFormat]
parseOrdinalDateExtended = \bytes -> 
    when splitListAtIndices bytes [4,5] is
        [yearBytes, _, dayBytes] -> 
            when (utf8ToInt yearBytes, utf8ToInt dayBytes) is
            (Ok year, Ok day) if year >= epochYear && day >= 1 && day <= 366 ->
                numDaysSinceEpoch {year, month: 1, day} 
                    |> daysToNanos |> fromNanosSinceEpoch |> Ok
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
        numDaysSinceEpoch {year, month: 1, day: (day + weekDaysSoFar)} |> daysToNanos |> fromNanosSinceEpoch |> Ok # month field should be optional, bug compiler bug prevents this
    else
        Err InvalidDateFormat
