app [main!] {
	pf: platform "https://github.com/roc-lang/basic-cli/releases/download/0.23.0/GNN5tt2gKdX4dhawg4915C4YB193woHFdcCkz31fhGxv.tar.zst",
	dt: "../package/main.roc",
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
