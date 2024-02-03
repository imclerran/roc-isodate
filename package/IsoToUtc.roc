interface IsoToUtc
    exposes [
        parseDateFromStr,
        parseDateFromU8,
        parseDateTimeFromStr,
        parseDateTimeFromU8,
        parseTimeFromStr,
        parseTimeFromU8,
    ]
    imports [
        Const.{
            weeksPerYear,
            nanosPerHour,
            nanosPerMinute,
            nanosPerSecond,
        },
        Utc.{
            Utc,
            fromNanosSinceEpoch,
            toNanosSinceEpoch,
        },
        UtcTime.{
            UtcTime,
            addTimes,
            fromNanosSinceMidnight,
            toNanosSinceMidnight,
        },
        Utils.{
            calendarWeekToDaysInYear,
            daysToNanos,
            numDaysSinceEpoch,
            numDaysSinceEpochToYear,
            splitListAtIndices,
            splitUtf8AndKeepDelimiters,
            stripTandZ,
            timeToNanos,
            utf8ToFrac,
            utf8ToInt,
            utf8ToIntSigned,
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
                numDaysSinceEpoch {year: y, month: m, day: d} |> daysToNanos |> fromNanosSinceEpoch |> Ok
            (_, _, _) -> Err InvalidDateFormat
        _ -> Err InvalidDateFormat

parseCalendarDateExtended  : List U8 -> Result Utc [InvalidDateFormat]
parseCalendarDateExtended = \bytes -> 
    when splitListAtIndices bytes [4,5,7,8] is
        [yearBytes, _, monthBytes, _, dayBytes] -> 
            when (utf8ToInt yearBytes, utf8ToInt monthBytes, utf8ToInt dayBytes) is
            (Ok y, Ok m, Ok d) if m >= 1 && m <= 12 && d >= 1 && d <= 31 ->
                numDaysSinceEpoch {year: y, month: m, day: d} |> daysToNanos |> fromNanosSinceEpoch |> Ok
            (_, _, _) -> Err InvalidDateFormat
        _ -> Err InvalidDateFormat

parseCalendarDateCentury : List U8 -> Result Utc [InvalidDateFormat]
parseCalendarDateCentury = \bytes ->
    when utf8ToInt bytes is
        Ok century -> century * 100 |> numDaysSinceEpochToYear |> daysToNanos |> fromNanosSinceEpoch |> Ok
        Err _ -> Err InvalidDateFormat

parseCalendarDateYear : List U8 -> Result Utc [InvalidDateFormat]
parseCalendarDateYear = \bytes ->
    when utf8ToInt bytes is
        Ok year -> year |> numDaysSinceEpochToYear |> daysToNanos |> fromNanosSinceEpoch |> Ok
        Err _ -> Err InvalidDateFormat

parseCalendarDateMonth : List U8 -> Result Utc [InvalidDateFormat]
parseCalendarDateMonth = \bytes -> 
    when splitListAtIndices bytes [4,5] is
        [yearBytes, _, monthBytes] -> 
            when (utf8ToInt yearBytes, utf8ToInt monthBytes) is
            (Ok year, Ok month) if month >= 1 && month <= 12 ->
                numDaysSinceEpoch { year, month, day: 1} |> daysToNanos |> fromNanosSinceEpoch |> Ok
            (_, _) -> Err InvalidDateFormat
        _ -> Err InvalidDateFormat

parseOrdinalDateBasic : List U8 -> Result Utc [InvalidDateFormat]
parseOrdinalDateBasic = \bytes -> 
    when splitListAtIndices bytes [4] is
        [yearBytes, dayBytes] -> 
            when (utf8ToInt yearBytes, utf8ToInt dayBytes) is
            (Ok year, Ok day) if day >= 1 && day <= 366 ->
                numDaysSinceEpoch {year, month: 1, day} |> daysToNanos |> fromNanosSinceEpoch |> Ok
            (_, _) -> Err InvalidDateFormat
        _ -> Err InvalidDateFormat

parseOrdinalDateExtended : List U8 -> Result Utc [InvalidDateFormat]
parseOrdinalDateExtended = \bytes -> 
    when splitListAtIndices bytes [4,5] is
        [yearBytes, _, dayBytes] -> 
            when (utf8ToInt yearBytes, utf8ToInt dayBytes) is
            (Ok year, Ok day) if day >= 1 && day <= 366 ->
                numDaysSinceEpoch {year, month: 1, day} |> daysToNanos |> fromNanosSinceEpoch |> Ok
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
        when (splitUtf8AndKeepDelimiters strippedBytes ['.', ',', '+', '-'], List.last bytes) is
            ([timeBytes, [byte1], fractionalBytes, [byte2], offsetBytes], Ok lastByte) if lastByte != 'Z' -> 
                timeRes = parseFractionalTime timeBytes (List.join [[byte1], fractionalBytes])
                offsetRes = parseTimeOffset (List.join [[byte2], offsetBytes])
                combineTimeAndOffsetResults timeRes offsetRes
            ([timeBytes, [byte1], offsetBytes], Ok lastByte) if (byte1 == '+' || byte1 == '-') && lastByte != 'Z' -> 
                timeRes = parseWholeTime timeBytes
                offsetRes = parseTimeOffset (List.join [[byte1], offsetBytes])
                combineTimeAndOffsetResults timeRes offsetRes
            ([timeBytes, [byte1], fractionalBytes], _) if byte1 == ',' || byte1 == '.' -> 
                parseFractionalTime timeBytes (List.join [[byte1], fractionalBytes])
            ([timeBytes], _) -> parseWholeTime timeBytes
            _ -> Err InvalidTimeFormat
    else
        Err InvalidTimeFormat

combineTimeAndOffsetResults = \timeRes, offsetRes ->
    when (timeRes, offsetRes) is
        (Ok time, Ok offset) -> addTimes time offset |> Ok
        (_, _) -> Err InvalidTimeFormat

parseWholeTime : List U8 -> Result UtcTime [InvalidTimeFormat]
parseWholeTime = \bytes ->
    when bytes is
        [_,_] -> parseLocalTimeHour bytes # hh
        [_,_,_,_] -> parseLocalTimeMinuteBasic bytes # hhmm
        [_,_,':',_,_] -> parseLocalTimeMinuteExtended bytes # hh:mm
        [_,_,_,_,_,_] -> parseLocalTimeBasic bytes # hhmmss
        [_,_,':',_,_,':',_,_] -> parseLocalTimeExtended bytes # hh:mm:ss
        _ -> Err InvalidTimeFormat

parseFractionalTime : List U8, List U8 -> Result UtcTime [InvalidTimeFormat]
parseFractionalTime = \wholeBytes, fractionalBytes ->
    addNanosToTime = \nanos, time -> Num.round nanos |> fromNanosSinceMidnight |> addTimes time
    when (wholeBytes, utf8ToFrac fractionalBytes) is
        ([_,_], Ok frac) -> # hh
            time <- parseLocalTimeHour wholeBytes |> Result.map
            frac * nanosPerHour |> addNanosToTime time
        ([_,_,_,_], Ok frac) -> # hhmm
            time <- parseLocalTimeMinuteBasic wholeBytes |> Result.map
            frac * nanosPerMinute |> addNanosToTime time
        ([_,_,':',_,_], Ok frac) -> # hh:mm
            time <- parseLocalTimeMinuteExtended wholeBytes |> Result.map 
            frac * nanosPerMinute |> addNanosToTime time
        ([_,_,_,_,_,_], Ok frac) -> # hhmmss
            time <- parseLocalTimeBasic wholeBytes |> Result.map
            frac * nanosPerSecond |> addNanosToTime time
        ([_,_,':',_,_,':',_,_], Ok frac) -> # hh:mm:ss
            time <- parseLocalTimeExtended wholeBytes |> Result.map
            frac * nanosPerSecond |> addNanosToTime time
        _ -> Err InvalidTimeFormat

parseTimeOffset : List U8 -> Result UtcTime [InvalidTimeFormat]
parseTimeOffset = \bytes ->
    when bytes is
        ['-',h1,h2] -> 
            parseTimeOffsetHelp h1 h2 '0' '0' 1
        ['+',h1,h2] -> 
            parseTimeOffsetHelp h1 h2 '0' '0' -1
        ['-',h1,h2,m1,m2] -> 
            parseTimeOffsetHelp h1 h2 m1 m2 1
        ['+',h1,h2,m1,m2] ->
            parseTimeOffsetHelp h1 h2 m1 m2 -1
        ['-',h1,h2,':',m1,m2] ->
            parseTimeOffsetHelp h1 h2 m1 m2 1
        ['+',h1,h2,':',m1,m2] ->
            parseTimeOffsetHelp h1 h2 m1 m2 -1
        _ -> Err InvalidTimeFormat

parseTimeOffsetHelp : U8, U8, U8, U8, I64 -> Result UtcTime [InvalidTimeFormat]
parseTimeOffsetHelp = \h1, h2, m1, m2, sign ->
    when (utf8ToIntSigned [h1,h2], utf8ToIntSigned [m1,m2]) is
        (Ok hour, Ok minute) if hour >= 0 && hour <= 14 && minute >= 0 && minute <= 59 ->
            sign * (hour * nanosPerHour + minute * nanosPerMinute) |> fromNanosSinceMidnight |> Ok
        (_, _) -> Err InvalidTimeFormat
    
parseLocalTimeHour : List U8 -> Result UtcTime [InvalidTimeFormat]
parseLocalTimeHour = \bytes ->
    when utf8ToIntSigned bytes is
        Ok hour if hour >= 0 && hour <= 24 ->
            timeToNanos {hour, minute: 0, second: 0} |> fromNanosSinceMidnight |> Ok
        Ok _ -> Err InvalidTimeFormat
        Err _ -> Err InvalidTimeFormat

parseLocalTimeMinuteBasic : List U8 -> Result UtcTime [InvalidTimeFormat]
parseLocalTimeMinuteBasic = \bytes ->
    when splitListAtIndices bytes [2] is
        [hourBytes, minuteBytes] -> 
            when (utf8ToIntSigned hourBytes, utf8ToIntSigned minuteBytes) is
            (Ok hour, Ok minute) if hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59 ->
                timeToNanos {hour, minute, second: 0} |> fromNanosSinceMidnight |> Ok
            (Ok 24, Ok 0) -> 
                timeToNanos {hour: 24, minute: 0, second: 0} |> fromNanosSinceMidnight |> Ok
            (_, _) -> Err InvalidTimeFormat
        _ -> Err InvalidTimeFormat

parseLocalTimeMinuteExtended : List U8 -> Result UtcTime [InvalidTimeFormat]
parseLocalTimeMinuteExtended = \bytes ->
    when splitListAtIndices bytes [2,3] is
        [hourBytes, _, minuteBytes] -> 
            when (utf8ToIntSigned hourBytes, utf8ToIntSigned minuteBytes) is
            (Ok hour, Ok minute) if hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59 ->
                timeToNanos {hour, minute, second: 0} |> fromNanosSinceMidnight |> Ok
            (Ok 24, Ok 0) ->
                timeToNanos {hour: 24, minute: 0, second: 0} |> fromNanosSinceMidnight |> Ok
            (_, _) -> Err InvalidTimeFormat
        _ -> Err InvalidTimeFormat

parseLocalTimeBasic : List U8 -> Result UtcTime [InvalidTimeFormat]
parseLocalTimeBasic = \bytes ->
    when splitListAtIndices bytes [2,4] is
        [hourBytes, minuteBytes, secondBytes] -> 
            when (utf8ToIntSigned hourBytes, utf8ToIntSigned minuteBytes, utf8ToIntSigned secondBytes) is
            (Ok h, Ok m, Ok s) if h >= 0 && h <= 23 && m >= 0 && m <= 59 && s >= 0 && s <= 59 ->
                timeToNanos {hour: h, minute: m, second: s} |> fromNanosSinceMidnight |> Ok
            (Ok 24, Ok 0, Ok 0) ->
                timeToNanos {hour: 24, minute: 0, second: 0} |> fromNanosSinceMidnight |> Ok
            (_, _, _) -> Err InvalidTimeFormat
        _ -> Err InvalidTimeFormat

parseLocalTimeExtended : List U8 -> Result UtcTime [InvalidTimeFormat]
parseLocalTimeExtended = \bytes ->
    when splitListAtIndices bytes [2,3,5,6] is
        [hourBytes, _, minuteBytes, _, secondBytes] -> 
            when (utf8ToIntSigned hourBytes, utf8ToIntSigned minuteBytes, utf8ToIntSigned secondBytes) is
            (Ok h, Ok m, Ok s) if h >= 0 && h <= 23 && m >= 0 && m <= 59 && s >= 0 && s <= 59 ->
                timeToNanos {hour: h, minute: m, second: s} |> fromNanosSinceMidnight |> Ok
            (Ok 24, Ok 0, Ok 0) ->
                timeToNanos {hour: 24, minute: 0, second: 0} |> fromNanosSinceMidnight |> Ok
            (_, _, _) -> Err InvalidTimeFormat
        _ -> Err InvalidTimeFormat

parseDateTimeFromStr : Str -> Result Utc [InvalidDateTimeFormat]
parseDateTimeFromStr = \str ->
    Str.toUtf8 str |> parseDateTimeFromU8

parseDateTimeFromU8 : List U8 -> Result Utc [InvalidDateTimeFormat]
parseDateTimeFromU8 = \bytes ->
    when splitUtf8AndKeepDelimiters bytes ['T'] is
        [dateBytes, ['T'], timeBytes] ->
            when (parseDateFromU8 dateBytes, parseTimeFromU8 timeBytes) is
                (Ok date, Ok time) -> 
                    dateNanos = toNanosSinceEpoch date
                    timeNanos = toNanosSinceMidnight time
                    dateNanos + (Num.toI128 timeNanos) |> fromNanosSinceEpoch |> Ok
                (_, _) -> Err InvalidDateTimeFormat
        [dateBytes] -> 
            parseDateFromU8 dateBytes |> Result.mapErr \_ -> InvalidDateTimeFormat
        _ -> Err InvalidDateTimeFormat

