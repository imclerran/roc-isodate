app [main!] { 
    cli: platform "https://github.com/roc-lang/basic-cli/releases/download/0.19.0/Hj-J_zxz7V9YurCSTFcFdu6cQJie4guzsPMUi5kBYUk.tar.br",
    dt: "../package/main.roc"
}

import cli.Sleep
import cli.Stdout
import cli.Utc
import dt.Duration
import dt.Time
import dt.Now {
    now!: Utc.now!,
    now_to_nanos: Utc.to_nanos_since_epoch,
}

main! = |_args|
    start = Now.time!({})
    Sleep.millis!(1000)
    end = Now.time!({})
    duration = Time.sub(end, start)
    Duration.format(duration, "Slept for {s}.{f} seconds")
    |> Stdout.line!
