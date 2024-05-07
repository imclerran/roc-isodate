app "parse-iso"
    packages {
        pf: "https://github.com/roc-lang/basic-cli/releases/download/0.10.0/vNe6s9hWzoTZtFmNkvEICPErI9ptji_ySjicO6CkucY.tar.br",
        dt: "../package/main.roc",
    }
    imports [
        pf.Http,
        pf.Task.{ Task },
        pf.Stdout,
        dt.DateTime,
    ]
    provides [main] to pf

main =
    response = Http.send! (formatRequest "America/Chicago")
    responseBody =
        when response |> Http.handleStringResponse is
            Err err -> crash (Http.errorToString err)
            Ok body -> body

    isoStr = getIsoString responseBody

    dtNow =
        when DateTime.fromIsoStr isoStr is
            Ok dateTime -> dateTime
            Err _ -> crash "Parsing Error"

    timeStr = "$(Num.toStr dtNow.time.hour):$(Num.toStr dtNow.time.minute):$(Num.toStr dtNow.time.second)"
    dateStr = "$(Num.toStr dtNow.date.year)-$(Num.toStr dtNow.date.month)-$(Num.toStr dtNow.date.dayOfMonth)"

    Stdout.line! "The current Zulut date is: $(dateStr)"
    Stdout.line "The current Zulu time is: $(timeStr)"

formatRequest = \timezone -> {
    method: Get,
    headers: [],
    url: "http://worldtimeapi.org/api/timezone/$(timezone).txt",
    mimeType: "",
    body: [],
    timeout: TimeoutMilliseconds 5000,
}


getIsoString = \body ->
    when Str.split body "\n" |> List.get 2 is
        Ok line ->
            when Str.splitFirst line ":" is
                Ok lineParts -> lineParts.after |> Str.trim
                Err _ -> crash "Error splitting line at delimiter"
        Err _ -> crash "Error getting output line"