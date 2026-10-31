Utils :: {}.{
	nanos_to_frac_str : I32 -> Str
	nanos_to_frac_str = |nanos| {
		length = count_frac_width(nanos)
		num_str = trim_to_last_sig_fig(nanos).drop_prefix("-") |> pad_left_ascii('0', length)
		untrimmed_str = if nanos == 0 {
			""
		} else {
			Str.concat(",", num_str)
		}
		untrimmed_str.to_utf8().take_first(length + 1) |> Str.from_utf8_lossy
	}

	replace_fx_format : Str, I32 -> Str
	replace_fx_format = |str, nanos| {
		frac_fmt = get_frac_format(str)
		if frac_fmt == "" {
			str
		} else {
			len = parse_frac_fmt(frac_fmt)
			frac_str = nanos_to_frac_str(nanos).drop_prefix(",").to_utf8().take_first(len) |> Str.from_utf8_lossy
			str |> replace_first(frac_fmt, frac_str)
		}
	}

	validate_utf8_single_bytes : List(U8) -> Bool
	validate_utf8_single_bytes = |u8_list| u8_list.all(|b| b < 128)

	utf8_to_int : List(U8) -> Try(U64, [InvalidBytes])
	utf8_to_int = |u8_list| {
		u8_list
			.rev()
			.fold_with_index(
				Ok(0),
				|num_result, byte, index| {
					num = num_result?
					if 0x30 <= byte and byte <= 0x39 {
						Ok(num + (byte.to_u64() - 0x30) * (10 |> pow_int(index)))
					} else {
						Err(InvalidBytes)
					}
				},
			)
	}

	utf8_to_int_signed : List(U8) -> Try(I64, [InvalidBytes])
	utf8_to_int_signed = |u8_list| {
		match u8_list {
			['-', .. as xs] => {
				num = utf8_to_int(xs)?
				Ok(-1 * num.to_i64_wrap())
			}
			['+', .. as xs] => {
				num = utf8_to_int(xs)?
				Ok(num.to_i64_wrap())
			}
			_ => {
				num = utf8_to_int(u8_list)?
				Ok(num.to_i64_wrap())
			}
		}
	}

	utf8_to_frac : List(U8) -> Try(F64, [InvalidBytes])
	utf8_to_frac = |u8_list| {
		match split_with_delims(u8_list, |b| b == ',' or b == '.') {
			[head, [byte], tail] if byte == ',' or byte == '.' => {
				int_part = utf8_to_int(head)?
				frac_part = utf8_to_int(tail)?
				decimal_shift = tail.len().to_u8_wrap()
				Ok(int_part.to_f64() + move_decimal_point(frac_part.to_f64(), decimal_shift))
			}

			[[','], tail] => { # if byte == ',' || byte == '.' -> # crashes when using byte comparison (TODO: check this is still true)
				frac_part = utf8_to_int(tail)?
				decimal_shift = tail.len().to_u8_wrap()
				Ok(move_decimal_point(frac_part.to_f64(), decimal_shift))
			}

			[['.'], tail] => { # if byte == ',' || byte == '.' -> # crashes when using byte comparison (TODO: check this is still true)
				frac_part = utf8_to_int(tail)?
				decimal_shift = tail.len().to_u8_wrap()
				Ok(move_decimal_point(frac_part.to_f64(), decimal_shift))
			}

			[head, [byte]] if byte == ',' or byte == '.' => {
				int_part = utf8_to_int(head)?
				Ok(int_part.to_f64())
			}

			_ => {
				int_part = utf8_to_int(u8_list)?
				Ok(int_part.to_f64())
			}
		}
	}

	expand_int_with_zeros : I64, U64 -> Str
	expand_int_with_zeros = |num, target_length| {
		num.to_str() |> pad_left_ascii('0', target_length)
	}

	split_at_indices = |list, indices| {
		help = |output, remaining_items, remaining_indices, current_index| {
			match remaining_indices {
				[] => output.append(remaining_items)
				[index, .. as other_indices] => {
					split_index = if index >= current_index {
						index - current_index
					} else {
						0
					}
					{ before, others } = remaining_items.split_at(split_index)
					help(output.append(before), others, other_indices, index)
				}
			}
		}
		help([], list, indices.sort_with(|a, b| a.order_relative_to(b)), 0)
	}

	split_with_delims = |list, is_delim| {
		split_with_delims_help(list, is_delim, [], [])
	}
}

split_with_delims_help = |list, check_delim, acc, curr| {
	match list {
		[] => {
			if curr.len() == 0 {
				acc
			} else {
				acc.concat([curr])
			}
		}
		[x, .. as xs] => {
			if check_delim(x) {
				new_acc =
					if curr.len() == 0 {
						acc.concat([[x]])
					} else {
						acc.concat([curr, [x]])
					}
				split_with_delims_help(xs, check_delim, new_acc, [])
			} else {
				split_with_delims_help(xs, check_delim, acc, curr.append(x))
			}
		}
	}
}

pad_left_ascii : Str, U8, U64 -> Str
pad_left_ascii = |str, char, target_length| {
	str_len = str.to_utf8().len()
	if str_len >= target_length {
		str
	} else {
		pad_len = target_length - str_len
		padding = List.repeat(char, pad_len)
		padding_str = padding |> Str.from_utf8_lossy
		padding_str.concat(str)
	}
}

trim_to_last_sig_fig : I32 -> Str
trim_to_last_sig_fig = |num| {
	num.to_str() |> drop_trailing_zeros
}

drop_trailing_zeros : Str -> Str
drop_trailing_zeros = |str| {
	str.to_utf8() |> drop_trailing_zeros_help |> Str.from_utf8_lossy
}

drop_trailing_zeros_help : List(U8) -> List(U8)
drop_trailing_zeros_help = |bytes| {
	match bytes {
		[.. as head, '0'] => drop_trailing_zeros_help(head)
		_ => bytes
	}
}

count_frac_width = |num| {
	9 - count_frac_width_help(num, 0)
}

count_frac_width_help = |num, width| {
	if num == 0 {
		0
	} else if num % 10 == 0 {
		count_frac_width_help((num // 10), (width + 1))
	} else {
		width
	}
}

get_frac_format : Str -> Str
get_frac_format = |str| {
	bytes = str.to_utf8()
	(first, last, _) =
		bytes.fold_with_index_until(
			(0, 0, Bool.False),
			|(start, end, is_frac), c, i| {
				if c == '{' {
					match (bytes.get(i + 1), bytes.get(i + 2)) {
						(Ok('f'), Ok(':')) => Continue((i, i, Bool.True))
						_ => Continue((start, end, is_frac))
					}
				} else if c == '}' and is_frac {
					Break((start, i, is_frac))
				} else {
					Continue((start, end, is_frac))
				}
			},
		)
	if first != last {
		bytes.sublist({ start: first, len: last - first + 1 }) |> Str.from_utf8_lossy
	} else {
		""
	}
}

parse_frac_fmt : Str -> U64
parse_frac_fmt = |fmt| {
	fmt.drop_prefix("{f:").drop_suffix("}") |> U64.from_str ?? 9
}

move_decimal_point : F64, U8 -> F64
move_decimal_point = |num, digits| {
	match digits {
		0 => num
		_ => (move_decimal_point(num, digits - 1)) / 10
	}
}

pow_int = |base, exp| {
	pow_int_help(base, exp, 1)
}

pow_int_help = |base, exp, acc| {
	match exp {
		0 => acc
		_ => pow_int_help(base, exp - 1, acc * base)
	}
}

replace_first = |str, from, to| {
	match str.split_on(from) {
		[] => str
		[_] => str
		[first, .. as rest] => {
			after = rest |> Str.join_with(from)
			[first, after] |> Str.join_with(to)
		}
	}
}

# nanos_to_frac_str
expect Utils.nanos_to_frac_str(123000000) == ",123"
expect Utils.nanos_to_frac_str(0) == ""
expect Utils.nanos_to_frac_str(500_000_000) == ",5"
expect Utils.nanos_to_frac_str(999_999_999) == ",999999999"

# replace_fx_format
expect Utils.replace_fx_format("{f:3}", 123456789) == "123"
expect Utils.replace_fx_format("no format", 123) == "no format"
expect Utils.replace_fx_format("{f:1}", 500_000_000) == "5"

# validate_utf8_single_bytes
expect Utils.validate_utf8_single_bytes(['a', 'b', 'c']) == Bool.True
expect Utils.validate_utf8_single_bytes([]) == Bool.True
expect Utils.validate_utf8_single_bytes([128]) == Bool.False

# utf8_to_int
expect Utils.utf8_to_int(['1', '2', '3']) == Ok(123)
expect Utils.utf8_to_int([]) == Ok(0)
expect Utils.utf8_to_int(['0']) == Ok(0)
expect Utils.utf8_to_int(['1', 'a']) == Err(InvalidBytes)

# utf8_to_int_signed
expect Utils.utf8_to_int_signed(['-', '1', '2', '3']) == Ok(-123)
expect Utils.utf8_to_int_signed(['+', '1', '2', '3']) == Ok(123)
expect Utils.utf8_to_int_signed(['1', '2', '3']) == Ok(123)
expect Utils.utf8_to_int_signed(['-', 'x']) == Err(InvalidBytes)

# utf8_to_frac
expect Utils.utf8_to_frac(['0', '.', '5']) == Ok(0.5)
expect Utils.utf8_to_frac(['0', ',', '5']) == Ok(0.5)
expect Utils.utf8_to_frac(['1', '2']) == Ok(12.0)
expect Utils.utf8_to_frac(['x']) == Err(InvalidBytes)

# expand_int_with_zeros
expect Utils.expand_int_with_zeros(123, 5) == "00123"
expect Utils.expand_int_with_zeros(12345, 5) == "12345"
expect Utils.expand_int_with_zeros(0, 3) == "000"

# split_at_indices
expect Utils.split_at_indices(['a', 'b', 'c', 'd'], [1, 3]) == [['a'], ['b', 'c'], ['d']]
expect Utils.split_at_indices(['a', 'b', 'c'], []) == [['a', 'b', 'c']]
expect Utils.split_at_indices(['a', 'b', 'c', 'd'], [3, 1]) == [['a'], ['b', 'c'], ['d']]

# split_with_delims
expect Utils.split_with_delims(['a', ',', 'b'], |b| b == ',') == [['a'], [','], ['b']]
expect Utils.split_with_delims(['a', 'b'], |b| b == ',') == [['a', 'b']]
expect Utils.split_with_delims([',', 'a'], |b| b == ',') == [[','], ['a']]
expect Utils.split_with_delims(['a', ','], |b| b == ',') == [['a'], [',']]

# split_with_delims_help
expect split_with_delims_help(['a', ',', 'b'], |b| b == ',', [], []) == [['a'], [','], ['b']]
expect split_with_delims_help([], |b| b == ',', [], []) == []
expect split_with_delims_help([], |b| b == ',', [], ['a']) == [['a']]

# pad_left_ascii
expect pad_left_ascii("123", '0', 5) == "00123"
expect pad_left_ascii("12345", '0', 3) == "12345"
expect pad_left_ascii("", '0', 3) == "000"

# trim_to_last_sig_fig
expect trim_to_last_sig_fig(12300) == "123"
expect trim_to_last_sig_fig(0) == ""
expect trim_to_last_sig_fig(-12300) == "-123"
expect trim_to_last_sig_fig(123) == "123"

# drop_trailing_zeros
expect drop_trailing_zeros("12300") == "123"
expect drop_trailing_zeros("123") == "123"
expect drop_trailing_zeros("000") == ""

# drop_trailing_zeros_help
expect drop_trailing_zeros_help(['1', '2', '0', '0']) == ['1', '2']
expect drop_trailing_zeros_help(['1', '2']) == ['1', '2']
expect drop_trailing_zeros_help([]) == []

# count_frac_width
expect count_frac_width(123000000) == 3
expect count_frac_width(0) == 9
expect count_frac_width(123456789) == 9

# count_frac_width_help
expect count_frac_width_help(100, 0) == 2
expect count_frac_width_help(0, 0) == 0
expect count_frac_width_help(123, 0) == 0

# get_frac_format
expect get_frac_format("abc{f:3}def") == "{f:3}"
expect get_frac_format("no format") == ""
expect get_frac_format("abc{f}def") == ""

# parse_frac_fmt
expect parse_frac_fmt("{f:3}") == 3
expect parse_frac_fmt("{f:9}") == 9
expect parse_frac_fmt("{f}") == 9

# move_decimal_point
expect move_decimal_point(500.0, 2) == 5.0
expect move_decimal_point(500.0, 0) == 500.0
expect move_decimal_point(5.0, 1) == 0.5

# pow_int
expect pow_int(10, 3) == 1000
expect pow_int(10, 0) == 1
expect pow_int(2, 4) == 16

# pow_int_help
expect pow_int_help(10, 3, 1) == 1000
expect pow_int_help(10, 0, 1) == 1

# replace_first
expect replace_first("hello world", "world", "roc") == "hello roc"
expect replace_first("hello world", "foo", "bar") == "hello world"
expect replace_first("", "foo", "bar") == ""
