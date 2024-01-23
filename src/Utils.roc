interface Utils
    exposes [
        unwrap,
        numDaysSinceEpoch,
        numDaysSinceEpochToYear,
        numDaysSinceEpochToYMD,
        daysToNanos,
        splitStrAtDelimiter,
        splitStrAtIndex,
        splitStrAtIndices,
        calendarWeekToDaysInYear,
        allOk,
    ]
    imports [
        Const.{
            epochYear, 
            epochWeekOffset,
            monthDaysNonLeap,
            secondsPerDay,
            nanosPerSecond,
        },
    ]

unwrap : [Ok a, Err _], Str -> a
unwrap = \result, message ->
    when result is
        Ok x -> x
        Err _ -> crash message

allOk : List [Ok _, Err _] -> Bool
allOk = \results ->
    List.all results (\result -> 
            when result is 
                Ok _ -> Bool.true
                Err _ -> Bool.false
    )

splitStrAtDelimiter = \str, delimiter ->
    Str.walkUtf8WithIndex 
        str
        [""]
        (\strList, byte, i -> 
            char = unwrap (Str.fromUtf8 [byte]) "splitStrAtDelimiter: Invalid UTF-8 byte"
            crashMsg = "splitStrAtDelimiter: List should always have last element"
            if char == delimiter then
                if 0 == i || Str.countUtf8Bytes str == i + 1 then
                    strList
                else
                    List.append strList ""
            else
                strs = List.takeFirst strList (List.len strList - 1)
                lastStr = unwrap (List.last strList) crashMsg
                List.append strs (Str.concat lastStr char)
        )

expect splitStrAtDelimiter "abc" "a" == ["bc"]
expect splitStrAtDelimiter "abc" "b" == ["a", "c"]
expect splitStrAtDelimiter "abc" "c" == ["ab"]

splitStrAtIndex = \str, index -> splitStrAtIndices str [index]

expect splitStrAtIndex "abc" 0 == ["abc"]
expect splitStrAtIndex "abc" 1 == ["a", "bc"]
expect splitStrAtIndex "abc" 3 == ["abc"]

splitStrAtIndices = \str, indices ->
    Str.walkUtf8WithIndex 
        str
        [""]
        (\strList, byte, i ->
            char = unwrap (Str.fromUtf8 [byte]) "splitStrAtDelimiter: Invalid UTF-8 byte"
            if List.contains indices i then
                if i == 0 then
                    [char]
                else
                    List.append strList char
            else
                strs = List.takeFirst strList (List.len strList - 1)
                lastStr = unwrap (List.last strList) "splitStrAtDelimiter: List should always have last element"
                List.append strs (Str.concat lastStr char)
        )

expect splitStrAtIndices "abc" [1, 2] == ["a", "b", "c"]


isLeapYear = \year ->
    if year % 4 == 0 then
        yearIsDivisBy100 = year % 100 == 0
        yearIsDivisBy400 = year % 400 == 0
        if yearIsDivisBy100 && yearIsDivisBy400 then
            Bool.true
        else if yearIsDivisBy100 then
            Bool.false
        else 
            Bool.true
    else
        Bool.false

numLeapYearsSinceEpoch = \year, inclusive ->
    years =
        when inclusive is  
            IncludeCurrent -> List.range { start: At epochYear, end: At year }
            ExcludeCurrent -> List.range { start: At epochYear, end: Before year }
    List.countIf years isLeapYear

daysInMonth = \{month, isLeap ? Bool.false} ->
    if month == 2 && isLeap then
        29
    else
        unwrap (Dict.get monthDaysNonLeap month) "daysInMonth: Invalid month"

numDaysSinceEpoch = \{year, month ? 1, day ? 1} ->
    numDaysSinceEpochToYMD year month day

expect numDaysSinceEpoch {year: 2024} == 19723

numDaysSinceEpochToYear = \year ->
    numDaysSinceEpochToYMD year 1 1

expect numDaysSinceEpochToYear 1970 == 0
expect numDaysSinceEpochToYear 1971 == 365
expect numDaysSinceEpochToYear 1972 == 365 + 365
expect numDaysSinceEpochToYear 1973 == 365 + 365 + 366
expect numDaysSinceEpochToYear 2024 == 19723

numDaysSinceEpochToYMD = \year, month, day ->
    numLeapYears = numLeapYearsSinceEpoch year ExcludeCurrent
    daysInYears = numLeapYears * 366 + (year - epochYear - numLeapYears) * 365
    isLeap = isLeapYear year
    daysInMonths = List.sum (List.map (List.range { start: At 1, end: Before month }) (\walkMonth -> daysInMonth {month: walkMonth, isLeap}), )
    daysInYears + daysInMonths + day - 1

expect numDaysSinceEpochToYMD 1970 12 31 == 365 - 1
expect numDaysSinceEpochToYMD 1971 1 2 == 365 + 1
expect numDaysSinceEpochToYMD 2024 1 1 == 19723
expect numDaysSinceEpochToYMD 2024 2 1 == 19723 + 31
expect numDaysSinceEpochToYMD 2024 12 31 == 19723 + 366 - 1

daysToNanos = \days ->
    days * secondsPerDay * nanosPerSecond |> Num.toU128

calendarWeekToDaysInYear = \week, year->
    # Week 1 of a year is the first week with a majority of its days in that year
    # https://en.wikipedia.org/wiki/ISO_week_date#First_week
    lengthOfFirstWeek = epochWeekOffset - (numDaysSinceEpochToYear year) % 7
    if lengthOfFirstWeek >= 4 && week == 1 then
        0
    else
        (week - 1) * 7 + lengthOfFirstWeek

expect calendarWeekToDaysInYear 1 1970  == 0
expect calendarWeekToDaysInYear 1 1971 == 3
expect calendarWeekToDaysInYear 1 1972 == 2
expect calendarWeekToDaysInYear 1 1973 == 0
expect calendarWeekToDaysInYear 2 2024 == 7