app [main!] {
	pf: platform "https://github.com/roc-lang/basic-cli/releases/download/0.23.0/GNN5tt2gKdX4dhawg4915C4YB193woHFdcCkz31fhGxv.tar.zst",
	dt: "../package/main.roc",
}

import pf.Stdout
import pf.Utc
import dt.DateTime
import dt.Now

main! = |_args| {
	now = Now.create({
		now!: Utc.now!,
		now_to_nanos: Utc.to_nanos_since_epoch,
	})
	_ = now.date_time!()
		.format("{MM}/{DD}/{YY} | {hh}:{mm}:{ss}")
		|> Stdout.line!
	Ok({})
}
