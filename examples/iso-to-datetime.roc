app [main!] {
    cli: platform "https://github.com/roc-lang/basic-cli/releases/download/0.19.0/bi5zubJ-_Hva9vxxPq4kNx4WHX6oFs8OP6Ad0tCYlrY.tar.br",
    dt: "../package/main.roc",
}

import cli.Http
import cli.Stdout
import dt.DateTime

main! = |_|
    req = format_request("America/Chicago")
    response = Http.send!(req)?
    iso_str = get_iso_str(response.body)?
    dt_now = DateTime.from_iso_str(iso_str)?

    time_str = "$(Num.to_str dt_now.time.hour):$(Num.to_str dt_now.time.minute):$(Num.to_str dt_now.time.second)"
    date_str = "$(Num.to_str dt_now.date.year)-$(Num.to_str dt_now.date.month)-$(Num.to_str dt_now.date.day_of_month)"
    Stdout.line!("The current Zulu date is: $(date_str)")?
    Stdout.line!("The current Zulu time is: $(time_str)")?
    
    Ok({})

format_request = |timezone| {
    method: GET,
    headers: [],
    uri: "http://worldtimeapi.org/api/timezone/$(timezone).txt",
    body: [],
    timeout_ms: TimeoutMilliseconds 5000,
}

get_iso_str : List U8 -> Result Str _
get_iso_str = |bytes|
    body = Str.from_utf8(bytes)?
    line = List.get(Str.split_on(body, "\n"), 3)?
    { after } = Str.split_first(line, ":")?
    after |> Str.trim |> Ok
