app [main!] { 
    cli: platform "https://github.com/roc-lang/basic-cli/releases/download/0.19.0/Hj-J_zxz7V9YurCSTFcFdu6cQJie4guzsPMUi5kBYUk.tar.br",
    dt: "../package/main.roc"
}

import cli.Sleep
import cli.Stdout
import cli.Utc
import dt.Duration
import dt.DateTime
import dt.Time

main! = |_args|
    start = Utc.now!({}) |> Utc.to_nanos_since_epoch |> DateTime.from_nanos_since_epoch
    Sleep.millis!(1000)
    end = Utc.now!({}) |> Utc.to_nanos_since_epoch |> DateTime.from_nanos_since_epoch
    duration = Time.sub(end.time, start.time)
    Duration.format(duration, "Slept for {s}.{f} seconds")
    |> Stdout.line!
