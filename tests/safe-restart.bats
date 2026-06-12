#!/usr/bin/env bats
#
# Tests for safe-restart. We stub `systemd-run` so nothing is actually
# scheduled — we just assert the command is invoked with a transient,
# session-detached unit and the right delay.

setup() {
	SR="${BATS_TEST_DIRNAME}/../safe-restart"
	STUB="${BATS_TEST_TMPDIR}/bin"
	mkdir -p "$STUB"
	{
		echo '#!/usr/bin/env bash'
		echo 'printf "%s\n" "$@" >>"$SDR_LOG"'
		echo 'exit 0'
	} >"$STUB/systemd-run"
	chmod +x "$STUB/systemd-run"
	export SDR_LOG="${BATS_TEST_TMPDIR}/systemd-run.log"
	: >"$SDR_LOG"
}

run_sr() {
	PATH="$STUB:$PATH" bash "$SR" "$@"
}

@test "no service argument is a usage error" {
	run run_sr
	[ "$status" -ne 0 ]
}

@test "schedules a transient unit for the given service" {
	run run_sr x-ui
	[ "$status" -eq 0 ]
	[[ "$output" == *"scheduled"* ]]
	grep -q -- "--unit=safe-restart-x-ui" "$SDR_LOG"
	grep -q -- "--on-active=2" "$SDR_LOG" # default delay
	grep -q "restart" "$SDR_LOG"
	grep -q "x-ui" "$SDR_LOG"
}

@test "honors a custom delay" {
	run run_sr hysteria-server 5
	[ "$status" -eq 0 ]
	grep -q -- "--on-active=5" "$SDR_LOG"
	grep -q -- "--unit=safe-restart-hysteria-server" "$SDR_LOG"
}
