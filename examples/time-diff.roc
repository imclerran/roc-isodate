app [main!] {
	pf: platform "https://github.com/roc-lang/basic-cli/releases/download/0.26.0/GddgvsGjiNXrHFW6au5i5dUDbTs8FinQdrgE2Gqmw53t.tar.zst",
	dt: "../package/main.roc",
}

import pf.Sleep
import pf.Stdout
import pf.Utc
import dt.Duration
import dt.Time
import dt.Now

main! = |_args| {
	now = Now.create({
		now!: Utc.now!,
		now_to_nanos: Utc.to_nanos_since_epoch,
	})
	start = now.time!()
	Sleep.millis!(1000)?
	end = now.time!()
	duration = Time.sub(end, start)
	_ = Duration.format(duration, "Slept for {s}.{f} seconds")
		|> Stdout.line!
	Ok({})
}
