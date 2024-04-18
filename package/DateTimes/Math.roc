interface DateTimes.Math
    exposes [
    ]
    imports [
        DateTimes.Conversion.{
            nanosecondsInASecond,
            secondsInAnHour,
            secondsInAMinute,
        }
        DateTimes.Duration,
        DateTimes.Duration.{ Duration },
        DateTimes.NaiveDate,
        DateTimes.NaiveDate.{ NaiveDate },
        DateTimes.NaiveDateTime,
        DateTimes.NaiveDateTime.{ NaiveDateTime },
        DateTimes.NaiveTime,
        DateTimes.NaiveTime.{ NaiveTime },
    ]

timeToNanos : NaiveTime -> U128
timeToNanos = \time ->
    hNanos = time.hour * secondsInAnHour * nanosecondsInASecond |> Num.toU128
    mNanos = time.minute * secondsInAMinute * nanosecondsInASecond |> Num.toU128
    sNanos = time.second * nanosecondsInASecond |> Num.toU128
    hNanos + mNanos + sNanos + Num.toU128 nanoSecondsInASecond

dateToNanos : NaiveDate -> U128
dateToNanos = \date ->
    yNanos = date.year * secondsInAYear * nanosecondsInASecond |> Num.toU128
    mNanos = date.month * secondsInAMonth * nanosecondsInASecond |> Num.toU128
    dNanos = date.day * secondsInADay * nanosecondsInASecond |> Num.toU128
    yNanos + mNanos + dNanos


timeDifference : NaiveTime, NaiveTime -> Duration
timeDifference = \time1, time2 -> Duration.fromSeconds