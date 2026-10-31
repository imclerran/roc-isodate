ContextualDuration := { years : I64, months : I8, days : I16, hours : I8, minutes : I8, seconds : I8, nanoseconds : I32 }.{
	from_ymd : I64, I8, I16 -> ContextualDuration
	from_ymd = |y, m, d| { years: y, months: m, days: d, hours: 0, minutes: 0, seconds: 0, nanoseconds: 0 }

	from_hms : I8, I8, I8 -> ContextualDuration
	from_hms = |h, m, s| { years: 0, months: 0, days: 0, hours: h, minutes: m, seconds: s, nanoseconds: 0 }

	from_hmsn : I8, I8, I8, I32 -> ContextualDuration
	from_hmsn = |h, m, s, n| { years: 0, months: 0, days: 0, hours: h, minutes: m, seconds: s, nanoseconds: n }

	from_ymd_hms : I64, I8, I16, I8, I8, I8 -> ContextualDuration
	from_ymd_hms = |y, m, d, h, mi, s| { years: y, months: m, days: d, hours: h, minutes: mi, seconds: s, nanoseconds: 0 }

	from_ymd_hmsn : I64, I8, I16, I8, I8, I8, I32 -> ContextualDuration
	from_ymd_hmsn = |y, m, d, h, mi, s, n| { years: y, months: m, days: d, hours: h, minutes: mi, seconds: s, nanoseconds: n }
}
