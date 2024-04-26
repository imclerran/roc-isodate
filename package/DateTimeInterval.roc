interface DateTimeInterval
    exposes [
        DateTimeInterval,
    ]
    imports [
        DateTime,
        DateTime.{ DateTime },
    ]

DateTimeInterval : { start: DateTime, end: DateTime }