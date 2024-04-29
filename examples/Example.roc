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
    ]
    provides [main] to pf

main =
    utcNow <- Utc.now |> Task.await
    dtNow = Utc.toNanosSinceEpoch utcNow |> DateTime.fromNanosSinceEpoch
    Stdout.line "Hello, World! The current date and time is: $(DateTime.toIsoStr dtNow)"