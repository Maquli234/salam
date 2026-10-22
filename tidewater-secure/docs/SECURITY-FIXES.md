# Tidewater IT: vulnerability fixes

| # | Vulnerability (old) | Fix (new) | Where |
|---|---------------------|-----------|-------|
| 1 | LFI: `?page=` was concatenated into an `include` path, filtered only by a one-pass `str_replace('../')` | Allow-list routing: user input is only an array key (`routes.php`); anything not listed returns 404. Pages are plain keys (`?page=about`), never file names | `web/public/index.php`, `web/app/routes.php` |
| 2 | RCE by Apache log poisoning (readable `access.log` included as PHP) | Root cause removed by #1. Also: no readable log files (logs go to stdout/stderr), `open_basedir` limits PHP to the site folders, dangerous functions disabled | `hardening.ini`, base image logging |
| 3 | `www-data` could use the host Docker daemon (socket mounted) = host root | Socket not mounted, no docker CLI in the image, `no-new-privileges`, all capabilities dropped except the four Apache needs, read-only root filesystem | `docker-compose.yml`, `Dockerfile` |
| 4 | Credentials in `config.php`, reused as the `marcus` account password | No credentials in the app (it uses no database), no `marcus` account, no secrets in the container environment | removed |
| 5 | Verbose PHP errors revealed filesystem paths | `display_errors = Off`, errors go to the container log | `hardening.ini` |
| 6 | Old credentials in `/backup/`, advertised by `robots.txt` | Both deleted | removed |
| 7 | Application code and `includes/` inside the web root | Code moved to `/var/www/app` outside the web root; Apache denies everything under `/var/www` except `/var/www/html` | `tidewater.conf` |
| 8 | Dead "client portal" login form | Removed (unused attack surface) | removed |
| 9 | Banner and header leakage, no browser protections | `ServerTokens Prod`, no `X-Powered-By`, CSP, `nosniff`, `X-Frame-Options`, `Referrer-Policy`, TRACE off, request body limit, methods limited to GET/POST/HEAD | `tidewater.conf` |
| 10 | Extra tooling in the container (python3, docker CLI, deploy-notes clue) | Not installed | `Dockerfile` |
| 11 | Host: `ubuntu` limited to `sudo find`, password SSH, log-cleaner cron, `/root/root.txt` | `harden-host.sh` reverts these (see script) | host |

## Retest
`sudo ./verify-fixed.sh` replays every old exploit step and expects it to fail, then checks the container settings.

## Residual risks (not fixed by this package)
- **No TLS.** For a real public site, put it behind an AWS load balancer or CloudFront with a certificate, or use Caddy/Let's Encrypt.
- **Apache's master process runs as root inside the container** (workers run as `www-data`), as in the stock image. Capabilities are dropped and the filesystem is read-only, which limits the impact. Moving to a non-root image is the next hardening step.
- **No rate limiting or WAF.** Consider AWS WAF, or fail2ban on the host.
- **Base image patching.** Rebuild regularly: `docker compose build --pull && docker compose up -d`.
- **Contact form** does not store or send anything. If it later does, add CSRF protection, validation and output escaping.
