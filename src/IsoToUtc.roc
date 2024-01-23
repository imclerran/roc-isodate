interface IsoToUtc
    exposes [parseDate]
    imports [
        Utils.{
            unwrap, 
            daysToNanos,
            numDaysSinceEpoch,
            numDaysSinceEpochToYear,
            calendarWeekToDaysInYear,
            splitStrAtDelimiter,
            splitStrAtIndices,
            allOk,
        },
        Const.{
            epochYear,
            secondsPerDay,
            nanosPerSecond,
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
    strs = splitStrAtIndices str [4, 6]
    if List.len strs == 3 then
        year = unwrap (List.get strs 0) "parseCalendarDateBasic: will always have index 0" |> Str.toNat
        month = unwrap (List.get strs 1) "parseCalendarDateBasic: will always have index 1" |> Str.toNat
        day = unwrap (List.get strs 2) "parseCalendarDateBasic: will always have index 2" |> Str.toNat
        if allOk [year, month, day] then
            numDaysSinceEpoch { year: (unwrap year "Ok"), month: (unwrap month "Ok"), day: (unwrap day "Ok")} 
                |> daysToNanos |> @Utc |> Ok
        else
            Err InvalidDateFormat
    else
        Err InvalidDateFormat

parseCalendarDateExtended  : Str -> Result Utc [InvalidDateFormat]
parseCalendarDateExtended = \str -> 
    strs = splitStrAtDelimiter str "-"
    if List.len strs == 3 then
        year = unwrap (List.get strs 0) "parseCalendarDateExtended: will always have index 0" |> Str.toNat
        month = unwrap (List.get strs 1) "parseCalendarDateExtended: will always have index 1" |> Str.toNat 
        day = unwrap (List.get strs 2) "parseCalendarDateExtended: will always have index 2" |> Str.toNat
        if allOk [year, month, day] then
            numDaysSinceEpoch { year: (unwrap year "Ok"), month: (unwrap month "Ok"), day: (unwrap day "Ok")} 
                |> daysToNanos |> @Utc |> Ok
        else
            Err InvalidDateFormat
    else
        Err InvalidDateFormat

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
        Ok year if year >= 1970 ->
            nanos = year
                |> numDaysSinceEpochToYear
                |> daysToNanos
            Ok (@Utc nanos)
        Ok _ -> Err InvalidDateFormat
        Err _ -> Err InvalidDateFormat

parseCalendarDateMonth : Str -> Result Utc [InvalidDateFormat]
parseCalendarDateMonth = \str -> 
    strs = splitStrAtDelimiter str "-"
    if List.len strs == 2 then
        year = unwrap (List.get strs 0) "parseCalendarDateMonth: will always have index 0" |> Str.toNat
        month = unwrap (List.get strs 1) "parseCalendarDateMonth: will always have index 1" |> Str.toNat
        if allOk [year, month] then
            numDaysSinceEpoch { year: (unwrap year "Ok"), month: (unwrap month "Ok"), day: 1} 
                |> daysToNanos |> @Utc |> Ok
        else
            Err InvalidDateFormat
    else
        Err InvalidDateFormat

parseOrdinalDateBasic : Str -> Result Utc [InvalidDateFormat]
parseOrdinalDateBasic = \str -> 
    strs = splitStrAtIndices str [4]
    if List.len strs == 2 then
        year = unwrap (List.get strs 0) "parseOrdinalDateBasic: will always have index 0" |> Str.toNat
        day = unwrap (List.get strs 1) "parseOrdinalDateBasic: will always have index 1" |> Str.toNat
        if allOk [year, day] then
            numDaysSinceEpoch {year: (unwrap year "Ok"), month: 1, day: (unwrap day "Ok")} 
                |> daysToNanos |> @Utc |> Ok
        else
            Err InvalidDateFormat
    else
        Err InvalidDateFormat

parseOrdinalDateExtended : Str -> Result Utc [InvalidDateFormat]
parseOrdinalDateExtended = \str -> 
    strs = splitStrAtDelimiter str "-"
    if List.len strs == 2 then
        year = unwrap (List.get strs 0) "parseOrdinalDateExtended: will always have index 0" |> Str.toNat 
        day = unwrap (List.get strs 1) "parseOrdinalDateExtended: will always have index 1" |> Str.toNat
        if allOk [year, day] then
            numDaysSinceEpoch {year: (unwrap year "Ok"), month: 1, day: (unwrap day "Ok")} 
                |> daysToNanos |> @Utc |> Ok
        else
            Err InvalidDateFormat
    else
        Err InvalidDateFormat

parseWeekDateBasic : Str -> Result Utc [InvalidDateFormat]
parseWeekDateBasic = \str -> 
    strs = splitStrAtIndices str [4,5,7]
    if List.len strs == 4 then
        year = unwrap (List.get strs 0) "parseWeekDateBasic: will always have index 0" |> Str.toNat #parseYearStr 
        week = unwrap (List.get strs 2) "parseWeekDateBasic: will always have index 2" |> Str.toNat #parseWeekStr 
        day = unwrap (List.get strs 3) "parseWeekDateBasic: will always have index 3" |> Str.toNat #parseDayStr
        if allOk [year, week, day] then
            calendarWeekToUtc {year: (unwrap year "Ok"), week: (unwrap week "Ok"), day: (unwrap day "Ok")}
        else
            Err InvalidDateFormat
    else
        Err InvalidDateFormat

parseWeekDateExtended : Str -> Result Utc [InvalidDateFormat]
parseWeekDateExtended = \str -> 
    strs = splitStrAtIndices str [4,6,8,9]
    if List.len strs == 5 then
        year = unwrap (List.get strs 0) "parseWeekDateExtended: will alwasy have index 0" |> Str.toNat
        week = unwrap (List.get strs 2) "parseWeekDateExtended: will always have index 2" |> Str.toNat
        day = unwrap (List.get strs 4) "parseWeekDateExtended: will always have index 4" |> Str.toNat
        if allOk [year, week, day] then
            calendarWeekToUtc {year: (unwrap year "year Err"), week: (unwrap week "week Err"), day: (unwrap day "day Err")}
        else
            Err InvalidDateFormat
    else 
        Err InvalidDateFormat

parseWeekDateReducedBasic : Str -> Result Utc [InvalidDateFormat]
parseWeekDateReducedBasic = \str -> 
    strs = splitStrAtIndices str [4,5]
    if List.len strs == 3 then
        year = unwrap (List.get strs 0) "parseWeekDateReducedBasic: will always have index 0" |> Str.toNat
        week = unwrap (List.get strs 2) "parseWeekDateReducedBasic: will always have index 2" |> Str.toNat
        if allOk [year, week] then
            calendarWeekToUtc {year: (unwrap year "year Err"), week: (unwrap week "week Err"), day: 1}
        else
            Err InvalidDateFormat
    else
        Err InvalidDateFormat

parseWeekDateReducedExtended : Str -> Result Utc [InvalidDateFormat]
parseWeekDateReducedExtended = \str -> 
    strs = splitStrAtIndices str [4,6]
    if List.len strs == 3 then
        year = unwrap (List.get strs 0) "parseWeekDateReducedExtended: will always have index 0" |> Str.toNat
        week = unwrap (List.get strs 2) "parseWeekDateReducedExtended: will always have index 2" |> Str.toNat
        if allOk [year, week] then
            calendarWeekToUtc {year: (unwrap year "year Err"), week: (unwrap week "week Err"), day: 1}
        else
            Err InvalidDateFormat
    else
        Err InvalidDateFormat

calendarWeekToUtc : {year: Nat, week: Nat, day? Nat} -> Result Utc [InvalidDateFormat]
calendarWeekToUtc = \{week, year, day? 1} ->
    if week >= 1 && week <= 52 && year > 1970 then
        weekDaysSoFar = (calendarWeekToDaysInYear week year)
        numDaysSinceEpoch {year, day: (day + weekDaysSoFar)} |> daysToNanos |> @Utc |> Ok
    else
        Err InvalidDateFormat