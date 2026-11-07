app [main!] {
	dt: "../package/main.roc",
	pf: platform "https://github.com/roc-lang/basic-cli/releases/download/0.27.0/9yjxqdGTP4xSpSEmDazwTmRsehfRZzA19pwEKkR6fj1g.tar.zst",
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
