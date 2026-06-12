# tools

[![ci](https://github.com/charlz-ferra/tools/actions/workflows/ci.yml/badge.svg)](https://github.com/charlz-ferra/tools/actions/workflows/ci.yml)

> Small sharp automation, UNIX-style. Each script does one thing,
> survives `set -euo pipefail`, and has been run in anger on a real box.

| Tool                | One-liner                                                              |
| ------------------- | ---------------------------------------------------------------------- |
| `safe-restart`      | Restart a service your SSH session depends on — without bricking it    |
| `fetch-blocklist`   | Pull the Hagezi TIF threat list, refuse broken downloads               |
| `tg-offsite-backup` | WAL-safe SQLite + configs → tar → gpg → Telegram, with dead-man marker |

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

## Install

```bash
sudo install -m 755 safe-restart fetch-blocklist tg-offsite-backup /usr/local/bin/
```

## License

[MIT](LICENSE)
