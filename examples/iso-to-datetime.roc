app [main!] {
    pf: platform "../../basic-cli/platform/main.roc",
    # pf: platform "https://github.com/roc-lang/basic-cli/releases/download/0.17.0/lZFLstMUCUvd5bjnnpYromZJXkQUrdhbva4xdBInicE.tar.br",
    dt: "../package/main.roc",
}

import pf.Http
import pf.Stdout
import dt.DateTime

main! = \_ ->
    response = Http.send!(format_request("America/Chicago"))

    response_body =
        when response is
            Ok { status, body } if status == 200 -> Str.from_utf8(body)?
            _ -> crash("Error getting response body")

    iso_str = get_iso_string(response_body)

    dt_now =
        when DateTime.from_iso_str(iso_str) is
            Ok(date_time) -> date_time
            Err(_) -> crash("Parsing Error")

    time_str = "${Num.to_str(dt_now.time.hour)}:${Num.to_str(dt_now.time.minute)}:${Num.to_str(dt_now.time.second)}"
    date_str = "${Num.to_str(dt_now.date.year)}-${Num.to_str(dt_now.date.month)}-${Num.to_str(dt_now.date.day_of_month)}"
    try Stdout.line!("The current Zulu date is: ${date_str}")
    try Stdout.line!("The current Zulu time is: ${time_str}")
    Ok {}

format_request = \timezone -> {
    method: GET,
    headers: [],
    uri: "http://worldtimeapi.org/api/timezone/${timezone}.txt",
    body: [],
    timeout_ms: TimeoutMilliseconds(5000),
}

get_iso_string = \body ->
    when Str.split_on(body, "\n") |> List.get(3) is
        Ok(line) ->
            when Str.split_first(line, ":") is
                Ok(line_parts) -> line_parts.after |> Str.trim
                Err(_) -> crash("Error splitting line at delimiter")

        Err(_) -> crash("Error getting output line")
