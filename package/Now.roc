module { now!, now_to_nanos } -> [date_time!, date!, time!]

import Const
import DateTime exposing [DateTime]
import Date exposing [Date]
import Time exposing [Time]

## Get the current system time as a `DateTime`.
date_time! : {} => DateTime
date_time! = |{}| now!({}) |> now_to_nanos |> DateTime.from_nanos_since_epoch

## Get the current system time as a `Date`.
date! : {} => Date
date! = |{}| now!({}) |> now_to_nanos |> Date.from_nanos_since_epoch

## Get the current system time as a `Time`.
time! : {} => Time
time! = |{}| now!({}) |> now_to_nanos |> |ns| ns % Const.nanos_per_day |> Time.from_nanos_since_midnight

