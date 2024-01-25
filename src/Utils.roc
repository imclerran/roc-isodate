interface Utils
    exposes [
        numDaysSinceEpoch,
        numDaysSinceEpochToYear,
        daysToNanos,
        splitListAtIndices,
        calendarWeekToDaysInYear,
        validateUtf8SingleBytes,
        utf8ToInt,
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

splitListAtIndices : List a, List U64 -> List (List a)
splitListAtIndices = \list, indices ->
    splitListAtIndicesRecur list (List.sortDesc indices)

splitListAtIndicesRecur : List a, List U64 -> List (List a)
splitListAtIndicesRecur = \list, indices ->
    when indices is
        [x, .. as xs] if x != 0 && x != List.len list |> Num.toU64-> 
            when List.split list (Num.toNat x) is
                {before: head, others: tail} -> 
                    splitListAtIndicesRecur head xs |> List.append tail
        [_, .. as xs] -> 
            splitListAtIndicesRecur list xs
        [] -> [list]

expect splitListAtIndices [1,2] [0,1,2] == [[1], [2]]
expect splitListAtIndices [1,2] [0] == [[1,2]]
expect splitListAtIndices [1,2] [1] == [[1], [2]]

validateUtf8SingleBytes : List U8 -> Bool
validateUtf8SingleBytes = \u8List ->
    if List.all u8List \u8 -> Num.bitwiseAnd u8 0b10000000 == 0b00000000 then
        Bool.true
    else
        Bool.false

expect validateUtf8SingleBytes [0b01111111]
expect !(validateUtf8SingleBytes [0b10000000, 0b00000001])
expect !("🔥" |> Str.toUtf8 |> validateUtf8SingleBytes)

utf8ToInt : List U8 -> Result U64 [InvalidBytes]
utf8ToInt = \u8List ->
    u8List |> List.reverse |> List.walkWithIndex (Ok 0) \numResult, byte, index ->
        when numResult is
            Ok num ->
                if 0x30 <= byte && byte <= 0x39 then
                    Ok (num + (Num.toU64 byte - 0x30) * (Num.toU64 (Num.powInt 10 (Num.toNat index))))
                else
                    Err InvalidBytes
            Err InvalidBytes -> Err InvalidBytes

expect ['0','1','2','3','4','5','6','7','8','9'] |> utf8ToInt == Ok 123456789
expect utf8ToInt ['@'] == Err InvalidBytes
expect utf8ToInt ['/'] == Err InvalidBytes

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