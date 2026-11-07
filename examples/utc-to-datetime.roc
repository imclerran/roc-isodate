app [main!] {
	dt: "../package/main.roc",
	pf: platform "https://github.com/roc-lang/basic-cli/releases/download/0.27.0/9yjxqdGTP4xSpSEmDazwTmRsehfRZzA19pwEKkR6fj1g.tar.zst",
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
