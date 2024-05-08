app [main] {
    pf: platform "https://github.com/roc-lang/basic-cli/releases/download/0.10.0/vNe6s9hWzoTZtFmNkvEICPErI9ptji_ySjicO6CkucY.tar.br",
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
