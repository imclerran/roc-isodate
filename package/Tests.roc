interface Tests
    exposes []
    imports [
        Const.{
            secondsPerDay,
            nanosPerSecond,
        },
        IsoToUtc.{
            parseDateFromStr,
        },
        Utc.{
            Utc,
            fromNanosSinceEpoch,
        }
    ]

# -- IsoToUtc.roc -- 
# CalendarDateCentury
expect parseDateFromStr "20" == (10_957) * secondsPerDay * nanosPerSecond |> Num.toI128 |> fromNanosSinceEpoch |> Ok
expect parseDateFromStr "19" == Err InvalidDateFormat
expect parseDateFromStr "ab" == Err InvalidDateFormat

# CalendarDateYear
expect parseDateFromStr "2024" == (19_723) * secondsPerDay * nanosPerSecond |> Num.toI128 |> fromNanosSinceEpoch |> Ok
expect parseDateFromStr "1970" == 0 |> Num.toI128 |> fromNanosSinceEpoch |> Ok
expect parseDateFromStr "1969" == Err InvalidDateFormat
expect parseDateFromStr "202f" == Err InvalidDateFormat

# WeekDateReducedBasic
expect parseDateFromStr "2024W04" == (19_723 + 21) * secondsPerDay * nanosPerSecond |> Num.toI128 |> fromNanosSinceEpoch |> Ok
expect parseDateFromStr "1970W01" == 0 |> Num.toI128 |> fromNanosSinceEpoch |> Ok
expect parseDateFromStr "1969W01" == Err InvalidDateFormat
expect parseDateFromStr "2024W53" == Err InvalidDateFormat
expect parseDateFromStr "2024W00" == Err InvalidDateFormat
expect parseDateFromStr "2024Www" == Err InvalidDateFormat

# CalendarDateMonth
expect parseDateFromStr "2024-02" == (19_723 + 31) * secondsPerDay * nanosPerSecond |> Num.toI128 |> fromNanosSinceEpoch |> Ok
expect parseDateFromStr "1970-01" == 0 |> Num.toI128 |> fromNanosSinceEpoch |> Ok
expect parseDateFromStr "1969-01" == Err InvalidDateFormat
expect parseDateFromStr "2024-13" == Err InvalidDateFormat
expect parseDateFromStr "2024-00" == Err InvalidDateFormat
expect parseDateFromStr "2024-0a" == Err InvalidDateFormat

# OrdinalDateBasic
expect parseDateFromStr "2024023" == (19_723 + 22) * secondsPerDay * nanosPerSecond |> Num.toI128 |> fromNanosSinceEpoch |> Ok
expect parseDateFromStr "1970001" == 0 |> Num.toI128 |> fromNanosSinceEpoch |> Ok
expect parseDateFromStr "1969001" == Err InvalidDateFormat
expect parseDateFromStr "2024000" == Err InvalidDateFormat
expect parseDateFromStr "2024367" == Err InvalidDateFormat
expect parseDateFromStr "2024a23" == Err InvalidDateFormat

# WeekDateReducedExtended
expect parseDateFromStr "2024-W04" == (19_723 + 21) * secondsPerDay * nanosPerSecond |> Num.toI128 |> fromNanosSinceEpoch |> Ok
expect parseDateFromStr "1970-W01" == 0 |> Num.toI128 |> fromNanosSinceEpoch |> Ok
expect parseDateFromStr "1969-W01" == Err InvalidDateFormat
expect parseDateFromStr "2024-W53" == Err InvalidDateFormat
expect parseDateFromStr "2024-W00" == Err InvalidDateFormat
expect parseDateFromStr "2024-Ww1" == Err InvalidDateFormat

# WeekDateBasic
expect parseDateFromStr "2024W042" == (19_723 + 22) * secondsPerDay * nanosPerSecond |> Num.toI128 |> fromNanosSinceEpoch |> Ok
expect parseDateFromStr "1970W011" == 0 |> Num.toI128 |> fromNanosSinceEpoch |> Ok
expect parseDateFromStr "1969W001" == Err InvalidDateFormat
expect parseDateFromStr "2024W000" == Err InvalidDateFormat
expect parseDateFromStr "2024W531" == Err InvalidDateFormat
expect parseDateFromStr "2024W010" == Err InvalidDateFormat
expect parseDateFromStr "2024W018" == Err InvalidDateFormat
expect parseDateFromStr "2024W0a2" == Err InvalidDateFormat

# OrdinalDateExtended
expect parseDateFromStr "2024-023" == (19_723 + 22) * secondsPerDay * nanosPerSecond |> Num.toI128 |> fromNanosSinceEpoch |> Ok
expect parseDateFromStr "1970-001" == 0 |> Num.toI128 |> fromNanosSinceEpoch |> Ok
expect parseDateFromStr "1969-001" == Err InvalidDateFormat
expect parseDateFromStr "2024-000" == Err InvalidDateFormat
expect parseDateFromStr "2024-367" == Err InvalidDateFormat
expect parseDateFromStr "2024-0a3" == Err InvalidDateFormat

# CalendarDateBasic
expect parseDateFromStr "20240123" == (19_723 + 22) * secondsPerDay * nanosPerSecond |> Num.toI128 |> fromNanosSinceEpoch |> Ok
expect parseDateFromStr "19700101" == 0 |> Num.toI128 |> fromNanosSinceEpoch |> Ok
expect parseDateFromStr "19690101" == Err InvalidDateFormat
expect parseDateFromStr "20240100" == Err InvalidDateFormat
expect parseDateFromStr "20240132" == Err InvalidDateFormat
expect parseDateFromStr "20240001" == Err InvalidDateFormat
expect parseDateFromStr "20241301" == Err InvalidDateFormat
expect parseDateFromStr "2024a123" == Err InvalidDateFormat

# WeekDateExtended
expect parseDateFromStr "2024-W04-2" == (19_723 + 22) * secondsPerDay * nanosPerSecond |> Num.toI128 |> fromNanosSinceEpoch |> Ok
expect parseDateFromStr "1970-W01-1" == 0 |> Num.toI128 |> fromNanosSinceEpoch |> Ok
expect parseDateFromStr "1969-W01-1" == Err InvalidDateFormat
expect parseDateFromStr "2024-W53-1" == Err InvalidDateFormat
expect parseDateFromStr "2024-W00-1" == Err InvalidDateFormat
expect parseDateFromStr "2024-W01-0" == Err InvalidDateFormat
expect parseDateFromStr "2024-W01-8" == Err InvalidDateFormat
expect parseDateFromStr "2024-Ww1-1" == Err InvalidDateFormat

# CalendarDateExtended
expect parseDateFromStr "2024-01-23" == (19_723 + 22) * secondsPerDay * nanosPerSecond |> Num.toI128 |> fromNanosSinceEpoch |> Ok
expect parseDateFromStr "1970-01-01" == 0 |> Num.toI128 |> fromNanosSinceEpoch |> Ok
expect parseDateFromStr "1969-01-01" == Err InvalidDateFormat
expect parseDateFromStr "2024-01-00" == Err InvalidDateFormat
expect parseDateFromStr "2024-01-32" == Err InvalidDateFormat
expect parseDateFromStr "2024-00-01" == Err InvalidDateFormat
expect parseDateFromStr "2024-13-01" == Err InvalidDateFormat
expect parseDateFromStr "2024-0a-01" == Err InvalidDateFormat