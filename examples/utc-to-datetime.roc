app [main!] {
	dt: "../package/main.roc",
	pf: platform "https://github.com/roc-lang/basic-cli/releases/download/0.26.0/GddgvsGjiNXrHFW6au5i5dUDbTs8FinQdrgE2Gqmw53t.tar.zst",
}

import pf.Stdout
import pf.Utc
import dt.DateTime

main! = |_| {
	utc_now = Utc.now!()
	now_str =
		(
			utc_now
				|> Utc.to_nanos_since_epoch
				.to_i128_try()?
				|> DateTime.from_nanos_since_epoch,
		).to_iso_str()
	_ = Stdout.line!("The current Zulu time is: ${now_str}")
	Ok({})
}
