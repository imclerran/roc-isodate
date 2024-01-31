interface Utils
    exposes [
        calendarWeekToDaysInYear,
        daysToNanos,
        numDaysSinceEpoch,
        numDaysSinceEpochToYear,
        splitListAtIndices,
        utf8ToInt,
        validateUtf8SingleBytes,
    ]
    imports [
        Const.{
            epochYear, 
            epochWeekOffset,
            daysPerWeek,
            leapException,
            leapInterval,
            leapNonException,
            monthDays,
            nanosPerSecond,
            secondsPerDay,
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

validateUtf8SingleBytes : List U8 -> Bool
validateUtf8SingleBytes = \u8List ->
    if List.all u8List \u8 -> Num.bitwiseAnd u8 0b10000000 == 0b00000000 then
        Bool.true
    else
        Bool.false

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

numDaysSinceEpoch: {year: U64, month? U64, day? U64} -> I64
numDaysSinceEpoch = \{year, month? 1, day? 1} ->
    isLeap = isLeapYear year
    numLeapYears = numLeapYearsSinceEpoch year ExcludeCurrent
    if year >= epochYear then
        daysInYears = numLeapYears * 366 + (year - epochYear - numLeapYears) * 365
        daysInMonths = List.sum (
            List.map (List.range { start: At 1, end: Before month }) 
            \mapMonth -> monthDays {month: mapMonth, isLeap}
        )
        (daysInYears + daysInMonths + day - 1) |> Num.toI64
    else
        daysInYears = numLeapYears * 366 + (epochYear - year - numLeapYears - 1) * 365
        daysInMonths = List.sum (
            List.map (List.range { start: After month, end: At 12 }) 
            \mapMonth -> monthDays {month: mapMonth, isLeap}
        )
        (daysInYears + daysInMonths + (monthDays {month, isLeap}) - day + 1)
            |> Num.toI64 |> Num.mul -1

numDaysSinceEpochToYear = \year ->
    numDaysSinceEpoch {year, month: 1, day: 1}

daysToNanos = \days ->
    days * secondsPerDay * nanosPerSecond |> Num.toI128

calendarWeekToDaysInYear : U64, U64 -> U64
calendarWeekToDaysInYear = \week, year->
    # Week 1 of a year is the first week with a majority of its days in that year
    # https://en.wikipedia.org/wiki/ISO_week_date#First_week
    lengthOfMaybeFirstWeek = epochWeekOffset - (numDaysSinceEpochToYear year |> Num.toU64) % 7
    if lengthOfMaybeFirstWeek >= 4 && week == 1 then
        0
    else
        (week - 1) * daysPerWeek + lengthOfMaybeFirstWeek
