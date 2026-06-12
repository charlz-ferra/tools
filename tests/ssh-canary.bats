#!/usr/bin/env bats
#
# Behavioral tests for ssh-canary. We stub `curl` with a fake that logs its
# args to a file, so we can assert what message would be sent without anything
# leaving the box — and verify the new-device state logic.

setup() {
	SC="${BATS_TEST_DIRNAME}/../ssh-canary"
	STUB="${BATS_TEST_TMPDIR}/bin"
	mkdir -p "$STUB"
	# fake curl: record args, succeed, produce no stdout
	{
		echo '#!/usr/bin/env bash'
		echo 'printf "%s\n" "$@" >>"$CURL_LOG"'
		echo 'exit 0'
	} >"$STUB/curl"
	chmod +x "$STUB/curl"
	export CURL_LOG="${BATS_TEST_TMPDIR}/curl.log"
	: >"$CURL_LOG"

	ENVF="${BATS_TEST_TMPDIR}/env"
	printf 'TG_BOT_TOKEN=stub\nTG_CHAT_ID=999\n' >"$ENVF"
	export CANARY_ENV="$ENVF"
	export CANARY_STATE="${BATS_TEST_TMPDIR}/seen"
}

run_canary() {
	PATH="$STUB:$PATH" PAM_TYPE="$1" PAM_USER="${2:-root}" PAM_RHOST="${3:-8.8.8.8}" \
		PAM_TTY=ssh PAM_SERVICE=sshd bash "$SC"
}

@test "ignores non-open_session events" {
	run run_canary close_session
	[ "$status" -eq 0 ]
	[ ! -s "$CURL_LOG" ] # nothing sent
}

@test "stays silent without a bot token" {
	printf 'TG_BOT_TOKEN=\nTG_CHAT_ID=\n' >"$CANARY_ENV"
	run run_canary open_session
	[ "$status" -eq 0 ]
	[ ! -s "$CURL_LOG" ]
}

@test "first login from a host flags NEW DEVICE and records state" {
	run run_canary open_session root 8.8.8.8
	[ "$status" -eq 0 ]
	grep -q "NEW DEVICE" "$CURL_LOG"
	grep -q "chat_id" "$CURL_LOG"
	[ -f "$CANARY_STATE" ]
	grep -q "root@8.8.8.8" "$CANARY_STATE"
}

@test "second login from same host is not NEW, no duplicate state" {
	run_canary open_session root 8.8.8.8 # seed
	: >"$CURL_LOG"
	run run_canary open_session root 8.8.8.8
	[ "$status" -eq 0 ]
	! grep -q "NEW DEVICE" "$CURL_LOG"
	grep -q "chat_id" "$CURL_LOG" # still pings
	[ "$(grep -c 'root@8.8.8.8' "$CANARY_STATE")" -eq 1 ]
}
