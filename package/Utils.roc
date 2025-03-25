module [
    nanos_to_frac_str,
    replace_fx_format,
    compare_values,
    expand_int_with_zeros,
    utf8_to_frac,
    utf8_to_int,
    utf8_to_int_signed,
    validate_utf8_single_bytes,
]

import rtils.ListUtils exposing [split_with_delims]
import rtils.StrUtils exposing [pad_left_ascii]
import parse.Parse as P

nanos_to_frac_str : Int _ -> Str
nanos_to_frac_str = |nanos|
    length = count_frac_width(nanos)
    num_str = trim_to_last_sig_fig(nanos) |> Str.drop_prefix("-") |> StrUtils.pad_left_ascii('0', length)
    untrimmed_str = (if nanos == 0 then "" else Str.concat(",", num_str))
    untrimmed_str |> Str.to_utf8 |> List.take_first((length + 1)) |> Str.from_utf8_lossy

trim_to_last_sig_fig : Int _ -> Str
trim_to_last_sig_fig = |num|
    Num.to_str(num) |> drop_trailing_zeros

drop_trailing_zeros : Str -> Str
drop_trailing_zeros = |str|
    str |> Str.to_utf8 |> drop_trailing_zeros_help |> Str.from_utf8_lossy
    
drop_trailing_zeros_help = |bytes|
    when bytes is
        [.. as head, '0'] -> drop_trailing_zeros_help(head)
        _ -> bytes

count_frac_width : Int _ -> Int _
count_frac_width = |num|
    9 - count_frac_width_help(num, 0) 

count_frac_width_help : Int _, Int _ -> Int _
count_frac_width_help = |num, width|
    if num == 0 then
        0
    else if num % 10 == 0 then
        count_frac_width_help((num // 10), (width + 1))
    else
        width

replace_fx_format = |str, nanos|
    frac_fmt = get_frac_format(str)
    if frac_fmt == "" then
        str
    else
        len = parse_frac_fmt(frac_fmt)
        frac_str = Utils.nanos_to_frac_str(nanos) |> Str.drop_prefix(",") |> Str.to_utf8 |> List.take_first(len) |> Str.from_utf8_lossy
        str |> Str.replace_first(frac_fmt, frac_str)

get_frac_format = |str|
    bytes = str |> Str.to_utf8
    (first, last, _) = 
        List.walk_with_index_until(
            bytes,
            (0, 0, Bool.false),
            |(start, end, is_frac), c, i|
                if c == '{' then
                    when (List.get(bytes, i + 1), List.get(bytes, i + 2)) is
                        (Ok('f'), Ok(':')) -> Continue((i, i, Bool.true))
                        _ -> Continue((start, end, is_frac))
                else if c == '}' and is_frac then
                    Break((start, i, is_frac))
                else
                    Continue((start, end, is_frac)),
        )
    if first != last then
        List.sublist(bytes, { start: first, len: last - first + 1 }) |> Str.from_utf8_lossy
    else
        ""
    
parse_frac_fmt : Str -> U64
parse_frac_fmt = |str|
    open_brace = P.char |> P.filter(|c| c == '{')
    close_brace = P.char |> P.filter(|c| c == '}')
    f = P.char |> P.filter(|c| c == 'f')
    colon = P.char |> P.filter(|c| c == ':')
    parser = open_brace |> P.rhs(f) |> P.rhs(colon) |> P.rhs(P.integer) |> P.lhs(close_brace)
    parser(str) |> P.finalize |> Result.with_default 9

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
expect expand_int_with_zeros(1230, 5) == "01230"

compare_values : Num a, Num a -> [LT, EQ, GT]
compare_values = |x, y| if x < y then LT else if x > y then GT else EQ
