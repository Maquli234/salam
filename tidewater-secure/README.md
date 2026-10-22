# Tidewater IT (patched)

Hardened rebuild of the Tidewater lab site. The LFI, log poisoning and Docker-socket escalation are removed. See `docs/SECURITY-FIXES.md`.

## Deploy on the Linux machine
```bash
unzip tidewater-secure.zip && cd tidewater-secure
chmod +x *.sh
sudo ./deploy.sh        # removes the old container, builds, starts, runs the retest
```
Or by hand: `sudo docker compose up -d --build`, then `sudo ./verify-fixed.sh`.

## Host cleanup (find-only sudo, cron cleaner, flags)
```bash
sudo -i
./harden-host.sh                   # sudo/cron/flags
HARDEN_SSH=yes ./harden-host.sh    # also disables password SSH (test key login first)
```

## If the container does not start
`sudo docker logs tidewater`. This build could not be run in my sandbox (no Docker), so if Apache complains, relax in this order: remove `read_only: true`, then add the capability named in the error.
