#!/usr/bin/env bash
# Undo the lab-only weaknesses on the AWS host (find-only sudo, cron cleaner, password SSH, flags).
# Run from a root shell:  sudo -i  then  ./harden-host.sh
# SSH hardening is opt-in:  HARDEN_SSH=yes ./harden-host.sh   (only after key login is confirmed working)
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "Run as root."; exit 1; }
HARDEN_SSH="${HARDEN_SSH:-no}"
STAMP=$(date +%s)
cp /etc/sudoers /root/sudoers.$STAMP.bak

echo "[1/6] Restoring normal sudo for the administrator account"
if [[ -f /root/90-cloud-init-users.bak && ! -e /etc/sudoers.d/90-cloud-init-users ]]; then
  mv /root/90-cloud-init-users.bak /etc/sudoers.d/90-cloud-init-users
elif [[ ! -e /etc/sudoers.d/90-cloud-init-users ]]; then
  echo 'ubuntu ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/90-cloud-init-users
fi
chmod 0440 /etc/sudoers.d/90-cloud-init-users
rm -f /etc/sudoers.d/ubuntu-find
sed -i '/^%ubuntu ALL=(ALL) \/usr\/bin\/find/d' /etc/sudoers
sed -i 's|^#%admin ALL=(ALL) ALL|%admin ALL=(ALL) ALL|' /etc/sudoers
visudo -c || { echo "sudoers invalid - restoring backup"; cp /root/sudoers.$STAMP.bak /etc/sudoers; exit 1; }
echo "      ubuntu is the normal AWS admin again (key-only SSH, passwordless sudo)."
echo "      If you want no passwordless sudo, replace NOPASSWD:ALL in /etc/sudoers.d/90-cloud-init-users with ALL after setting a password."

echo "[2/6] Removing the log-cleaner job and script (no log file exists any more)"
rm -f /etc/cron.d/lab-logs /usr/local/bin/clean-lab-logs.sh
crontab -u ubuntu -r 2>/dev/null || true
(crontab -l 2>/dev/null | grep -v 'clean-lab-logs\|docker exec tidewater' || true) | crontab - 2>/dev/null || true

echo "[3/6] Removing lab flags from the host"
rm -f /root/root.txt

echo "[4/6] Making sure the admin account is not in the docker/lxd groups"
for g in docker lxd; do gpasswd -d ubuntu $g 2>/dev/null || true; done
id ubuntu

echo "[5/6] SSH"
if [[ "$HARDEN_SSH" == "yes" ]]; then
  rm -f /etc/ssh/sshd_config.d/01-password.conf
  cat > /etc/ssh/sshd_config.d/00-hardening.conf <<'SSH'
PasswordAuthentication no
PermitRootLogin no
MaxAuthTries 3
LoginGraceTime 20
X11Forwarding no
SSH
  sshd -t && systemctl reload ssh
  echo "      Password login disabled. Keep your current session open and test a new key login now."
else
  echo "      Skipped. Run again with HARDEN_SSH=yes once you have confirmed key login works."
fi

echo "[6/6] Summary"
sudo -l -U ubuntu | tail -3
ss -tlnp | grep -E ':(22|80) ' || true
cat <<'NOTE'

Manual follow-ups:
 - In the old project folder (tidewater-docker) delete .env and .author/  (they hold the old flags and passwords).
 - AWS security group: SSH (22) from your IP only; HTTP (80) can stay public now that the app is patched.
 - Rotate the ubuntu password if it was ever set: passwd -l ubuntu (key login keeps working).
NOTE
