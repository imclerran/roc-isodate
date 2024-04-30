app "example1"
    packages {
        pf: "https://github.com/roc-lang/basic-cli/releases/download/0.9.1/y_Ww7a2_ZGjp0ZTt9Y_pNdSqqMRdMLzHMKfdN8LWidk.tar.br",
        dt: "../package/main.roc",
    }
    imports [
        pf.Stdout,
        pf.Task,
        pf.Utc,
        dt.DateTime,
        # import additional modules to avoid bug in roc
        dt.Duration,
        dt.Time,
        dt.Date,
    ]
    provides [main] to pf

main =
    utcNow = Utc.now!
    nowStr = utcNow
        |> Utc.toNanosSinceEpoch
        |> DateTime.fromNanosSinceEpoch
        |> DateTime.toIsoStr
    Stdout.line "Hello, World! The current Zulu time is: $(nowStr)"