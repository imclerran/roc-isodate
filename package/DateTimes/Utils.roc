interface Utils
    exposes [
        flooredIntegerDivisionAndModulus,
        nDaysInMonthOfYear,
        nDaysInEachMonthOfYear,
        padIntegerToLength,
        subtractWhileGreaterThanZero,
        nDaysInYear,
        unwrap,
        cumulativeSum,
    ]
    imports []

# Functions

## unwrap
unwrap : Result a _, Str -> a
unwrap = \x, message ->
    when x is
        Ok v -> v
        Err _ -> crash message

## cumulativeSum
cumulativeSum : List (Num a) -> List (Num a)
cumulativeSum = \xs ->
    xs
    |> List.walk [0] (\accumulator, x -> accumulator |> List.append ((List.last accumulator |> unwrap "This can never happen because the list always has at least one element") + x))

## Divide the numerator by the denominator, returning the quotient and remainder.
##
## Division is rounded towards zero, so if `flooredIntegerDivisionAndModulus a b == (q, r)`, then `a == b * q + r`.
# flooredIntegerDivisionAndModulus : Num, Num -> (Num, Num)
flooredIntegerDivisionAndModulus = \numerator, denominator ->
    quotient = numerator // denominator
    remainder = numerator - denominator * quotient
    (quotient, remainder)

expect
    out = flooredIntegerDivisionAndModulus 11 5
    out == (2, 1)

expect
    out = flooredIntegerDivisionAndModulus -11 5
    out == (-2, -1)

## padLeft
# padLeft : Str , Str, U8 -> Str
padLeft = \x, padWith, desiredLength ->
    currentLength = Str.countUtf8Bytes x # TODO replace with proper unicode length when available
    if currentLength >= desiredLength then
        x
    else
        extendBy = desiredLength - currentLength
        x |> Str.withPrefix (Str.repeat padWith extendBy)

expect
    out = padLeft "hello" " " 10
    out == "     hello"

## padIntegerToLength
# padIntegerToLength : U8 , U8 -> Str
padIntegerToLength = \x, desiredLength ->
    xStr = Num.toStr x
    padLeft xStr "0" desiredLength

expect
    out = padIntegerToLength 5 2
    out == "05"

expect
    out = padIntegerToLength 123 2
    out == "123"

## divides
# divides : I64 , I64 -> Bool
divides = \a, b -> a % b == 0

expect
    out = divides 10 2
    out == Bool.true

expect
    out = divides 11 2
    out == Bool.false

## isLeapYear
# isLeapYear : I64 -> Bool
isLeapYear = \year -> (divides year 4) && ((Bool.not (divides year 100)) || (divides year 400))

expect
    out = isLeapYear 2001
    out == Bool.false

expect
    out = isLeapYear 2004
    out == Bool.true

expect
    out = isLeapYear 1900
    out == Bool.false

expect
    out = isLeapYear 2000
    out == Bool.true

expect
    out = isLeapYear 0 # 1 BCE
    out == Bool.true

expect
    out = isLeapYear -1 # 2 BCE
    out == Bool.false

expect
    out = isLeapYear -4 # 5 BCE
    out == Bool.true

## nDaysInEachMonthOfYear
nDaysInEachMonthOfYear : I64 -> List U8
nDaysInEachMonthOfYear = \year -> [0, 31, 28 + (if isLeapYear year then 1 else 0), 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]

## nDaysInMonthOfYear
nDaysInMonthOfYear : U8, I64 -> Result U8 [InvalidMonth]
nDaysInMonthOfYear = \month, year ->
    year
    |> nDaysInEachMonthOfYear
    |> List.get (Num.intCast month)
    |> Result.mapErr \_ -> InvalidMonth

expect
    out = nDaysInMonthOfYear 1 1
    out == Ok 31

expect
    out = nDaysInMonthOfYear 2 1
    out == Ok 28

expect
    out = nDaysInMonthOfYear 2 4
    out == Ok 29

expect
    out = nDaysInMonthOfYear 13 1
    out == Err InvalidMonth

## nDaysInYear
# nDaysInYear : I64 -> U16
nDaysInYear = \year -> if isLeapYear year then 366u16 else 365u16

expect
    out = nDaysInYear 2004
    out == 366u16

expect
    out = nDaysInYear 1900
    out == 365u16

expect
    out = nDaysInYear 2000
    out == 366u16

subtractWhileGreaterThanZero : Num a, List (Num a) -> { quotient : Num a, remainder : Num a }
subtractWhileGreaterThanZero = \numerator, list ->
    List.walkUntil
        list
        { quotient: 0, remainder: numerator }
        (
            \{ quotient, remainder }, toSubtract ->
                if remainder >= toSubtract then
                    Continue { quotient: quotient + 1, remainder: remainder - toSubtract }
                else
                    Break { quotient: quotient, remainder: remainder }
        )

expect
    out = subtractWhileGreaterThanZero 3 [1, 1, 1, 1]
    out == { quotient: 3, remainder: 0 }

expect
    out = subtractWhileGreaterThanZero 3 []
    out == { quotient: 0, remainder: 3 }

expect
    out = subtractWhileGreaterThanZero 3 [1, 1, 1]
    out == { quotient: 3, remainder: 0 }

expect
    out = subtractWhileGreaterThanZero 3 [1, 2, 3, 4]
    out == { quotient: 2, remainder: 0 }

expect
    out = subtractWhileGreaterThanZero 4 [1, 2, 3, 4]
    out == { quotient: 2, remainder: 1 }

# ## Convert the number of days into the 400 year cycle to a year and ordinal day of the year.
# dayofYearMod400ToYearMod400AndDayOfYear : U16 -> {yearMod400: U16, dayOfYear: U16}
# dayofYearMod400ToYearMod400AndDayOfYear = \dayOfYearMod400 ->
#     nDaysInEachYearMod400 =
#         List.range { start: At 1i64, end: At 400i64 }
#         |> List.map Utils.nDaysInYear
#     ( yearMod400, dayOfYear ) = subtractWhileGreaterThanZero dayOfYearMod400 nDaysInEachYearMod400
#     { yearMod400: yearMod400 + 1, dayOfYear: dayOfYear + 1 }

# cycleToYo = \cycle ->
#     Pair yearMod400 ordinal0 = flooredIntegerDivisionAndModulus cycle 365
#     delta  = List.get Constants.yearDeltas yearMod400 |> Result.withDefault -1
#     Pair yearMod400 ordinal0 = if ordinal0 < delta then
#         newYearMod400 = yearMod400 - 1
#         newOrdinal0 = ordinal0 +  365 - (List.get Constants.yearDeltas newYearMod400 |> Result.withDefault -1)
#         Pair newYearMod400 newOrdinal0
#     else
#         Pair yearMod400 (ordinal0 - delta)
#     Pair yearMod400 (ordinal0+1)

# fn cycle_to_yo(cycle: u32) -> (u32, u32) {
#     let (mut year_mod_400, mut ordinal0) = div_rem(cycle, 365);
#     let delta = u32::from(YEAR_DELTAS[year_mod_400 as usize]);
#     if ordinal0 < delta {
#         year_mod_400 -= 1;
#         ordinal0 += 365 - u32::from(YEAR_DELTAS[year_mod_400 as usize]);
#     } else {
#         ordinal0 -= delta;
#     }
#     (year_mod_400, ordinal0 + 1)
# }
