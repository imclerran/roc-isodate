app [main!] {
    cli: platform "https://github.com/roc-lang/basic-cli/releases/download/0.19.0/Hj-J_zxz7V9YurCSTFcFdu6cQJie4guzsPMUi5kBYUk.tar.br",
    dt: "../package/main.roc",
}

import cli.Stdout
import cli.Utc
import dt.DateTime

main! = |_|
    utc_now = Utc.now!({})
    now_str =
        utc_now
        |> Utc.to_nanos_since_epoch
        |> DateTime.from_nanos_since_epoch
        |> DateTime.to_iso_str
    Stdout.line!("The current Zulu time is: ${now_str}")
