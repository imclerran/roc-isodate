app [main!] {
	dt: "../package/main.roc",
	http: "https://github.com/roc-lang/http/releases/download/2.0.0/6ZUwqYhCS8PU9Mo6MF7oV82ET2o7KYb57CLKDq4cq4sS.tar.zst",
	pf: platform "https://github.com/roc-lang/basic-cli/releases/download/0.26.0/GddgvsGjiNXrHFW6au5i5dUDbTs8FinQdrgE2Gqmw53t.tar.zst",
}

import pf.Stdout
import pf.Http
import http.Method
import http.Request
import dt.DateTime as DT

main! = |_| {
	timezone = "Europe/Paris"
	request = Request.from_method(GET)
		.with_uri("https://timeapi.io/api/v1/timezone/zone?timeZone=${timezone}")
		.with_timeout(TimeoutMilliseconds(3000))
	response = Http.send!(request, {})?
	if response.status() >= 200 and response.status() <= 299 {
		iso_str = get_iso_str(response.body())?
		dt_now = DT.from_iso_str(iso_str)?
		date_str = dt_now.format("{YYYY}-{MM}-{DD}")
		time_str = dt_now.format("{hh}:{mm}:{ss}")
		_ = Stdout.line!("The current date in ${timezone} is: ${date_str}")
		_ = Stdout.line!("The current time in ${timezone} is: ${time_str}")
		Ok({})
	} else {
		Err(FailedToGetServerResponse(response.status()))
	}
}

get_iso_str : List(U8) -> Try(Str, _)
get_iso_str = |bytes| {
	str = bytes |> Str.from_utf8()?
	response : { local_time : Str }
	response = Json.parse(str)?
	Ok(response.local_time)
}
