interface DateTime
    exposes []
    imports [
        Utils.{
            unwrap, 
            daysToNanos,
            numDaysSinceEpoch,
            numDaysSinceEpochToYear,
            splitStrAtDelimiter,
        },
    ]

## Stores a timestamp as nanoseconds since UNIX EPOCH
## Note that this implementation only supports dates after 1970
Utc := U128 implements [Inspect, Eq]

# TODO: use regex? library?
parseDate : Str -> Result Utc [InvalidDateStr]
parseDate =\ str ->
    when Str.countUtf8Bytes str is
        2 -> 
            # Calendar Date: Century
            # YY
            parseYearStr str
        4 -> 
            # Calendar Date: Year
            # YYYY
            parseYearStr str
        7 -> 
            # Calendar Date: Month
            # YYYY-MM
            parseYearMonthStr str
            # Ordinal Date: Basic
            # YYYYDDD
        8 -> 
            # Calendar Date: Basic Complete
            # YYYYMMDD
            # Week Date: Basic
            # YYYYWwwD
            crash "parseDate: Not implemented"
        10 -> 
            # Calendar Date: Extended Complete
            # YYYY-MM-DD
            # Week Date: Extended
            # YYYY-Www-D
            crash "parseDate: Not implemented"
        _ -> Err InvalidDateStr

expect unwrap (parseDate "24") "Oops!" == @Utc (Num.toU128 (19723 * 86400 * 1000000000))
expect unwrap (parseDate "2024") "Oops!" == @Utc (Num.toU128 (19723 * 86400 * 1000000000))
expect unwrap (parseDate "2024-02") "Oops!" == @Utc (Num.toU128 ((19723 + 31) * 86400 * 1000000000))

parseYearStr : Str -> Result Utc [InvalidDateStr]
parseYearStr = \str -> 
    when Str.toNat str is
        Ok year if Str.countUtf8Bytes str == 2 && year >= 20 -> 
            nanos = year * 100
                |> numDaysSinceEpochToYear
                |> daysToNanos
            Ok (@Utc nanos)
        Ok year if year >= 1970 -> 
            nanos = year
                |> numDaysSinceEpochToYear
                |> daysToNanos
            Ok (@Utc nanos)
        Ok year -> Err InvalidDateStr
        Err _ -> Err InvalidDateStr

parseYearMonthStr : Str -> Result Utc [InvalidDateStr]
parseYearMonthStr = \str ->
    substrs = Str.split str "-"
    if List.len substrs == 2 then
        yearStr = unwrap (List.get substrs 0) "parseYearMonthStr: get year str failed"
        monthStr = unwrap (List.get substrs 1) "parseYearMonthStr: get month str failed"
        when Str.toNat yearStr is
            Ok year if year >= 1970 ->
                when Str.toNat monthStr is
                    Ok month if month >= 1 && month <= 12 ->
                        nanos = numDaysSinceEpoch { year, month }
                            |> daysToNanos
                        Ok (@Utc nanos)
                    Ok _ -> Err InvalidDateStr
                    Err _ -> Err InvalidDateStr
            Ok year -> crash "parseYearStr: Not implemented - years before 1970: \(Num.toStr year)"
            Err _ -> Err InvalidDateStr
    else
        Err InvalidDateStr

parseMonthStr : Str -> Result Utc [InvalidDateStr]
parseMonthStr = \str ->
    when Str.toNat str is
        Ok month if month >= 1 && month <= 12 ->
            nanos = numDaysSinceEpoch { year: 1970, month }
                |> daysToNanos
            Ok (@Utc nanos)
        Ok _ -> Err InvalidDateStr
        Err _ -> Err InvalidDateStr

parseDayStr : Str -> Result Utc [InvalidDateStr]
parseDayStr : \str ->
    when Str.toNat str is
        Ok days if days >= 1 && day <= 366 ->
            daysToNanos days
        Ok _ -> Err InvalidDateStr
        Err _ -> Err InvalidDateStr

parseWeekStr : Str -> Result Utc [InvalidDateStr]
parseWeekStr : \str ->
    when Str.toNat str is
        Ok week if week >= 1 && week <= 53 ->
            daysToNanos (week * 7)
        Ok _ -> Err InvalidDateStr
        Err _ -> Err InvalidDateStr