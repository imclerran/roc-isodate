module [
    compare_values,
    expand_int_with_zeros,
    utf8_to_frac,
    utf8_to_int,
    utf8_to_int_signed,
    validate_utf8_single_bytes,
]

import rtils.ListUtils exposing [split_with_delims]
import rtils.StrUtils exposing [pad_left_ascii]

validate_utf8_single_bytes : List U8 -> Bool
validate_utf8_single_bytes = |u8_list| List.all(u8_list, |b| b < 128)

utf8_to_int : List U8 -> Result U64 [InvalidBytes]
utf8_to_int = |u8_list|
    u8_list
    |> List.reverse
    |> List.walk_with_index(
        Ok(0),
        |num_result, byte, index|
            Result.try(
                num_result,
                |num|
                    if 0x30 <= byte and byte <= 0x39 then
                        Ok((num + (Num.to_u64(byte) - 0x30) * (Num.to_u64(Num.pow_int(10, index)))))
                    else
                        Err(InvalidBytes),
            ),
    )

utf8_to_int_signed : List U8 -> Result I64 [InvalidBytes]
utf8_to_int_signed = |u8_list|
    when u8_list is
        ['-', .. as xs] -> utf8_to_int(xs) |> Result.map_ok(|num| -1 * Num.to_i64(num))
        ['+', .. as xs] -> utf8_to_int(xs) |> Result.map_ok(|num| Num.to_i64(num))
        _ -> utf8_to_int(u8_list) |> Result.map_ok(|num| Num.to_i64(num))

utf8_to_frac : List U8 -> Result F64 [InvalidBytes]
utf8_to_frac = |u8_list|
    when split_with_delims(u8_list, |b| b == ',' or b == '.') is
        [head, [byte], tail] if byte == ',' or byte == '.' ->
            when (utf8_to_int(head), utf8_to_int(tail)) is
                (Ok(int_part), Ok(frac_part)) ->
                    decimal_shift = List.len(tail) |> Num.to_u8
                    Num.to_f64(int_part) + move_decimal_point(Num.to_f64(frac_part), decimal_shift) |> Ok

                (_, _) -> Err(InvalidBytes)

        [[','], tail] -> # if byte == ',' || byte == '.' -> # crashes when using byte comparison
            frac_part = utf8_to_int(tail)?
            decimal_shift = List.len(tail) |> Num.to_u8
            Ok(move_decimal_point(Num.to_f64(frac_part), decimal_shift))

        [['.'], tail] -> # if byte == ',' || byte == '.' -> # crashes when using byte comparison
            frac_part = utf8_to_int(tail)?
            decimal_shift = List.len(tail) |> Num.to_u8
            Ok(move_decimal_point(Num.to_f64(frac_part), decimal_shift))

        [head, [byte]] if byte == ',' or byte == '.' ->
            int_part = utf8_to_int(head)?
            Ok(Num.to_f64(int_part))

        _ ->
            int_part = utf8_to_int(u8_list)?
            Ok(Num.to_f64(int_part))

move_decimal_point : F64, U8 -> F64
move_decimal_point = |num, digits|
    when digits is
        0 -> num
        _ -> (move_decimal_point(num, (digits - 1))) / 10

expand_int_with_zeros : Int *, U64 -> Str
expand_int_with_zeros = |num, target_length|
    num |> Num.to_str |> pad_left_ascii('0', target_length)

expect expand_int_with_zeros(123, 5) == "00123"

compare_values : Num a, Num a -> [LT, EQ, GT]
compare_values = |x, y| if x < y then LT else if x > y then GT else EQ
