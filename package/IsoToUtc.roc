interface IsoToUtc
    exposes [
        parseDateFromStr,
        parseDateFromU8,
        parseTimeFromStr,
        parseTimeFromU8,
    ]
    imports [
        Const.{
            nanosPerSecond,
            weeksPerYear,
        },
        Utc.{
            Utc,
            fromNanosSinceEpoch,
        },
        UtcTime.{
            UtcTime,
            fromNanosSinceMidnight,
        },
        Utils.{
            calendarWeekToDaysInYear,
            daysToNanos,
            numDaysSinceEpoch,
            numDaysSinceEpochToYear,
            splitListAtIndices,
            utf8ToInt,
            validateUtf8SingleBytes,
        },
    ]

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
            (Ok y, Ok m, Ok d) if m >= 1 && m <= 12 && d >= 1 && d <= 31 ->
                numDaysSinceEpoch {year: y, month: m, day: d} 
                    |> daysToNanos |> fromNanosSinceEpoch |> Ok
            (_, _, _) -> Err InvalidDateFormat
        _ -> Err InvalidDateFormat

parseCalendarDateExtended  : List U8 -> Result Utc [InvalidDateFormat]
parseCalendarDateExtended = \bytes -> 
    when splitListAtIndices bytes [4,5,7,8] is
        [yearBytes, _, monthBytes, _, dayBytes] -> 
            when (utf8ToInt yearBytes, utf8ToInt monthBytes, utf8ToInt dayBytes) is
            (Ok y, Ok m, Ok d) if m >= 1 && m <= 12 && d >= 1 && d <= 31 ->
                numDaysSinceEpoch {year: y, month: m, day: d} 
                    |> daysToNanos |> fromNanosSinceEpoch |> Ok
            (_, _, _) -> Err InvalidDateFormat
        _ -> Err InvalidDateFormat

parseCalendarDateCentury : List U8 -> Result Utc [InvalidDateFormat]
parseCalendarDateCentury = \bytes ->
    when utf8ToInt bytes is
        Ok century ->
            nanos = century * 100
                |> numDaysSinceEpochToYear
                |> daysToNanos
            nanos |> fromNanosSinceEpoch |> Ok
        Err _ -> Err InvalidDateFormat

parseCalendarDateYear : List U8 -> Result Utc [InvalidDateFormat]
parseCalendarDateYear = \bytes ->
    when utf8ToInt bytes is
        Ok year ->
            nanos = year
                |> numDaysSinceEpochToYear
                |> daysToNanos
            nanos |> fromNanosSinceEpoch |> Ok
        Err _ -> Err InvalidDateFormat

parseCalendarDateMonth : List U8 -> Result Utc [InvalidDateFormat]
parseCalendarDateMonth = \bytes -> 
    when splitListAtIndices bytes [4,5] is
        [yearBytes, _, monthBytes] -> 
            when (utf8ToInt yearBytes, utf8ToInt monthBytes) is
            (Ok year, Ok month) if month >= 1 && month <= 12 ->
                numDaysSinceEpoch { year, month, day: 1} 
                    |> daysToNanos |> fromNanosSinceEpoch |> Ok
            (_, _) -> Err InvalidDateFormat
        _ -> Err InvalidDateFormat

parseOrdinalDateBasic : List U8 -> Result Utc [InvalidDateFormat]
parseOrdinalDateBasic = \bytes -> 
    when splitListAtIndices bytes [4] is
        [yearBytes, dayBytes] -> 
            when (utf8ToInt yearBytes, utf8ToInt dayBytes) is
            (Ok year, Ok day) if day >= 1 && day <= 366 ->
                numDaysSinceEpoch {year, month: 1, day} 
                    |> daysToNanos |> fromNanosSinceEpoch |> Ok
            (_, _) -> Err InvalidDateFormat
        _ -> Err InvalidDateFormat

parseOrdinalDateExtended : List U8 -> Result Utc [InvalidDateFormat]
parseOrdinalDateExtended = \bytes -> 
    when splitListAtIndices bytes [4,5] is
        [yearBytes, _, dayBytes] -> 
            when (utf8ToInt yearBytes, utf8ToInt dayBytes) is
            (Ok year, Ok day) if day >= 1 && day <= 366 ->
                numDaysSinceEpoch {year, month: 1, day} 
                    |> daysToNanos |> fromNanosSinceEpoch |> Ok
            (_, _) -> Err InvalidDateFormat
        _ -> Err InvalidDateFormat

parseWeekDateBasic : List U8 -> Result Utc [InvalidDateFormat]
parseWeekDateBasic = \bytes -> 
    when splitListAtIndices bytes [4,5,7] is
        [yearBytes, _, weekBytes, dayBytes] -> 
            when (utf8ToInt yearBytes, utf8ToInt weekBytes, utf8ToInt dayBytes) is
            (Ok y, Ok w, Ok d) if w >= 1 && w <= 52 && d >= 1 && d <= 7 ->
                calendarWeekToUtc {year: y, week: w, day: d}
            (_, _, _) -> Err InvalidDateFormat
        _ -> Err InvalidDateFormat

parseWeekDateExtended : List U8 -> Result Utc [InvalidDateFormat]
parseWeekDateExtended = \bytes -> 
    when splitListAtIndices bytes [4,6,8,9] is
        [yearBytes, _, weekBytes, _, dayBytes] -> 
            when (utf8ToInt yearBytes, utf8ToInt weekBytes, utf8ToInt dayBytes) is
            (Ok y, Ok w, Ok d) if w >= 1 && w <= 52 && d >= 1 && d <= 7 ->
                calendarWeekToUtc {year: y, week: w, day: d}
            (_, _, _) -> Err InvalidDateFormat
        _ -> Err InvalidDateFormat

parseWeekDateReducedBasic : List U8 -> Result Utc [InvalidDateFormat]
parseWeekDateReducedBasic = \bytes -> 
    when splitListAtIndices bytes [4,5] is
        [yearBytes, _, weekBytes] -> 
            when (utf8ToInt yearBytes, utf8ToInt weekBytes) is
            (Ok year, Ok week) if week >= 1 && week <= 52 ->
                calendarWeekToUtc {year, week, day: 1}
            (_, _) -> Err InvalidDateFormat
        _ -> Err InvalidDateFormat

parseWeekDateReducedExtended : List U8 -> Result Utc [InvalidDateFormat]
parseWeekDateReducedExtended = \bytes -> 
    when splitListAtIndices bytes [4,6] is
        [yearBytes, _, weekBytes] -> 
            when (utf8ToInt yearBytes, utf8ToInt weekBytes) is
            (Ok year, Ok week) if week >= 1 && week <= 52  ->
                calendarWeekToUtc {year, week, day: 1}
            (_, _) -> Err InvalidDateFormat
        _ -> Err InvalidDateFormat

calendarWeekToUtc : {year: U64, week: U64, day? U64} -> Result Utc [InvalidDateFormat]
calendarWeekToUtc = \{week, year, day? 1} ->
    if week >= 1 && week <= weeksPerYear then
        weekDaysSoFar = (calendarWeekToDaysInYear week year)
        numDaysSinceEpoch {year, month: 1, day: (day + weekDaysSoFar)} |> daysToNanos |> fromNanosSinceEpoch |> Ok # month field should be optional, bug compiler bug prevents this
    else
        Err InvalidDateFormat

parseTimeFromStr: Str -> Result UtcTime [InvalidTimeFormat]
parseTimeFromStr = \str ->
    Str.toUtf8 str |> parseTimeFromU8
        
parseTimeFromU8 : List U8 -> Result UtcTime [InvalidTimeFormat]
parseTimeFromU8 = \bytes ->
    if validateUtf8SingleBytes bytes then
        strippedBytes = stripTandZ bytes
        when strippedBytes is
            [_,_] -> parseLocalTimeHour strippedBytes # hh
            [_,_,_,_] -> parseLocalTimeMinuteBasic strippedBytes # hhmm
            [_,_,':',_,_] -> parseLocalTimeMinuteExtended strippedBytes # hh:mm
            [_,_,_,_,_,_] -> parseLocalTimeBasic strippedBytes # hhmmss
            [_,_,':',_,_,':',_,_] -> parseLocalTimeExtended strippedBytes # hh:mm:ss
            _ -> Err InvalidTimeFormat
    else
        Err InvalidTimeFormat

parseLocalTimeHour : List U8 -> Result UtcTime [InvalidTimeFormat]
parseLocalTimeHour = \bytes ->
    when utf8ToInt bytes is
        Ok hour if hour >= 0 && hour <= 24 ->
            hour * 60 * 60 * nanosPerSecond
                |> fromNanosSinceMidnight |> Ok
        Ok _ -> Err InvalidTimeFormat
        Err _ -> Err InvalidTimeFormat

parseLocalTimeMinuteBasic : List U8 -> Result UtcTime [InvalidTimeFormat]
parseLocalTimeMinuteBasic = \bytes ->
    when splitListAtIndices bytes [2] is
        [hourBytes, minuteBytes] -> 
            when (utf8ToInt hourBytes, utf8ToInt minuteBytes) is
            (Ok hour, Ok minute) if hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59 ->
                hourNanos = (hour * 60 * 60 * nanosPerSecond) 
                minuteNanos = (minute * 60 * nanosPerSecond)
                hourNanos + minuteNanos |> fromNanosSinceMidnight |> Ok
            (Ok 24, Ok 0) -> 
                (24 * 60 * 60 * nanosPerSecond) |> fromNanosSinceMidnight |> Ok
            (_, _) -> Err InvalidTimeFormat
        _ -> Err InvalidTimeFormat

parseLocalTimeMinuteExtended : List U8 -> Result UtcTime [InvalidTimeFormat]
parseLocalTimeMinuteExtended = \bytes ->
    when splitListAtIndices bytes [2,3] is
        [hourBytes, _, minuteBytes] -> 
            when (utf8ToInt hourBytes, utf8ToInt minuteBytes) is
            (Ok hour, Ok minute) if hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59 ->
                hourNanos = (hour * 60 * 60 * nanosPerSecond) 
                minuteNanos = (minute * 60 * nanosPerSecond)
                hourNanos + minuteNanos |> fromNanosSinceMidnight |> Ok
            (Ok 24, Ok 0) ->
                (24 * 60 * 60 * nanosPerSecond) |> fromNanosSinceMidnight |> Ok
            (_, _) -> Err InvalidTimeFormat
        _ -> Err InvalidTimeFormat

parseLocalTimeBasic : List U8 -> Result UtcTime [InvalidTimeFormat]
parseLocalTimeBasic = \bytes ->
    when splitListAtIndices bytes [2,4] is
        [hourBytes, minuteBytes, secondBytes] -> 
            when (utf8ToInt hourBytes, utf8ToInt minuteBytes, utf8ToInt secondBytes) is
            (Ok h, Ok m, Ok s) if h >= 0 && h <= 23 && m >= 0 && m <= 59 && s >= 0 && s <= 59 ->
                hourNanos = (h * 60 * 60 * nanosPerSecond) 
                minuteNanos = (m * 60 * nanosPerSecond)
                secondNanos = (s * nanosPerSecond)
                hourNanos + minuteNanos + secondNanos |> fromNanosSinceMidnight |> Ok
            (Ok 24, Ok 0, Ok 0) ->
                (24 * 60 * 60 * nanosPerSecond) |> fromNanosSinceMidnight |> Ok
            (_, _, _) -> Err InvalidTimeFormat
        _ -> Err InvalidTimeFormat

parseLocalTimeExtended : List U8 -> Result UtcTime [InvalidTimeFormat]
parseLocalTimeExtended = \bytes ->
    when splitListAtIndices bytes [2,3,5,6] is
        [hourBytes, _, minuteBytes, _, secondBytes] -> 
            when (utf8ToInt hourBytes, utf8ToInt minuteBytes, utf8ToInt secondBytes) is
            (Ok h, Ok m, Ok s) if h >= 0 && h <= 23 && m >= 0 && m <= 59 && s >= 0 && s <= 59 ->
                hourNanos = (h * 60 * 60 * nanosPerSecond) 
                minuteNanos = (m * 60 * nanosPerSecond)
                secondNanos = (s * nanosPerSecond)
                hourNanos + minuteNanos + secondNanos |> fromNanosSinceMidnight |> Ok
            (Ok 24, Ok 0, Ok 0) ->
                (24 * 60 * 60 * nanosPerSecond) |> fromNanosSinceMidnight |> Ok
            (_, _, _) -> Err InvalidTimeFormat
        _ -> Err InvalidTimeFormat

stripTandZ : List U8 -> List U8
stripTandZ = \bytes ->
    when bytes is
        ['T', .. as tail] -> stripTandZ tail
        [.. as head, 'Z'] -> head
        _ -> bytes

