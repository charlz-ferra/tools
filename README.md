# tools

[![ci](https://github.com/charlz-ferra/tools/actions/workflows/ci.yml/badge.svg)](https://github.com/charlz-ferra/tools/actions/workflows/ci.yml)

> Small sharp automation, UNIX-style. Each script does one thing,
> survives `set -euo pipefail`, and has been run in anger on a real box.

| Tool                | One-liner                                                              |
| ------------------- | ---------------------------------------------------------------------- |
| `safe-restart`      | Restart a service your SSH session depends on — without bricking it    |
| `fetch-blocklist`   | Pull the Hagezi TIF threat list, refuse broken downloads               |
| `tg-offsite-backup` | WAL-safe SQLite + configs → tar → gpg → Telegram, with dead-man marker |
| `ssh-canary`        | Telegram ping on every SSH login — who, where, which key, new-device   |

## safe-restart

You SSH into a box and restart the very service your connection rides on
(VPN endpoint, network stack). Session drops, the restart dies with it,
the service never comes back. This schedules the restart through a
**transient systemd timer** — detached from your session, guaranteed to
finish. Your SSH still drops; the box survives.

```bash
safe-restart x-ui
safe-restart hysteria-server 5   # custom delay
```

## fetch-blocklist

Threat-intel blocklist updater that knows two things most don't:

1. **Threat lists are for threats.** No ad/tracker lists mixed in — otherwise
   `app-measurement` and friends light up your alerting as "malware" and you
   stop reading alerts.
2. **A broken download is worse than a stale list.** Size sanity check before
   replacing anything.

```bash
BLOCKLIST_PATH=/var/lib/blocklists/tif.txt fetch-blocklist
```

## tg-offsite-backup

Encrypted offsite backups into a Telegram chat. WAL-safe SQLite snapshots
(`sqlite3 .backup`, consistent even mid-write), config paths, tar, symmetric
gpg, `sendDocument`. Local rotation. A `.last-ok` **dead-man marker** that only
updates on successful offsite — point your monitoring at its mtime and you'll
know the day backups silently die, not the day you need one.

```bash
ENV_FILE=/etc/backup.env tg-offsite-backup
```

```bash
# /etc/backup.env (chmod 600)
BACKUP_DBS="/etc/x-ui/x-ui.db /opt/bot/data/bot.db"
BACKUP_PATHS="/etc/tor/torrc /etc/fail2ban/jail.local /etc/sysctl.d/*.conf"
TG_BOT_TOKEN=...
TG_CHAT_ID=...
```

## ssh-canary

A pager for your front door. Hooks into PAM so it fires on **every** successful
SSH login — root or not, key or password — and pushes a Telegram message with
the user, source IP (+ geo), the SSH key fingerprint, and a loud `🆕 NEW DEVICE`
flag the first time a given key/host combo shows up. The day someone walks in on
a stolen key, you hear about it from your phone in seconds.

```bash
sudo install -m 755 ssh-canary /usr/local/bin/
sudo tee /etc/ssh-canary.env >/dev/null <<'EOF'
TG_BOT_TOKEN=123:abc
TG_CHAT_ID=123456789
GEOIP_DB=/var/lib/GeoLite2-Country.mmdb   # local geo, optional
GEO_API=0                                 # 1 = ip-api.com fallback (leaks IPs!)
EOF
sudo chmod 600 /etc/ssh-canary.env
echo 'session optional pam_exec.so /usr/local/bin/ssh-canary' | sudo tee -a /etc/pam.d/sshd
```

It's `session optional` and every external call is time-boxed, so a broken token
or a dead network means _no ping_ — never a locked-out login. Geo lookups are
**local by default** (GeoLite2 mmdb) or skipped; it only talks to a third-party
API if you explicitly set `GEO_API=1`, because a tripwire that narcs your every
login IP to `ip-api.com` defeats the point.

## Install

```bash
sudo install -m 755 safe-restart fetch-blocklist tg-offsite-backup ssh-canary /usr/local/bin/
```

## License

[MIT](LICENSE)
