interface Utils
    exposes [
        calendarWeekToDaysInYear,
        daysToNanos,
        findDecimalIndex,
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
            secondsPerHour,
            secondsPerMinute,
        },
    ]

splitListAtIndices : List a, List U8 -> List (List a)
splitListAtIndices = \list, indices ->
    splitListAtIndicesRecur list (List.sortDesc indices)

splitListAtIndicesRecur : List a, List U8 -> List (List a)
splitListAtIndicesRecur = \list, indices ->
    when indices is
        [x, .. as xs] if x != 0 && x != List.len list |> Num.toU8-> 
            when List.split list (Num.toNat x) is
                {before: head, others: tail} -> 
                    splitListAtIndicesRecur head xs |> List.append tail
        [_, .. as xs] -> 
            splitListAtIndicesRecur list xs
        [] -> [list]

splitUtf8AndKeepDelimiters : List U8, List U8 -> List (List U8)
splitUtf8AndKeepDelimiters = \u8List, delimiters ->
    compareToDelimiters = \b -> List.contains delimiters b |> \isFound -> if isFound then Found else NotFound
    result = List.walk u8List [] \lists, byte ->
        when lists is 
            [.. as xs, []] ->
                when compareToDelimiters byte is
                    Found -> xs |> List.append [byte] |> List.append []
                    NotFound -> xs |> List.append [byte]
            [.. as xs, x] ->
                when compareToDelimiters byte is
                    Found -> xs |> List.append x |> List.append [byte] |> List.append []
                    NotFound -> xs |> List.append (x |> List.append byte)
            [] ->
                when compareToDelimiters byte is
                    Found -> [[byte], []]
                    NotFound -> [[byte]]
    when result is
        [.. as xs, []] -> xs
        _ -> result

validateUtf8SingleBytes : List U8 -> Bool
validateUtf8SingleBytes = \u8List ->
    if List.all u8List \u8 -> Num.bitwiseAnd u8 0b10000000 == 0b00000000 then
        Bool.true
    else
        Bool.false

utf8ToInt : List U8 -> Result U64 [InvalidBytes]
utf8ToInt = \u8List ->
    u8List |> List.reverse |> List.walkWithIndex (Ok 0) \numResult, byte, index ->
        Result.try numResult \num ->
            if 0x30 <= byte && byte <= 0x39 then
                Ok (num + (Num.toU64 byte - 0x30) * (Num.toU64 (Num.powInt 10 (Num.toNat index))))
            else
                Err InvalidBytes

utf8ToIntSigned : List U8 -> Result I64 [InvalidBytes]
utf8ToIntSigned = \u8List ->
    when u8List is
        ['-', .. as xs] ->
            num <- utf8ToInt xs |> Result.map
            -1 * Num.toI64 num
        ['+', .. as xs] ->
            num <- utf8ToInt xs |> Result.map
            Num.toI64 num
        _ -> 
            num <- utf8ToInt u8List |> Result.map
            Num.toI64 num

utf8ToFrac : List U8 -> Result F64 [InvalidBytes]
utf8ToFrac = \u8List -> 
    when findDecimalIndex u8List is
        Ok decimalIndex ->
            when splitListAtIndices u8List [decimalIndex, (decimalIndex + 1)] is
                [head, [byte], tail] if byte == ',' || byte == '.' ->
                    when (utf8ToInt head, utf8ToInt tail) is
                        (Ok intPart, Ok fracPart) ->
                            decimalShift = List.len tail |> Num.toU8
                            Num.toF64 intPart + moveDecimalPoint (Num.toF64 fracPart) decimalShift |> Ok
                        (_, _) -> Err InvalidBytes
                [['.'], tail] -> #if byte == ',' || byte == '.' -> # crashes when using byte comparison
                    fracPart <- utf8ToInt tail |> Result.map
                    decimalShift = List.len tail |> Num.toU8
                    moveDecimalPoint (Num.toF64 fracPart) decimalShift
                [[','], tail] ->#if byte == ',' || byte == '.' -> # crashes when using byte comparison
                    fracPart <- utf8ToInt tail |> Result.map
                    decimalShift = List.len tail |> Num.toU8
                    moveDecimalPoint (Num.toF64 fracPart) decimalShift
                [head, [byte]] if byte == ',' || byte == '.' ->
                    intPart <- utf8ToInt head |> Result.map
                    Num.toF64 intPart
                _ -> 
                    intPart <- utf8ToInt u8List |> Result.map
                    Num.toF64 intPart
        Err NoDecimalPoint -> 
            intPart <- utf8ToInt u8List |> Result.map
            Num.toF64 intPart

findDecimalIndex : List U8 -> Result U8 [NoDecimalPoint]
findDecimalIndex = \u8List ->
    List.walkWithIndexUntil u8List (Err NoDecimalPoint) \_, byte, index ->
        if byte == '.' || byte == ',' then
            Break (Ok (Num.toU8 index))
        else
            Continue (Err NoDecimalPoint)

moveDecimalPoint : F64, U8 -> F64 
moveDecimalPoint = \num, digits ->
    when digits is
        0 -> num
        _ -> (moveDecimalPoint num (digits - 1)) / 10

stripTandZ : List U8 -> List U8
stripTandZ = \bytes ->
    when bytes is
        ['T', .. as tail] -> stripTandZ tail
        [.. as head, 'Z'] -> head
        _ -> bytes

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

timeToNanos : {hour: I64, minute: I64, second: I64} -> I64
timeToNanos = \{hour, minute, second} ->
    (hour * secondsPerHour + minute * secondsPerMinute + second) * nanosPerSecond

calendarWeekToDaysInYear : U64, U64 -> U64
calendarWeekToDaysInYear = \week, year->
    # Week 1 of a year is the first week with a majority of its days in that year
    # https://en.wikipedia.org/wiki/ISO_week_date#First_week
    lengthOfMaybeFirstWeek = 
        if year >= epochYear then 
            epochWeekOffset - (numDaysSinceEpochToYear year |> Num.toU64) % 7
        else
            (epochWeekOffset + (numDaysSinceEpochToYear year |> Num.abs |> Num.toU64)) % 7
    if lengthOfMaybeFirstWeek >= 4 && week == 1 then
        0
    else
        (week - 1) * daysPerWeek + lengthOfMaybeFirstWeek
