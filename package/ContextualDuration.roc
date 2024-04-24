inteface ContextualDuration
    exposes []
    imports []

ContextualDuration : { years: I64, months: I8, days: I16, hours: I8, minutes: I8, seconds: I8, nanoseconds: I32 }

fromYmd : Int *, Int *, Int * -> ContextualDuration
fromYmd = \y, m, d -> { years: Num.toI64 y, months: Num.toI8 m, days: Num.toI16 d, hours: 0, minutes: 0, seconds: 0, nanoseconds: 0 }

fromHms : Int *, Int *, Int * -> ContextualDuration
fromHms = \h, m, s -> { years: 0, months: 0, days: 0, hours: Num.toI8 h, minutes: Num.toI8 m, seconds: Num.toI8 s, nanoseconds: 0 }

fromHmsn : Int *, Int *, Int *, Int * -> ContextualDuration
fromHmsn = \h, m, s, n -> { years: 0, months: 0, days: 0, hours: Num.toI8 h, minutes: Num.toI8 m, seconds: Num.toI8 s, nanoseconds: Num.toI32 n }

fromYmdHms : Int *, Int *, Int *, Int *, Int *, Int * -> ContextualDuration
fromYmdHms = \y, m, d, h, mi, s -> { years: Num.toI64 y, months: Num.toI8 m, days: Num.toI16 d, hours: Num.toI8 h, minutes: Num.toI8 mi, seconds: Num.toI8 s, nanoseconds: 0 }

fromYmdHmsn : Int *, Int *, Int *, Int *, Int *, Int *, Int * -> ContextualDuration
fromYmdHmsn = \y, m, d, h, mi, s, n -> { years: Num.toI64 y, months: Num.toI8 m, days: Num.toI16 d, hours: Num.toI8 h, minutes: Num.toI8 mi, seconds: Num.toI8 s, nanoseconds: Num.toI32 n }

addDateAndDuration : Date, ContextualDuration -> Date
addDateAndDuration = \date, duration -> 
    Date.addYears date duration.years
    |> Date.addMonths duration.months
    |> Date.addDays duration.days

addDurationAndDate : ContextualDuration, Date -> Date
addDurationAndDate = \duration, date -> addDateAndDuration date duration


    
        
