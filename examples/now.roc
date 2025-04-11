app [main!] { 
    cli: platform "https://github.com/roc-lang/basic-cli/releases/download/0.19.0/Hj-J_zxz7V9YurCSTFcFdu6cQJie4guzsPMUi5kBYUk.tar.br",
    dt: "../package/main.roc"
}

import cli.Stdout
import cli.Utc
import dt.DateTime
import dt.Now {
    now!: Utc.now!,
    now_to_nanos: Utc.to_nanos_since_epoch,
}

main! = |_args|
    Now.date_time!({})
    |> DateTime.format("{MM}/{DD}/{YY} | {hh}:{mm}:{ss}")
    |> Stdout.line!

