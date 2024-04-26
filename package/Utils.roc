interface Utils
    exposes [
        findDecimalIndex,
        splitListAtIndices,
        splitUtf8AndKeepDelimiters,
        utf8ToFrac,
        utf8ToInt,
        utf8ToIntSigned,
        validateUtf8SingleBytes,
    ]
    imports []

splitListAtIndices : List a, List U8 -> List (List a)
splitListAtIndices = \list, indices ->
    splitListAtIndicesRecur list (List.sortDesc indices)

splitListAtIndicesRecur : List a, List U8 -> List (List a)
splitListAtIndicesRecur = \list, indices ->
    when indices is
        [x, .. as xs] if x != 0 && x != List.len list |> Num.toU8 -> 
            {before, others} = List.split list (Num.toU64 x)
            splitListAtIndicesRecur before xs |> List.append others
        [_, .. as xs] -> 
            splitListAtIndicesRecur list xs
        [] -> [list]

splitUtf8AndKeepDelimiters : List U8, List U8 -> List (List U8)
splitUtf8AndKeepDelimiters = \u8List, delimiters ->
    compareToDelimiters = \byte -> List.contains delimiters byte |> \isFound -> if isFound then Found else NotFound
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
                Ok (num + (Num.toU64 byte - 0x30) * (Num.toU64 (Num.powInt 10 index)))
            else
                Err InvalidBytes

utf8ToIntSigned : List U8 -> Result I64 [InvalidBytes]
utf8ToIntSigned = \u8List ->
    when u8List is
        ['-', .. as xs] -> utf8ToInt xs |> Result.map \num -> -1 * Num.toI64 num
        ['+', .. as xs] -> utf8ToInt xs |> Result.map \num -> Num.toI64 num
        _ -> utf8ToInt u8List |> Result.map \num -> Num.toI64 num

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
                [['.'], tail] -> # if byte == ',' || byte == '.' -> # crashes when using byte comparison
                    fracPart <- utf8ToInt tail |> Result.map
                    decimalShift = List.len tail |> Num.toU8
                    moveDecimalPoint (Num.toF64 fracPart) decimalShift
                [[','], tail] -> # if byte == ',' || byte == '.' -> # crashes when using byte comparison
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
  