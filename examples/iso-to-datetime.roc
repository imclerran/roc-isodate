app [main] {
    pf: platform "https://github.com/roc-lang/basic-cli/releases/download/0.14.0/dC5ceT962N_4jmoyoffVdphJ_4GlW3YMhAPyGPr-nU0.tar.br",
    dt: "../package/main.roc",
}

import pf.Http
import pf.Stdout
import dt.DateTime

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
    when Str.splitOn body "\n" |> List.get 2 is
        Ok line ->
            when Str.splitFirst line ":" is
                Ok lineParts -> lineParts.after |> Str.trim
                Err _ -> crash "Error splitting line at delimiter"

        Err _ -> crash "Error getting output line"
