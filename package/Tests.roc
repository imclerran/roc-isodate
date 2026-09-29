Tests :: {}.{}

import Const
import Date
import DateTime
import Time
import Utils

# <==== Date.roc ====>
# <---- parseDate ---->
# parseCalendarDateCentury
# 1
expect Date.from_iso_str("20") == Ok(Date.from_ymd(2000, 1, 1))
expect Date.from_iso_str("20")? |> Date.to_nanos_since_epoch == 10_957.I128 * Const.seconds_per_day.to_i128() * Const.nanos_per_second.to_i128()
# 2
expect Date.from_iso_str("19") == Ok(Date.from_ymd(1900, 1, 1))
expect Date.from_iso_str("19")? |> Date.to_nanos_since_epoch == (-25_567.I128) * Const.seconds_per_day.to_i128() * Const.nanos_per_second.to_i128()
# 3
expect Date.from_iso_str("ab") == Err(InvalidDateFormat)

# parseCalendarDateYear
# 4
expect Date.from_iso_str("2024") == Ok(Date.from_ymd(2024, 1, 1))
expect Date.from_iso_str("2024")? |> Date.to_nanos_since_epoch == 19_723.I128 * Const.seconds_per_day.to_i128() * Const.nanos_per_second.to_i128()
# 5
expect Date.from_iso_str("1970") == Ok(Date.from_ymd(1970, 1, 1))
expect Date.from_iso_str("1970")? |> Date.to_nanos_since_epoch == 0.I128
# 6
expect Date.from_iso_str("1968") == Ok(Date.from_ymd(1968, 1, 1))
expect Date.from_iso_str("1968")? |> Date.to_nanos_since_epoch == (-731.I128) * Const.seconds_per_day.to_i128() * Const.nanos_per_second.to_i128()
# 7
expect Date.from_iso_str("202f") == Err(InvalidDateFormat)

# parseWeekDateReducedBasic
# 8
expect Date.from_iso_str("2024W04") == Ok(Date.from_ymd(2024, 1, 22))
expect Date.from_iso_str("2024W04")? |> Date.to_nanos_since_epoch == (19_723.I128 + 21) * Const.seconds_per_day.to_i128() * Const.nanos_per_second.to_i128()
# 9
expect Date.from_iso_str("1970W01") == Ok(Date.from_ymd(1970, 1, 1))
expect Date.from_iso_str("1970W01")? |> Date.to_nanos_since_epoch == 0.I128
# 10
expect Date.from_iso_str("1968W01") == Ok(Date.from_ymd(1968, 1, 1))
expect Date.from_iso_str("1968W01")? |> Date.to_nanos_since_epoch == (-731.I128) * Const.seconds_per_day.to_i128() * Const.nanos_per_second.to_i128()
# 11
expect Date.from_iso_str("2024W53") == Err(InvalidDateFormat)
# 12
expect Date.from_iso_str("2024W00") == Err(InvalidDateFormat)
# 13
expect Date.from_iso_str("2024Www") == Err(InvalidDateFormat)

# parseCalendarDateMonth
# 14
expect Date.from_iso_str("2024-02") == Ok(Date.from_ymd(2024, 2, 1))
expect Date.from_iso_str("2024-02")? |> Date.to_nanos_since_epoch == (19_723.I128 + 31) * Const.seconds_per_day.to_i128() * Const.nanos_per_second.to_i128()
# 15
expect Date.from_iso_str("1970-01") == Ok(Date.from_ymd(1970, 1, 1))
expect Date.from_iso_str("1970-01")? |> Date.to_nanos_since_epoch == 0.I128
# 16
expect Date.from_iso_str("1968-01") == Ok(Date.from_ymd(1968, 1, 1))
expect Date.from_iso_str("1968-01")? |> Date.to_nanos_since_epoch == (-731.I128) * Const.seconds_per_day.to_i128() * Const.nanos_per_second.to_i128()
# 17
expect Date.from_iso_str("2024-13") == Err(InvalidDateFormat)
# 18
expect Date.from_iso_str("2024-00") == Err(InvalidDateFormat)
# 19
expect Date.from_iso_str("2024-0a") == Err(InvalidDateFormat)

# parseOrdinalDateBasic
# 20
expect Date.from_iso_str("2024023") == Ok(Date.from_ymd(2024, 1, 23))
expect Date.from_iso_str("2024023")? |> Date.to_nanos_since_epoch == (19_723.I128 + 22) * Const.seconds_per_day.to_i128() * Const.nanos_per_second.to_i128()
# 21
expect Date.from_iso_str("1970001") == Ok(Date.from_ymd(1970, 1, 1))
expect Date.from_iso_str("1970001")? |> Date.to_nanos_since_epoch == 0.I128
# 22
expect Date.from_iso_str("1968001") == Ok(Date.from_ymd(1968, 1, 1))
expect Date.from_iso_str("1968001")? |> Date.to_nanos_since_epoch == (-731.I128) * Const.seconds_per_day.to_i128() * Const.nanos_per_second.to_i128()
# 23
expect Date.from_iso_str("2024000") == Err(InvalidDateFormat)
# 24
expect Date.from_iso_str("2024367") == Err(InvalidDateFormat)
# 25
expect Date.from_iso_str("2024a23") == Err(InvalidDateFormat)

# parseWeekDateReducedExtended
# 26
expect Date.from_iso_str("2024-W04") == Ok(Date.from_ymd(2024, 1, 22))
expect Date.from_iso_str("2024-W04")? |> Date.to_nanos_since_epoch == (19_723.I128 + 21) * Const.seconds_per_day.to_i128() * Const.nanos_per_second.to_i128()
# 27
expect Date.from_iso_str("1970-W01") == Ok(Date.from_ymd(1970, 1, 1))
expect Date.from_iso_str("1970-W01")? |> Date.to_nanos_since_epoch == 0.I128
# 28
expect Date.from_iso_str("1968-W01") == Ok(Date.from_ymd(1968, 1, 1))
expect Date.from_iso_str("1968-W01")? |> Date.to_nanos_since_epoch == (-731.I128) * Const.seconds_per_day.to_i128() * Const.nanos_per_second.to_i128()
# 29
expect Date.from_iso_str("2024-W53") == Err(InvalidDateFormat)
# 30
expect Date.from_iso_str("2024-W00") == Err(InvalidDateFormat)
# 31
expect Date.from_iso_str("2024-Ww1") == Err(InvalidDateFormat)

# parseWeekDateBasic
# 32
expect Date.from_iso_str("2024W042") == Ok(Date.from_ymd(2024, 1, 23))
expect Date.from_iso_str("2024W042")? |> Date.to_nanos_since_epoch == (19_723.I128 + 22) * Const.seconds_per_day.to_i128() * Const.nanos_per_second.to_i128()
# 33
expect Date.from_iso_str("1970W011") == Ok(Date.from_ymd(1970, 1, 1))
expect Date.from_iso_str("1970W011")? |> Date.to_nanos_since_epoch == 0.I128
# 34
expect Date.from_iso_str("1970W524") == Ok(Date.from_ymd(1970, 12, 31))
expect Date.from_iso_str("1970W524")? |> Date.to_nanos_since_epoch == 364.I128 * Const.seconds_per_day.to_i128() * Const.nanos_per_second.to_i128()
# 35
expect Date.from_iso_str("1970W525") == Ok(Date.from_ymd(1971, 1, 1))
expect Date.from_iso_str("1970W525")? |> Date.to_nanos_since_epoch == 365.I128 * Const.seconds_per_day.to_i128() * Const.nanos_per_second.to_i128()
# 36
expect Date.from_iso_str("1968W011") == Ok(Date.from_ymd(1968, 1, 1))
expect Date.from_iso_str("1968W011")? |> Date.to_nanos_since_epoch == (-731.I128) * Const.seconds_per_day.to_i128() * Const.nanos_per_second.to_i128()
# 37
expect Date.from_iso_str("2024W001") == Err(InvalidDateFormat)
# 38
expect Date.from_iso_str("2024W531") == Err(InvalidDateFormat)
# 39
expect Date.from_iso_str("2024W010") == Err(InvalidDateFormat)
# 40
expect Date.from_iso_str("2024W018") == Err(InvalidDateFormat)
# 41
expect Date.from_iso_str("2024W0a2") == Err(InvalidDateFormat)

# parseOrdinalDateExtended
# 42
expect Date.from_iso_str("2024-023") == Ok(Date.from_ymd(2024, 1, 23))
expect Date.from_iso_str("2024-023")? |> Date.to_nanos_since_epoch == (19_723.I128 + 22) * Const.seconds_per_day.to_i128() * Const.nanos_per_second.to_i128()
# 43
expect Date.from_iso_str("1970-001") == Ok(Date.from_ymd(1970, 1, 1))
expect Date.from_iso_str("1970-001")? |> Date.to_nanos_since_epoch == 0.I128
# 44
expect Date.from_iso_str("1968-001") == Ok(Date.from_ymd(1968, 1, 1))
expect Date.from_iso_str("1968-001")? |> Date.to_nanos_since_epoch == (-731.I128) * Const.seconds_per_day.to_i128() * Const.nanos_per_second.to_i128()
# 45
expect Date.from_iso_str("2024-000") == Err(InvalidDateFormat)
# 46
expect Date.from_iso_str("2024-367") == Err(InvalidDateFormat)
# 47
expect Date.from_iso_str("2024-0a3") == Err(InvalidDateFormat)

# parseCalendarDateBasic
# 48
expect Date.from_iso_str("20240123") == Ok(Date.from_ymd(2024, 1, 23))
expect Date.from_iso_str("20240123")? |> Date.to_nanos_since_epoch == (19_723.I128 + 22) * Const.seconds_per_day.to_i128() * Const.nanos_per_second.to_i128()
# 49
expect Date.from_iso_str("19700101") == Ok(Date.from_ymd(1970, 1, 1))
expect Date.from_iso_str("19700101")? |> Date.to_nanos_since_epoch == 0.I128
# 50
expect Date.from_iso_str("19680101") == Ok(Date.from_ymd(1968, 1, 1))
expect Date.from_iso_str("19680101")? |> Date.to_nanos_since_epoch == (-731.I128) * Const.seconds_per_day.to_i128() * Const.nanos_per_second.to_i128()
# 51
expect Date.from_iso_str("20240100") == Err(InvalidDateFormat)
# 52
expect Date.from_iso_str("20240132") == Err(InvalidDateFormat)
# 53
expect Date.from_iso_str("20240001") == Err(InvalidDateFormat)
# 54
expect Date.from_iso_str("20241301") == Err(InvalidDateFormat)
# 55
expect Date.from_iso_str("2024a123") == Err(InvalidDateFormat)

# parseWeekDateExtended
# 56
expect Date.from_iso_str("2024-W04-2") == Ok(Date.from_ymd(2024, 1, 23))
expect Date.from_iso_str("2024-W04-2")? |> Date.to_nanos_since_epoch == (19_723.I128 + 22) * Const.seconds_per_day.to_i128() * Const.nanos_per_second.to_i128()
# 57
expect Date.from_iso_str("1970-W01-1") == Ok(Date.from_ymd(1970, 1, 1))
expect Date.from_iso_str("1970-W01-1")? |> Date.to_nanos_since_epoch == 0.I128
# 58
expect Date.from_iso_str("1968-W01-1") == Ok(Date.from_ymd(1968, 1, 1))
expect Date.from_iso_str("1968-W01-1")? |> Date.to_nanos_since_epoch == (-731.I128) * Const.seconds_per_day.to_i128() * Const.nanos_per_second.to_i128()
# 59
expect Date.from_iso_str("2024-W53-1") == Err(InvalidDateFormat)
# 60
expect Date.from_iso_str("2024-W00-1") == Err(InvalidDateFormat)
# 61
expect Date.from_iso_str("2024-W01-0") == Err(InvalidDateFormat)
# 62
expect Date.from_iso_str("2024-W01-8") == Err(InvalidDateFormat)
# 63
expect Date.from_iso_str("2024-Ww1-1") == Err(InvalidDateFormat)

# parseCalendarDateExtended
# 64
expect Date.from_iso_str("2024-01-23") == Ok(Date.from_ymd(2024, 1, 23))
expect Date.from_iso_str("2024-01-23")? |> Date.to_nanos_since_epoch == (19_723.I128 + 22) * Const.seconds_per_day.to_i128() * Const.nanos_per_second.to_i128()
# 65
expect Date.from_iso_str("1970-01-01") == Ok(Date.from_ymd(1970, 1, 1))
expect Date.from_iso_str("1970-01-01")? |> Date.to_nanos_since_epoch == 0.I128
# 66
expect Date.from_iso_str("1968-01-01") == Ok(Date.from_ymd(1968, 1, 1))
expect Date.from_iso_str("1968-01-01")? |> Date.to_nanos_since_epoch == (-731.I128) * Const.seconds_per_day.to_i128() * Const.nanos_per_second.to_i128()
# 71
expect Date.from_iso_str("2024-01-00") == Err(InvalidDateFormat)
# 68
expect Date.from_iso_str("2024-01-32") == Err(InvalidDateFormat)
# 69
expect Date.from_iso_str("2024-00-01") == Err(InvalidDateFormat)
# 70
expect Date.from_iso_str("2024-13-01") == Err(InvalidDateFormat)
# 71
expect Date.from_iso_str("2024-0a-01") == Err(InvalidDateFormat)

# <==== Time.roc ====>
# <---- parseTime ---->
# parseLocalTimeHour
# 72
expect Time.from_iso_str("11") == Ok(Time.from_hms(11, 0, 0))
expect Time.from_iso_str("11")? |> Time.to_nanos_since_midnight == 11 * Const.nanos_per_hour
# 73
expect Time.from_iso_str("00Z") == Ok(Time.from_hms(0, 0, 0))
expect Time.from_iso_str("00Z")? |> Time.to_nanos_since_midnight == 0
# 74
expect Time.from_iso_str("T00") == Ok(Time.from_hms(0, 0, 0))
expect Time.from_iso_str("T00")? |> Time.to_nanos_since_midnight == 0
# 75
expect Time.from_iso_str("T00Z") == Ok(Time.from_hms(0, 0, 0))
expect Time.from_iso_str("T00Z")? |> Time.to_nanos_since_midnight == 0
# 76
expect Time.from_iso_str("T23") == Ok(Time.from_hms(23, 0, 0))
expect Time.from_iso_str("T23")? |> Time.to_nanos_since_midnight == 23 * Const.nanos_per_hour
# 77
expect Time.from_iso_str("T24") == Ok(Time.from_hms(24, 0, 0))
expect Time.from_iso_str("T24")? |> Time.to_nanos_since_midnight == 24 * Const.nanos_per_hour
# 78
expect Time.from_iso_str("T25") == Err(InvalidTimeFormat)
# 79
expect Time.from_iso_str("T0Z") == Err(InvalidTimeFormat)

# parseLocalTimeMinuteBasic
# 80
expect Time.from_iso_str("1111") == Ok(Time.from_hms(11, 11, 0))
expect Time.from_iso_str("1111")? |> Time.to_nanos_since_midnight == 11 * Const.nanos_per_hour + 11 * Const.nanos_per_minute
# 81
expect Time.from_iso_str("0000Z") == Ok(Time.from_hms(0, 0, 0))
expect Time.from_iso_str("0000Z")? |> Time.to_nanos_since_midnight == 0
# 82
expect Time.from_iso_str("T0000") == Ok(Time.from_hms(0, 0, 0))
expect Time.from_iso_str("T0000")? |> Time.to_nanos_since_midnight == 0
# 83
expect Time.from_iso_str("T0000Z") == Ok(Time.from_hms(0, 0, 0))
expect Time.from_iso_str("T0000Z")? |> Time.to_nanos_since_midnight == 0
# 84
expect Time.from_iso_str("T2359") == Ok(Time.from_hms(23, 59, 0))
expect Time.from_iso_str("T2359")? |> Time.to_nanos_since_midnight == 23 * Const.nanos_per_hour + 59 * Const.nanos_per_minute
# 85
expect Time.from_iso_str("T2400") == Ok(Time.from_hms(24, 0, 0))
expect Time.from_iso_str("T2400")? |> Time.to_nanos_since_midnight == 24 * Const.nanos_per_hour
# 86
expect Time.from_iso_str("T2401") == Err(InvalidTimeFormat)
# 87
expect Time.from_iso_str("T000Z") == Err(InvalidTimeFormat)

# parseLocalTimeMinuteExtended
# 88
expect Time.from_iso_str("11:11") == Ok(Time.from_hms(11, 11, 0))
expect Time.from_iso_str("11:11")? |> Time.to_nanos_since_midnight == 11 * Const.nanos_per_hour + 11 * Const.nanos_per_minute
# 89
expect Time.from_iso_str("00:00Z") == Ok(Time.midnight)
expect Time.from_iso_str("00:00Z")? |> Time.to_nanos_since_midnight == 0
# 90
expect Time.from_iso_str("T00:00") == Ok(Time.midnight)
expect Time.from_iso_str("T00:00")? |> Time.to_nanos_since_midnight == 0
# 91
expect Time.from_iso_str("T00:00Z") == Ok(Time.midnight)
expect Time.from_iso_str("T00:00Z")? |> Time.to_nanos_since_midnight == 0
# 92
expect Time.from_iso_str("T23:59") == Ok(Time.from_hms(23, 59, 0))
expect Time.from_iso_str("T23:59")? |> Time.to_nanos_since_midnight == 23 * Const.nanos_per_hour + 59 * Const.nanos_per_minute
# 93
expect Time.from_iso_str("T24:00") == Ok(Time.from_hms(24, 0, 0))
expect Time.from_iso_str("T24:00")? |> Time.to_nanos_since_midnight == 24 * Const.nanos_per_hour
# 94
expect Time.from_iso_str("T24:01") == Err(InvalidTimeFormat)
# 95
expect Time.from_iso_str("T00:0Z") == Err(InvalidTimeFormat)

# parseLocalTimeBasic
# 96
expect Time.from_iso_str("111111") == Ok(Time.from_hms(11, 11, 11))
expect Time.from_iso_str("111111")? |> Time.to_nanos_since_midnight == 11 * Const.nanos_per_hour + 11 * Const.nanos_per_minute + 11 * Const.nanos_per_second
# 97
expect Time.from_iso_str("000000Z") == Ok(Time.midnight)
expect Time.from_iso_str("000000Z")? |> Time.to_nanos_since_midnight == 0
# 98
expect Time.from_iso_str("T000000") == Ok(Time.midnight)
expect Time.from_iso_str("T000000")? |> Time.to_nanos_since_midnight == 0
# 99
expect Time.from_iso_str("T000000Z") == Ok(Time.midnight)
expect Time.from_iso_str("T000000Z")? |> Time.to_nanos_since_midnight == 0
# 100
expect Time.from_iso_str("T235959") == Ok(Time.from_hms(23, 59, 59))
expect Time.from_iso_str("T235959")? |> Time.to_nanos_since_midnight == 23 * Const.nanos_per_hour + 59 * Const.nanos_per_minute + 59 * Const.nanos_per_second
# 101
expect Time.from_iso_str("T240000") == Ok(Time.from_hms(24, 0, 0))
expect Time.from_iso_str("T240000")? |> Time.to_nanos_since_midnight == 24 * Const.nanos_per_hour
# 102
expect Time.from_iso_str("T240001") == Err(InvalidTimeFormat)
# 103
expect Time.from_iso_str("T00000Z") == Err(InvalidTimeFormat)

# parseLocalTimeExtended
# 104
expect Time.from_iso_str("11:11:11") == Ok(Time.from_hms(11, 11, 11))
expect Time.from_iso_str("11:11:11")? |> Time.to_nanos_since_midnight == 11 * Const.nanos_per_hour + 11 * Const.nanos_per_minute + 11 * Const.nanos_per_second
# 105
expect Time.from_iso_str("00:00:00Z") == Ok(Time.midnight)
expect Time.from_iso_str("00:00:00Z")? |> Time.to_nanos_since_midnight == 0
# 106
expect Time.from_iso_str("T00:00:00") == Ok(Time.midnight)
expect Time.from_iso_str("T00:00:00")? |> Time.to_nanos_since_midnight == 0
# 107
expect Time.from_iso_str("T00:00:00Z") == Ok(Time.midnight)
expect Time.from_iso_str("T00:00:00Z")? |> Time.to_nanos_since_midnight == 0
# 108
expect Time.from_iso_str("T23:59:59") == Ok(Time.from_hms(23, 59, 59))
expect Time.from_iso_str("T23:59:59")? |> Time.to_nanos_since_midnight == 23 * Const.nanos_per_hour + 59 * Const.nanos_per_minute + 59 * Const.nanos_per_second
# 109
expect Time.from_iso_str("T24:00:00") == Ok(Time.from_hms(24, 0, 0))
expect Time.from_iso_str("T24:00:00")? |> Time.to_nanos_since_midnight == 24 * Const.nanos_per_hour
# 110
expect Time.from_iso_str("T24:00:01") == Err(InvalidTimeFormat)
# 111
expect Time.from_iso_str("T00:00:0Z") == Err(InvalidTimeFormat)

# parseFractionalTime
# 112
expect Time.from_iso_str("12.500") == Ok(Time.from_hms(12, 30, 0))
expect Time.from_iso_str("12.500")? |> Time.to_nanos_since_midnight == 12 * Const.nanos_per_hour + 30 * Const.nanos_per_minute
# 113
expect Time.from_iso_str("12,500") == Ok(Time.from_hms(12, 30, 0))
expect Time.from_iso_str("12,500")? |> Time.to_nanos_since_midnight == 12 * Const.nanos_per_hour + 30 * Const.nanos_per_minute
# 114
expect Time.from_iso_str("1200.500") == Ok(Time.from_hms(12, 0, 30))
expect Time.from_iso_str("1200.500")? |> Time.to_nanos_since_midnight == 12 * Const.nanos_per_hour + 30 * Const.nanos_per_second
# 115
expect Time.from_iso_str("12:00,500") == Ok(Time.from_hms(12, 0, 30))
expect Time.from_iso_str("12:00,500")? |> Time.to_nanos_since_midnight == 12 * Const.nanos_per_hour + 30 * Const.nanos_per_second
# 116
expect Time.from_iso_str("12:00:00,123") == Ok(Time.from_hmsn(12, 0, 0, 123_000_000))
expect Time.from_iso_str("12:00:00,123")? |> Time.to_nanos_since_midnight == 12 * Const.nanos_per_hour + 123_000_000

# parseTime w/ offset
# 117
expect Time.from_iso_str("12:00:00+01") == Ok(Time.from_hms(11, 0, 0))
expect Time.from_iso_str("12:00:00+01")? |> Time.to_nanos_since_midnight == 11 * Const.nanos_per_hour
# 118
expect Time.from_iso_str("12:00:00-01") == Ok(Time.from_hms(13, 0, 0))
expect Time.from_iso_str("12:00:00-01")? |> Time.to_nanos_since_midnight == 13 * Const.nanos_per_hour
# 119
expect Time.from_iso_str("12:00:00+0100") == Ok(Time.from_hms(11, 0, 0))
expect Time.from_iso_str("12:00:00+0100")? |> Time.to_nanos_since_midnight == 11 * Const.nanos_per_hour
# 120
expect Time.from_iso_str("12:00:00-0100") == Ok(Time.from_hms(13, 0, 0))
expect Time.from_iso_str("12:00:00-0100")? |> Time.to_nanos_since_midnight == 13 * Const.nanos_per_hour
# 121
expect Time.from_iso_str("12:00:00+01:00") == Ok(Time.from_hms(11, 0, 0))
expect Time.from_iso_str("12:00:00+01:00")? |> Time.to_nanos_since_midnight == 11 * Const.nanos_per_hour
# 122
expect Time.from_iso_str("12:00:00-01:00") == Ok(Time.from_hms(13, 0, 0))
expect Time.from_iso_str("12:00:00-01:00")? |> Time.to_nanos_since_midnight == 13 * Const.nanos_per_hour
# 123
expect Time.from_iso_str("12:00:00+01:30") == Ok(Time.from_hms(10, 30, 0))
expect Time.from_iso_str("12:00:00+01:30")? |> Time.to_nanos_since_midnight == 10 * Const.nanos_per_hour + 30 * Const.nanos_per_minute
# 124
expect Time.from_iso_str("12:00:00-01:30") == Ok(Time.from_hms(13, 30, 0))
expect Time.from_iso_str("12:00:00-01:30")? |> Time.to_nanos_since_midnight == 13 * Const.nanos_per_hour + 30 * Const.nanos_per_minute
# 125
expect Time.from_iso_str("12.50+0030") == Ok(Time.from_hms(12, 0, 0))
expect Time.from_iso_str("12.50+0030")? |> Time.to_nanos_since_midnight == 12 * Const.nanos_per_hour
# 126
expect Time.from_iso_str("0000+1400") == Ok(Time.from_hms(-14, 0, 0))
expect Time.from_iso_str("0000+1400")? |> Time.to_nanos_since_midnight == -14 * Const.nanos_per_hour
# 127
expect Time.from_iso_str("T24-1200") == Ok(Time.from_hms(36, 0, 0))
expect Time.from_iso_str("T24-1200")? |> Time.to_nanos_since_midnight == 36 * Const.nanos_per_hour
# 128
expect Time.from_iso_str("1200+1401") == Err(InvalidTimeFormat)
# 129
expect Time.from_iso_str("1200-1201") == Err(InvalidTimeFormat)
# 130
expect Time.from_iso_str("T24+1200Z") == Err(InvalidTimeFormat)

# <==== DateTime.roc ====>
# parseDateTime
# 131
expect DateTime.from_iso_str("20240223T120000Z") == Ok(DateTime.from_ymdhms(2024, 2, 23, 12, 0, 0))
expect DateTime.from_iso_str("20240223T120000Z")? |> DateTime.to_nanos_since_epoch == 19_776.I128 * Const.seconds_per_day.to_i128() * Const.nanos_per_second.to_i128().to_i128() + 12 * Const.nanos_per_hour.to_i128()
# 132
expect DateTime.from_iso_str("2024-02-23T12:00:00+00:00") == Ok(DateTime.from_ymdhms(2024, 2, 23, 12, 0, 0))
expect DateTime.from_iso_str("2024-02-23T12:00:00+00:00")? |> DateTime.to_nanos_since_epoch == 19_776.I128 * Const.seconds_per_day.to_i128() * Const.nanos_per_second.to_i128().to_i128() + 12 * Const.nanos_per_hour.to_i128()
# 133
expect DateTime.from_iso_str("2024-02-23T00:00:00+14") == Ok(DateTime.from_ymdhms(2024, 2, 22, 10, 0, 0))
expect DateTime.from_iso_str("2024-02-23T00:00:00+14")? |> DateTime.to_nanos_since_epoch == 19_776.I128 * Const.nanos_per_day.to_i128() - 14.I128 * Const.nanos_per_hour.to_i128()
# 134
expect DateTime.from_iso_str("2024-02-23T23:59:59-12") == Ok(DateTime.from_ymdhms(2024, 2, 24, 11, 59, 59))
expect DateTime.from_iso_str("2024-02-23T23:59:59-12")? |> DateTime.to_nanos_since_epoch == 19_776.I128 * Const.nanos_per_day.to_i128() + (Const.nanos_per_day.to_i128() - 1.I128 * Const.nanos_per_second.to_i128()) + 12 * Const.nanos_per_hour.to_i128()
# 135
expect DateTime.from_iso_str("2024-02-23T12:00:00+01:30") == Ok(DateTime.from_ymdhms(2024, 2, 23, 10, 30, 0))
expect DateTime.from_iso_str("2024-02-23T12:00:00+01:30")? |> DateTime.to_nanos_since_epoch == 19_776.I128 * Const.nanos_per_day.to_i128() + 10 * Const.nanos_per_hour.to_i128() + 30 * Const.nanos_per_minute.to_i128()

# <==== Utils.roc ====>
# <---- validateUtf8SingleBytes ---->
expect Utils.validate_utf8_single_bytes([0b01111111])
expect !(Utils.validate_utf8_single_bytes([0b10000000, 0b00000001]))
expect !("🔥".to_utf8() |> Utils.validate_utf8_single_bytes)

# <---- utf8ToInt ---->
expect ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'] |> Utils.utf8_to_int == Ok(123456789)
expect Utils.utf8_to_int(['@']) == Err(InvalidBytes)
expect Utils.utf8_to_int(['/']) == Err(InvalidBytes)

# <---- utf8ToIntSigned ---->
expect ['-', '1'] |> Utils.utf8_to_int_signed == Ok(-1)
expect ['+', '1'] |> Utils.utf8_to_int_signed == Ok(1)
expect ['1', '9'] |> Utils.utf8_to_int_signed == Ok(19)

# <---- utf8ToFrac ---->
expect is_approx_eq(Utils.utf8_to_frac(['1', '2', '.', '3', '4', '5'])?, 12.345, { atol: 0.0001 })
expect is_approx_eq(Utils.utf8_to_frac(['1', '2', ',', '3', '4', '5'])?, 12.345, { atol: 0.0001 })
expect is_approx_eq(Utils.utf8_to_frac(['.', '1', '2', '3'])?, 0.123, { atol: 0.0001 })
expect is_approx_eq(Utils.utf8_to_frac([',', '1', '2', '3'])?, 0.123, { atol: 0.0001 })
expect is_approx_eq(Utils.utf8_to_frac(['1', '2', '3'])?, 123.0, { atol: 0.0001 })
expect is_approx_eq(Utils.utf8_to_frac(['1', '2', '3', '.'])?, 123.0, { atol: 0.0001 })
expect Utils.utf8_to_frac(['1', '2', 'Z']) == Err(InvalidBytes)
expect Utils.utf8_to_frac(['T', '2', '3']) == Err(InvalidBytes)

# The following function should soon be available in Roc's builtins
is_approx_eq : _, _, { atol : _ } -> Bool
is_approx_eq = |x, y, { atol }| {
	to_int = |f| {
		(f / atol + 0.5).to_i64_try()
	}

	match (to_int(x), to_int(y)) {
		(Ok(xi), Ok(yi)) => (xi == yi)
		_ => Bool.False
	}
}
