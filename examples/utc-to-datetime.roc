app [main] {
    pf: platform "https://github.com/roc-lang/basic-cli/releases/download/0.14.0/dC5ceT962N_4jmoyoffVdphJ_4GlW3YMhAPyGPr-nU0.tar.br",
    dt: "../package/main.roc",
}

import pf.Stdout
import pf.Task
import pf.Utc
import dt.DateTime

main =
    utcNow = Utc.now!
    nowStr =
        utcNow
        |> Utc.toNanosSinceEpoch
        |> DateTime.fromNanosSinceEpoch
        |> DateTime.toIsoStr
    Stdout.line "Hello, World! The current Zulu time is: $(nowStr)"
