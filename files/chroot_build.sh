#!/bin/bash

set -eu -o pipefail

echo >&2 "===]> Info: Configure environment... "

mount none -t proc /proc
mount none -t sysfs /sys
mount none -t devpts /dev/pts

export HOME=/root
export LC_ALL=C

echo >&2 "===]> Info: Upgrade the system... "

apt-get update
export DEBIAN_FRONTEND=noninteractive
#apt-get upgrade -y -qq -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"

echo >&2 "===]> Info: Install Ubuntu MBP Repo... "

apt-get install -y systemd-sysv gnupg curl wget

mkdir -p /etc/apt/sources.list.d
curl -s --compressed "https://adityagarg8.github.io/t2-ubuntu-repo/KEY.gpg" | gpg --dearmor | tee /etc/apt/trusted.gpg.d/t2-ubuntu-repo.gpg >/dev/null
curl -s --compressed -o /etc/apt/sources.list.d/t2.list "https://adityagarg8.github.io/t2-ubuntu-repo/t2.list"
echo "deb [signed-by=/etc/apt/trusted.gpg.d/t2-ubuntu-repo.gpg] https://github.com/AdityaGarg8/t2-ubuntu-repo/releases/download/${CODENAME} ./" | tee -a /etc/apt/sources.list.d/t2.list
apt-get update

echo >&2 "===]> Info: Install the T2 kernel... "

apt-get install -y -qq -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" \
  linux-t2=KVER-PREL-${CODENAME}

echo >&2 "===]> Info: Install sound configuration and Wi-Fi script... "

apt-get install -y -qq -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" \
  apple-t2-audio-config \
  apple-firmware-script

echo >&2 "===]> Info: Configure drivers... "

printf 'apple-bce' >>/etc/modules-load.d/t2.conf

echo >&2 "===]> Info: Update initramfs... "

## Add custom drivers to be loaded at boot
/usr/sbin/depmod -a "${KERNEL_VERSION}"
update-initramfs -u -v -k "${KERNEL_VERSION}"

apt-get autoremove -y

echo >&2 "===]> Info: Add udev Rule for AMD GPU Power Management... "
cat <<EOF > /etc/udev/rules.d/30-amdgpu-pm.rules
KERNEL=="card[012]", SUBSYSTEM=="drm", DRIVERS=="amdgpu", ATTR{device/power_dpm_force_performance_level}="low"
EOF

echo >&2 "===]> Info: Cleanup the chroot environment... "

truncate -s 0 /etc/machine-id || true
rm /sbin/initctl || true
dpkg-divert --rename --remove /sbin/initctl || true
apt-get clean || true
rm -rf /tmp/* ~/.bash_history || true
rm -rf /tmp/setup_files || true

umount -lf /dev/pts
umount -lf /sys
umount -lf /proc

export HISTSIZE=0
