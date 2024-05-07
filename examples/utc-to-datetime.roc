app "example1"
    packages {
        pf: "https://github.com/roc-lang/basic-cli/releases/download/0.10.0/vNe6s9hWzoTZtFmNkvEICPErI9ptji_ySjicO6CkucY.tar.br",
        dt: "../package/main.roc",
    }
    imports [
        pf.Stdout,
        pf.Task,
        pf.Utc,
        dt.DateTime,
    ]
    provides [main] to pf

main =
    utcNow = Utc.now!
    nowStr = utcNow
        |> Utc.toNanosSinceEpoch
        |> DateTime.fromNanosSinceEpoch
        |> DateTime.toIsoStr
    Stdout.line "Hello, World! The current Zulu time is: $(nowStr)"