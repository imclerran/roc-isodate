app [main!] {
    cli: platform "https://github.com/roc-lang/basic-cli/releases/download/0.19.0/Hj-J_zxz7V9YurCSTFcFdu6cQJie4guzsPMUi5kBYUk.tar.br",
    dt: "../package/main.roc",
}

import cli.Http
import cli.Stdout
import dt.DateTime

main! = |_|
    req = format_request("America/Chicago")
    response = Http.send!(req)?
    if response.status >= 200 and response.status <= 299 then
        iso_str = get_iso_str(response.body)?
        dt_now = DateTime.from_iso_str(iso_str)?

        time_str = "${Num.to_str dt_now.time.hour}:${Num.to_str dt_now.time.minute}:${Num.to_str dt_now.time.second}"
        date_str = "${Num.to_str dt_now.date.year}-${Num.to_str dt_now.date.month}-${Num.to_str dt_now.date.day_of_month}"
        "The current Zulu date is: ${date_str}" |> Stdout.line!()?
        "The current Zulu time is: ${time_str}"|> Stdout.line!()
    else
        Err FailedToGetServerResponse(response.status)

format_request = |timezone| {
    method: GET,
    headers: [],
    uri: "http://worldtimeapi.org/api/timezone/${timezone}.txt",
    body: [],
    timeout_ms: TimeoutMilliseconds 3000,
}

get_iso_str : List U8 -> Result Str _
get_iso_str = |bytes|
    body = Str.from_utf8(bytes) ? |_| FailedToParseResponse
    line =
        List.find_first(
            Str.split_on(body, "\n"),
            |ln| Str.starts_with(ln, "datetime:"),
        )
        ? |_| FailedToFindDatetime
    { after } = Str.split_first(line, ":") ? |_| FailedToFindColon
    after |> Str.trim |> Ok
