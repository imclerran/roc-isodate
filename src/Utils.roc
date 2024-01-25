interface Utils
    exposes [
        numDaysSinceEpoch,
        numDaysSinceEpochToYear,
        daysToNanos,
        splitStrAtIndex,
        splitStrAtIndices,
        calendarWeekToDaysInYear,
        validateUtf8SingleBytes,
    ]
    imports [
        Const.{
            epochYear, 
            epochWeekOffset,
            secondsPerDay,
            nanosPerSecond,
            daysPerWeek,
            leapInterval,
            leapException,
            leapNonException,
            monthDays,
        },
    ]

splitStrAtIndices = \str, indices ->
    sortedIndices = List.sortAsc indices
    splitStrAtIndicesRecur str sortedIndices

splitStrAtIndicesRecur = \str, indices ->
    u8List = Str.toUtf8 str
    when List.last indices is
        Ok index if index > 0 && index < List.len u8List ->
            lists = List.split u8List index
            when (Str.fromUtf8 lists.before, Str.fromUtf8 lists.others) is
                (Ok headStr, Ok tailStr) -> 
                    splitStrAtIndicesRecur headStr (List.dropLast indices 1)
                    |> List.append tailStr
                (_, _) -> 
                    crash "splitStrAtIndicesRecur: should never happen because u8List was parsed from str"
        Ok _ -> splitStrAtIndicesRecur str (List.dropLast indices 1)
        Err _ -> [str]

splitStrAtIndex = \str, index -> splitStrAtIndices str [index]

expect splitStrAtIndex "abc" 0 == ["abc"]
expect splitStrAtIndex "abc" 1 == ["a", "bc"]
expect splitStrAtIndex "abc" 3 == ["abc"]
expect splitStrAtIndices "abc" [1, 2] == ["a", "b", "c"]  
expect splitStrAtIndices "abcde" [3,1,4,2] == ["a", "b", "c", "d", "e"]
expect splitStrAtIndices "abc" [0,5] == ["abc"]

validateUtf8SingleBytes : List U8 -> Result (List U8) [MultibyteCharacters]
validateUtf8SingleBytes = \u8List ->
    if List.all u8List \u8 -> Num.bitwiseAnd u8 0b10000000 == 0b00000000 then
        Ok u8List
    else
        Err MultibyteCharacters

expect validateUtf8SingleBytes [0b01111111] == Ok [0b01111111]
expect validateUtf8SingleBytes [0b10000000, 0b00000001] == Err MultibyteCharacters
expect "🔥" |> Str.toUtf8 |> validateUtf8SingleBytes == Err MultibyteCharacters

utf8ToInt : List U8 -> Result U64 [InvalidBytes]
utf8ToInt = \u8List ->
    u8List 
        |> List.reverse 
        |> List.walkWithIndex (Ok 0) \numResult, byte, index ->
                when numResult is
                    Ok num ->
                        digit = Num.toU64 (byte - 0x30)
                        if digit >= 0 && digit <= 9 then
                            Ok (num + digit * (Num.toU64 (Num.powInt 10 (Num.toNat index))))
                        else
                            Err InvalidBytes
                    Err InvalidBytes -> Err InvalidBytes

expect utf8ToInt ['0', '1', '2', '3'] == Ok 123

isLeapYear = \year ->
    (year % leapInterval == 0 &&
    year % leapException != 0) || 
    year % leapNonException == 0

numLeapYearsSinceEpoch : U64, [IncludeCurrent, ExcludeCurrent] -> U64
numLeapYearsSinceEpoch = \year, inclusive ->
    leapIncr = isLeapYear year |> \isLeap -> if isLeap && inclusive == IncludeCurrent then 1 else 0
    nextYear = if year > epochYear then year - 1 else year + 1
    when inclusive is
        ExcludeCurrent if year != epochYear -> numLeapYearsSinceEpoch nextYear IncludeCurrent
        ExcludeCurrent -> 0
        IncludeCurrent if year != epochYear -> leapIncr + numLeapYearsSinceEpoch nextYear inclusive
        IncludeCurrent -> leapIncr

numDaysSinceEpoch: {year: U64, month? U64, day? U64} -> U64
numDaysSinceEpoch = \{year, month? 1, day? 1} ->
    numLeapYears = numLeapYearsSinceEpoch year ExcludeCurrent
    daysInYears = numLeapYears * 366 + (year - epochYear - numLeapYears) * 365
    isLeap = isLeapYear year
    daysInMonths = List.sum (
        List.map (List.range { start: At 1, end: Before month }) 
        \mapMonth -> monthDays {month: mapMonth, isLeap}
    )
    daysInYears + daysInMonths + day - 1

# expect numDaysSinceEpoch {year: 2024} == 19723 # Removed due to compiler bug with optional record fields
expect numDaysSinceEpoch {year: 1970, month: 12, day: 31} == 365 - 1
expect numDaysSinceEpoch {year: 1971, month: 1, day: 2} == 365 + 1
expect numDaysSinceEpoch {year: 2024, month: 1, day: 1} == 19723
expect numDaysSinceEpoch {year: 2024, month: 2, day: 1} == 19723 + 31
expect numDaysSinceEpoch {year: 2024, month: 12, day: 31} == 19723 + 366 - 1

numDaysSinceEpochToYear = \year ->
    numDaysSinceEpoch {year, month: 1, day: 1}

expect numDaysSinceEpochToYear 1970 == 0
expect numDaysSinceEpochToYear 1971 == 365
expect numDaysSinceEpochToYear 1972 == 365 + 365
expect numDaysSinceEpochToYear 1973 == 365 + 365 + 366
expect numDaysSinceEpochToYear 2024 == 19723

daysToNanos = \days ->
    days * secondsPerDay * nanosPerSecond |> Num.toU128

calendarWeekToDaysInYear = \week, year->
    # Week 1 of a year is the first week with a majority of its days in that year
    # https://en.wikipedia.org/wiki/ISO_week_date#First_week
    lengthOfMaybeFirstWeek = epochWeekOffset - (numDaysSinceEpochToYear year) % 7
    if lengthOfMaybeFirstWeek >= 4 && week == 1 then
        0
    else
        (week - 1) * daysPerWeek + lengthOfMaybeFirstWeek

expect calendarWeekToDaysInYear 1 1970  == 0
expect calendarWeekToDaysInYear 1 1971 == 3
expect calendarWeekToDaysInYear 1 1972 == 2
expect calendarWeekToDaysInYear 1 1973 == 0
expect calendarWeekToDaysInYear 2 2024 == 7