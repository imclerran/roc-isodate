interface Parser
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
            nanosPerHour,
            nanosPerMinute,
            nanosPerSecond,
        },
        Utils.{
            splitListAtIndices,
            splitUtf8AndKeepDelimiters,
            stripTandZ,
            utf8ToFrac,
            utf8ToInt,
            utf8ToIntSigned,
            validateUtf8SingleBytes,
        },
        Date,
        Date.{ Date },
        DateTime,
        DateTime.{ DateTime },
        Duration,
        Duration.{ Duration },
        #DateTimeInterval,
        Time,
        Time.{ Time },
        Unsafe.{ unwrap }, # for unit testing only 
    ]

expect 
    dateTime = parseDateFromStr "1970" |> unwrap "invalid date"
    dateTime == Date.fromYmd 1970 1 1

parseDateFromStr: Str -> Result Date [InvalidDateFormat]
parseDateFromStr = \str -> Str.toUtf8 str |> parseDateFromU8

# TODO: More efficient parsing method?
parseDateFromU8 : List U8 -> Result Date [InvalidDateFormat]
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

parseCalendarDateBasic : List U8 -> Result Date [InvalidDateFormat]
parseCalendarDateBasic = \bytes ->
    when splitListAtIndices bytes [4, 6] is
        [yearBytes, monthBytes, dayBytes] ->
            when (utf8ToInt yearBytes, utf8ToInt monthBytes, utf8ToInt dayBytes) is
            (Ok y, Ok m, Ok d) if m >= 1 && m <= 12 && d >= 1 && d <= 31 ->
                Date.fromYmd y m d |> Ok
            (_, _, _) -> Err InvalidDateFormat
        _ -> Err InvalidDateFormat

parseCalendarDateExtended  : List U8 -> Result Date [InvalidDateFormat]
parseCalendarDateExtended = \bytes -> 
    when splitListAtIndices bytes [4,5,7,8] is
        [yearBytes, _, monthBytes, _, dayBytes] -> 
            when (utf8ToIntSigned yearBytes, utf8ToInt monthBytes, utf8ToInt dayBytes) is
            (Ok y, Ok m, Ok d) if m >= 1 && m <= 12 && d >= 1 && d <= 31 ->
                Date.fromYmd y m d |> Ok
            (_, _, _) -> Err InvalidDateFormat
        _ -> Err InvalidDateFormat

parseCalendarDateCentury : List U8 -> Result Date [InvalidDateFormat]
parseCalendarDateCentury = \bytes ->
    when utf8ToIntSigned bytes is
        Ok century -> Date.fromYmd (century * 100) 1 1 |> Ok
        Err _ -> Err InvalidDateFormat

parseCalendarDateYear : List U8 -> Result Date [InvalidDateFormat]
parseCalendarDateYear = \bytes ->
    when utf8ToIntSigned bytes is
        Ok year -> Date.fromYmd year 1 1 |> Ok
        Err _ -> Err InvalidDateFormat

parseCalendarDateMonth : List U8 -> Result Date [InvalidDateFormat]
parseCalendarDateMonth = \bytes -> 
    when splitListAtIndices bytes [4,5] is
        [yearBytes, _, monthBytes] -> 
            when (utf8ToIntSigned yearBytes, utf8ToInt monthBytes) is
            (Ok year, Ok month) if month >= 1 && month <= 12 ->
                Date.fromYmd year month 1 |> Ok
            (_, _) -> Err InvalidDateFormat
        _ -> Err InvalidDateFormat

parseOrdinalDateBasic : List U8 -> Result Date [InvalidDateFormat]
parseOrdinalDateBasic = \bytes -> 
    when splitListAtIndices bytes [4] is
        [yearBytes, dayBytes] -> 
            when (utf8ToIntSigned yearBytes, utf8ToInt dayBytes) is
            (Ok year, Ok day) if day >= 1 && day <= 366 ->
                Date.fromYd year day |> Ok
            (_, _) -> Err InvalidDateFormat
        _ -> Err InvalidDateFormat

parseOrdinalDateExtended : List U8 -> Result Date [InvalidDateFormat]
parseOrdinalDateExtended = \bytes -> 
    when splitListAtIndices bytes [4,5] is
        [yearBytes, _, dayBytes] -> 
            when (utf8ToIntSigned yearBytes, utf8ToInt dayBytes) is
            (Ok year, Ok day) if day >= 1 && day <= 366 ->
                Date.fromYd year day |> Ok
            (_, _) -> Err InvalidDateFormat
        _ -> Err InvalidDateFormat

parseWeekDateBasic : List U8 -> Result Date [InvalidDateFormat]
parseWeekDateBasic = \bytes -> 
    when splitListAtIndices bytes [4,5,7] is
    [yearBytes, _, weekBytes, dayBytes] -> 
        when (utf8ToInt yearBytes, utf8ToInt weekBytes, utf8ToInt dayBytes) is
        (Ok y, Ok w, Ok d) if w >= 1 && w <= 52 && d >= 1 && d <= 7 ->
            Date.fromYwd y w d |> Ok
        (_, _, _) -> Err InvalidDateFormat
    _ -> Err InvalidDateFormat

parseWeekDateExtended : List U8 -> Result Date [InvalidDateFormat]
parseWeekDateExtended = \bytes -> 
    when splitListAtIndices bytes [4,6,8,9] is
    [yearBytes, _, weekBytes, _, dayBytes] -> 
        when (utf8ToInt yearBytes, utf8ToInt weekBytes, utf8ToInt dayBytes) is
        (Ok y, Ok w, Ok d) if w >= 1 && w <= 52 && d >= 1 && d <= 7 ->
            Date.fromYwd y w d |> Ok
        (_, _, _) -> Err InvalidDateFormat
    _ -> Err InvalidDateFormat

parseWeekDateReducedBasic : List U8 -> Result Date [InvalidDateFormat]
parseWeekDateReducedBasic = \bytes -> 
    when splitListAtIndices bytes [4,5] is
        [yearBytes, _, weekBytes] -> 
            when (utf8ToInt yearBytes, utf8ToInt weekBytes) is
            (Ok year, Ok week) if week >= 1 && week <= 52 ->
                Date.fromYw year week |> Ok
            (_, _) -> Err InvalidDateFormat
        _ -> Err InvalidDateFormat

parseWeekDateReducedExtended : List U8 -> Result Date [InvalidDateFormat]
parseWeekDateReducedExtended = \bytes -> 
    when splitListAtIndices bytes [4,6] is
        [yearBytes, _, weekBytes] -> 
            when (utf8ToInt yearBytes, utf8ToInt weekBytes) is
            (Ok year, Ok week) if week >= 1 && week <= 52  ->
                Date.fromYw year week |> Ok
            (_, _) -> Err InvalidDateFormat
        _ -> Err InvalidDateFormat

parseTimeFromStr: Str -> Result Time [InvalidTimeFormat]
parseTimeFromStr = \str -> Str.toUtf8 str |> parseTimeFromU8
        
parseTimeFromU8 : List U8 -> Result Time [InvalidTimeFormat]
parseTimeFromU8 = \bytes ->
    if validateUtf8SingleBytes bytes then
        strippedBytes = stripTandZ bytes
        when (splitUtf8AndKeepDelimiters strippedBytes ['.', ',', '+', '-'], List.last bytes) is
            # time.fractionaltime+timeoffset / time,fractionaltime-timeoffset
            ([timeBytes, [byte1], fractionalBytes, [byte2], offsetBytes], Ok lastByte) if lastByte != 'Z' -> 
                timeRes = parseFractionalTime timeBytes (List.join [[byte1], fractionalBytes])
                offsetRes = parseTimeOffset (List.join [[byte2], offsetBytes])
                combineTimeAndOffsetResults timeRes offsetRes
            # time+timeoffset / time-timeoffset
            ([timeBytes, [byte1], offsetBytes], Ok lastByte) if (byte1 == '+' || byte1 == '-') && lastByte != 'Z' -> 
                timeRes = parseWholeTime timeBytes
                offsetRes = parseTimeOffset (List.join [[byte1], offsetBytes])
                combineTimeAndOffsetResults timeRes offsetRes
            # time.fractionaltime / time,fractionaltime
            ([timeBytes, [byte1], fractionalBytes], _) if byte1 == ',' || byte1 == '.' -> 
                parseFractionalTime timeBytes (List.join [[byte1], fractionalBytes])
            # time
            ([timeBytes], _) -> parseWholeTime timeBytes
            _ -> Err InvalidTimeFormat
    else
        Err InvalidTimeFormat

combineTimeAndOffsetResults = \timeRes, offsetRes ->
    when (timeRes, offsetRes) is
        (Ok time, Ok offset) -> 
            Duration.addTimeAndDuration time offset |> Ok
        (_, _) -> Err InvalidTimeFormat

parseWholeTime : List U8 -> Result Time [InvalidTimeFormat]
parseWholeTime = \bytes ->
    when bytes is
        [_,_] -> parseLocalTimeHour bytes # hh
        [_,_,_,_] -> parseLocalTimeMinuteBasic bytes # hhmm
        [_,_,':',_,_] -> parseLocalTimeMinuteExtended bytes # hh:mm
        [_,_,_,_,_,_] -> parseLocalTimeBasic bytes # hhmmss
        [_,_,':',_,_,':',_,_] -> parseLocalTimeExtended bytes # hh:mm:ss
        _ -> Err InvalidTimeFormat

parseFractionalTime : List U8, List U8 -> Result Time [InvalidTimeFormat]
parseFractionalTime = \wholeBytes, fractionalBytes ->
    combineDurationResAndTime = \durationRes, time ->
        when durationRes is
            Ok duration -> Duration.addTimeAndDuration time duration |> Ok
            Err _ -> Err InvalidTimeFormat
    when (wholeBytes, utf8ToFrac fractionalBytes) is
        ([_,_], Ok frac) -> # hh
            time <- parseLocalTimeHour wholeBytes |> Result.try
            frac * nanosPerHour |> Num.round |> Duration.fromNanoseconds |> combineDurationResAndTime time
        ([_,_,_,_], Ok frac) -> # hhmm
            time <- parseLocalTimeMinuteBasic wholeBytes |> Result.try
            frac * nanosPerMinute |> Num.round |> Duration.fromNanoseconds |> combineDurationResAndTime time
        ([_,_,':',_,_], Ok frac) -> # hh:mm
            time <- parseLocalTimeMinuteExtended wholeBytes |> Result.try 
            frac * nanosPerMinute |> Num.round |> Duration.fromNanoseconds |> combineDurationResAndTime time
        ([_,_,_,_,_,_], Ok frac) -> # hhmmss
            time <- parseLocalTimeBasic wholeBytes |> Result.try
            frac * nanosPerSecond |> Num.round |> Duration.fromNanoseconds |> combineDurationResAndTime time
        ([_,_,':',_,_,':',_,_], Ok frac) -> # hh:mm:ss
            time <- parseLocalTimeExtended wholeBytes |> Result.try
            frac * nanosPerSecond |> Num.round |> Duration.fromNanoseconds |> combineDurationResAndTime time
        _ -> Err InvalidTimeFormat

parseTimeOffset : List U8 -> Result Duration [InvalidTimeFormat]
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

parseTimeOffsetHelp : U8, U8, U8, U8, I64 -> Result Duration [InvalidTimeFormat]
parseTimeOffsetHelp = \h1, h2, m1, m2, sign ->
    isValidOffset = \offset -> if offset >= -14 * nanosPerHour && offset <= 12 * nanosPerHour then Valid else Invalid
    when (utf8ToIntSigned [h1,h2], utf8ToIntSigned [m1,m2]) is
        (Ok hour, Ok minute) ->
            offsetNanos = sign * (hour * nanosPerHour + minute * nanosPerMinute)
            when isValidOffset offsetNanos is
                Valid -> Duration.fromNanoseconds offsetNanos |>Result.mapErr \_ -> InvalidTimeFormat
                Invalid -> Err InvalidTimeFormat
        (_, _) -> Err InvalidTimeFormat
    
parseLocalTimeHour : List U8 -> Result Time [InvalidTimeFormat]
parseLocalTimeHour = \bytes ->
    when utf8ToIntSigned bytes is
        Ok hour if hour >= 0 && hour <= 24 ->
            Time.fromHms hour 0 0 |> Ok
        Ok _ -> Err InvalidTimeFormat
        Err _ -> Err InvalidTimeFormat

parseLocalTimeMinuteBasic : List U8 -> Result Time [InvalidTimeFormat]
parseLocalTimeMinuteBasic = \bytes ->
    when splitListAtIndices bytes [2] is
        [hourBytes, minuteBytes] -> 
            when (utf8ToIntSigned hourBytes, utf8ToIntSigned minuteBytes) is
            (Ok hour, Ok minute) if hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59 ->
                Time.fromHms hour minute 0 |> Ok
            (Ok 24, Ok 0) -> 
                Time.fromHms 24 0 0 |> Ok
            (_, _) -> Err InvalidTimeFormat
        _ -> Err InvalidTimeFormat

parseLocalTimeMinuteExtended : List U8 -> Result Time [InvalidTimeFormat]
parseLocalTimeMinuteExtended = \bytes ->
    when splitListAtIndices bytes [2,3] is
        [hourBytes, _, minuteBytes] -> 
            when (utf8ToIntSigned hourBytes, utf8ToIntSigned minuteBytes) is
            (Ok hour, Ok minute) if hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59 ->
                Time.fromHms hour minute 0 |> Ok
            (Ok 24, Ok 0) ->
                Time.fromHms 24 0 0 |> Ok
            (_, _) -> Err InvalidTimeFormat
        _ -> Err InvalidTimeFormat

parseLocalTimeBasic : List U8 -> Result Time [InvalidTimeFormat]
parseLocalTimeBasic = \bytes ->
    when splitListAtIndices bytes [2,4] is
        [hourBytes, minuteBytes, secondBytes] -> 
            when (utf8ToIntSigned hourBytes, utf8ToIntSigned minuteBytes, utf8ToIntSigned secondBytes) is
            (Ok h, Ok m, Ok s) if h >= 0 && h <= 23 && m >= 0 && m <= 59 && s >= 0 && s <= 59 ->
                Time.fromHms h m s |> Ok
            (Ok 24, Ok 0, Ok 0) ->
                Time.fromHms 24 0 0 |> Ok
            (_, _, _) -> Err InvalidTimeFormat
        _ -> Err InvalidTimeFormat

parseLocalTimeExtended : List U8 -> Result Time [InvalidTimeFormat]
parseLocalTimeExtended = \bytes ->
    when splitListAtIndices bytes [2,3,5,6] is
        [hourBytes, _, minuteBytes, _, secondBytes] -> 
            when (utf8ToIntSigned hourBytes, utf8ToIntSigned minuteBytes, utf8ToIntSigned secondBytes) is
            (Ok h, Ok m, Ok s) if h >= 0 && h <= 23 && m >= 0 && m <= 59 && s >= 0 && s <= 59 ->
                Time.fromHms h m s |> Ok
            (Ok 24, Ok 0, Ok 0) ->
                Time.fromHms 24 0 0 |> Ok
            (_, _, _) -> Err InvalidTimeFormat
        _ -> Err InvalidTimeFormat

parseDateTimeFromStr : Str -> Result DateTime [InvalidDateTimeFormat]
parseDateTimeFromStr = \str -> Str.toUtf8 str |> parseDateTimeFromU8

parseDateTimeFromU8 : List U8 -> Result DateTime [InvalidDateTimeFormat]
parseDateTimeFromU8 = \bytes ->
    when splitUtf8AndKeepDelimiters bytes ['T'] is
        [dateBytes, ['T'], timeBytes] ->
            when (parseDateFromU8 dateBytes, parseTimeFromU8 timeBytes) is
                (Ok date, Ok time) -> 
                    { date, time } |> Ok
                (_, _) -> Err InvalidDateTimeFormat
        [dateBytes] -> 
            when (parseDateFromU8 dateBytes) is
                Ok date -> { date, time: Time.fromHms 0 0 0 } |> Ok
                Err _ -> Err InvalidDateTimeFormat
        _ -> Err InvalidDateTimeFormat

# parseDateTimeIntervalFromStr : Str -> Result DateTimeInterval [InvalidIntervalFormat]
# parseDateTimeIntervalFromStr = \str -> Str.toUtf8 str |> parseDateTimeIntervalFromU8

# parseDateTimeIntervalFromU8 : List U8 -> Result DateTimeInterval [InvalidIntervalFormat]
# parsePateTimeIntervalFromU8 = \bytes -> 
#     when splitUtf8AndKeepDelimiters bytes ['/','P'] is
#         [dateBytes, ['/'], ['P'], durationBytes] ->
#             when (parseDateFromU8 dateBytes, parseDuration durationBytes) is
#                 (Ok date, Ok duration) -> 
#                     { start: date, end: Duration.addDateAndDuration date duration } |> Ok
#                 (_, _) -> Err InvalidIntervalFormat
#         [['P'], durationBytes, ['/'], dateBytes] ->
#             crash "Not implemented yet"
#         [date1Bytes, ['/'], date2Bytes] -> 
#             crash "Not implemented yet"
#         _ -> Err InvalidIntervalFormat