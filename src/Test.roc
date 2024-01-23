interface Test
    exposes []
    imports []

expect
    strs = Str.split "YYYYMMDD" ""
    List.len strs == 8