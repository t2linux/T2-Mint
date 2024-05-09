#!/bin/bash
set -eu -o pipefail

ROOT_PATH=$(pwd)
WORKING_PATH=/root/work
CHROOT_PATH="${WORKING_PATH}/chroot"
IMAGE_PATH="${WORKING_PATH}/image"
CODENAME=jammy
FLAVOUR=$1
MINT_VERSION=21.3
KERNEL_VERSION=6.8.9
PKGREL=1
sed -i "s/KVER/${KERNEL_VERSION}/g" $(pwd)/files/chroot_build.sh
sed -i "s/PREL/${PKGREL}/g" $(pwd)/files/chroot_build.sh

if [ -d "$WORKING_PATH" ]; then
  rm -rf "$WORKING_PATH"
fi
mkdir -p "$WORKING_PATH"
if [ -d "${ROOT_PATH}/output" ]; then
  rm -rf "${ROOT_PATH}/output"
fi
mkdir -p "${ROOT_PATH}/output"

echo >&2 "===]> Info: Build dependencies... "
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y -qq -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" \
  binutils \
  debootstrap \
  squashfs-tools \
  xorriso \
  grub-pc-bin \
  grub-efi-amd64-bin \
  mtools \
  dosfstools \
  zip \
  isolinux \
  syslinux \
  wget

echo >&2 "===]> Info: Start loop... "
for ALTERNATIVE in t2-jammy
do
  echo >&2 "===]> Info: Start building ${ALTERNATIVE}... "

  echo >&2 "===]> Info: Build Filesystem from official ISO... "
  /bin/bash -c "
    ROOT_PATH=${ROOT_PATH} \\
    WORKING_PATH=${WORKING_PATH} \\
    CHROOT_PATH=${CHROOT_PATH}_${ALTERNATIVE} \\
    IMAGE_PATH=${IMAGE_PATH} \\
    KERNEL_VERSION=${KERNEL_VERSION}-${ALTERNATIVE} \\
    ALTERNATIVE=${ALTERNATIVE} \\
    CODENAME=${CODENAME} \\
    MINT_VERSION=${MINT_VERSION} \\
    FLAVOUR=${FLAVOUR} \\
    ${ROOT_PATH}/01_build_file_system.sh
  "

  echo >&2 "===]> Info: Build Image from modified Filesystem... "
  /bin/bash -c "
    ROOT_PATH=${ROOT_PATH} \\
    WORKING_PATH=${WORKING_PATH} \\
    CHROOT_PATH=${CHROOT_PATH}_${ALTERNATIVE} \\
    IMAGE_PATH=${IMAGE_PATH} \\
    KERNEL_VERSION=${KERNEL_VERSION}-${ALTERNATIVE} \\
    ALTERNATIVE=${ALTERNATIVE} \\
    CODENAME=${CODENAME} \\
    MINT_VERSION=${MINT_VERSION} \\
    FLAVOUR=${FLAVOUR} \\
    ${ROOT_PATH}/02_build_image.sh
  "

  echo >&2 "===]> Info: Prepare Boot for ISO... "
  /bin/bash -c "
    IMAGE_PATH=${IMAGE_PATH} \\
    CHROOT_PATH=${CHROOT_PATH}_${ALTERNATIVE} \\
    CODENAME=${CODENAME} \\
    MINT_VERSION=${MINT_VERSION} \\
    FLAVOUR=${FLAVOUR} \\
    ${ROOT_PATH}/03_prepare_iso.sh
  "

  echo >&2 "===]> Info: Create ISO... "
  /bin/bash -c "
    ROOT_PATH=${ROOT_PATH} \\
    IMAGE_PATH=${IMAGE_PATH} \\
    CHROOT_PATH=${CHROOT_PATH}_${ALTERNATIVE} \\
    KERNEL_VERSION=${KERNEL_VERSION}-${ALTERNATIVE} \\
    ALTERNATIVE=${ALTERNATIVE} \\
    CODENAME=${CODENAME} \\
    MINT_VERSION=${MINT_VERSION} \\
    FLAVOUR=${FLAVOUR} \\
    ${ROOT_PATH}/04_create_iso.sh
  "
  livecd_exitcode=$?
  if [ "${livecd_exitcode}" -ne 0 ]; then
    echo "Error building ${KERNEL_VERSION}-${ALTERNATIVE}"
    exit "${livecd_exitcode}"
  fi
  ## Zip iso and split it into multiple parts - github max size of release attachment is 2GB, where ISO is sometimes bigger than that
  cd "${ROOT_PATH}"
  zip -s 1500m "${ROOT_PATH}/output/linuxmint-${MINT_VERSION}-${FLAVOUR}-${KERNEL_VERSION}-${ALTERNATIVE}.zip" "${ROOT_PATH}/linuxmint-${MINT_VERSION}-${FLAVOUR}-${KERNEL_VERSION}-${ALTERNATIVE}.iso"
done
## Calculate sha256 sums of built ISO
sha256sum "${ROOT_PATH}"/*.iso >"${ROOT_PATH}/output/sha256-linuxmint-${MINT_VERSION}-${FLAVOUR}"

find ./ | grep ".iso"
find ./ | grep ".zip"

exit "${livecd_exitcode}"
