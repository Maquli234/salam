#!/usr/bin/env bash
# Retest: every old exploit step must now FAIL. Run as root on the Docker host.
set -uo pipefail
BASE=${BASE:-http://127.0.0.1}
FAILED=0
ok(){ echo "PASS  $1"; }
bad(){ echo "FAIL  $1"; FAILED=1; }
code(){ curl -s -o /dev/null -w '%{http_code}' "$@"; }

[[ $(code "$BASE/") == 200 ]] && ok "site works (home 200)" || bad "site does not load"
[[ $(code "$BASE/index.php?page=about") == 200 ]] && ok "normal navigation works" || bad "navigation broken"

for P in '../../../../etc/passwd' '....//....//....//....//etc/passwd' \
         '%2e%2e%2f%2e%2e%2fetc/passwd' '/etc/passwd' \
         'php://filter/convert.base64-encode/resource=index.php' 'data://text/plain;base64,PD9waHAgcGhwaW5mbygpOz8+'; do
  OUT=$(curl -s -G "$BASE/index.php" --data-urlencode "page=$P")
  if echo "$OUT" | grep -q 'root:x:0:0\|PD9waHA\|phpinfo'; then bad "LFI payload leaked data: $P"; else ok "LFI payload rejected: $P"; fi
done

# Log poisoning chain
curl -s -o /dev/null -A "<?php system(\$_GET['c']); ?>" "$BASE/"
OUT=$(curl -s -G "$BASE/index.php" --data-urlencode 'page=....//....//....//....//var/log/apache2/access.log' --data-urlencode 'c=id')
echo "$OUT" | grep -q 'uid=' && bad "log poisoning gives code execution" || ok "log poisoning no longer works"

for U in /backup/old-notes.txt /robots.txt /routes.php /includes/header.php /app/routes.php /.git/config; do
  [[ $(code "$BASE$U") == 404 ]] && ok "not exposed: $U" || bad "reachable: $U"
done

HDR=$(curl -sI "$BASE/")
echo "$HDR" | grep -qi '^server: Apache/[0-9]' && bad "Apache version disclosed" || ok "no server version banner"
echo "$HDR" | grep -qi 'x-powered-by' && bad "X-Powered-By disclosed" || ok "no X-Powered-By"
echo "$HDR" | grep -qi 'x-content-type-options: nosniff' && ok "security headers present" || bad "security headers missing"
[[ $(code -X TRACE "$BASE/") =~ ^(403|405)$ ]] && ok "TRACE blocked" || bad "TRACE allowed"

# Container checks
C=tidewater
docker exec $C sh -c 'test ! -e /var/run/docker.sock' && ok "no docker socket in the container" || bad "docker socket present"
docker exec $C sh -c 'command -v docker python3 sudo nano >/dev/null 2>&1' && bad "extra tools installed in the container" || ok "no docker/python/sudo in the container"
docker exec $C sh -c 'getent passwd marcus' >/dev/null 2>&1 && bad "marcus account exists" || ok "no marcus account"
[[ $(docker inspect -f '{{.HostConfig.ReadonlyRootfs}}' $C) == true ]] && ok "read-only root filesystem" || bad "root filesystem is writable"
[[ $(docker inspect -f '{{.HostConfig.Privileged}}' $C) == false ]] && ok "not privileged" || bad "privileged"
docker inspect -f '{{.HostConfig.CapDrop}}' $C | grep -qi 'all' && ok "capabilities dropped" || bad "capabilities not dropped"
docker inspect -f '{{range .Mounts}}{{.Source}} {{end}}' $C | grep -q 'docker.sock' && bad "docker.sock mounted" || ok "no host mounts"
docker exec $C sh -c 'env | grep -qi "flag\|DEV_PASS\|PASSWORD"' && bad "secrets in the environment" || ok "no secrets in the environment"

echo
[[ $FAILED -eq 0 ]] && echo "All checks passed." || echo "Some checks failed - see above."
exit $FAILED
