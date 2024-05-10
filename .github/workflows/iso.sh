#!/bin/bash

os=$(uname -s)
case "$os" in
	(Darwin)
		true
		;;
	(Linux)
		true
		;;
	(*)
		echo "This script is meant to be run only on Linux or macOS"
		exit 1
		;;
esac

echo -e "GET http://github.com HTTP/1.0\n\n" | nc github.com 80 > /dev/null 2>&1

if [ $? -eq 0 ]; then
    true
else
    echo "Please connect to the internet"
    exit 1
fi

set -e

cd $HOME/Downloads

latest=$(curl -sL https://github.com/t2linux/T2-Mint/releases/latest/ | grep "<title>Release" | awk -F " " '{print $2}' )
latestkver=$(echo $latest | cut -d "v" -f 2 | cut -d "-" -f 1)

cat <<EOF

Choose the flavour of Linux Mint you wish to install:

1. Cinnamon
2. Xfce
3. MATE

Type your choice (1,2 or 3) from the above list and press return.
EOF

read flavinput

case "$flavinput" in
	(1)
		flavour=cinnamon
  		flavourcap=Cinnamon
		;;
	(2)
		flavour=xfce
		flavourcap=Xfce
		;;
	(3)
		flavour=mate
    	flavourcap=MATE
		;;
	(*)
		echo "Invalid input. Aborting!"
		exit 1
		;;
esac

iso="linuxmint-21.3-${flavour}-${latestkver}-t2-jammy"
ver="Linux Mint 21.3 \"Virginia\" - ${flavourcap} Edition"

if [ ! -f ${iso}.z01 ]; then
	echo -e "\nDownloading Part 1 for ${ver}"
	echo -e "\n"
	curl -#L https://github.com/t2linux/T2-Mint/releases/download/${latest}/${iso}.z01 > ${iso}.z01
fi
if [ ! -f ${iso}.zip ]; then
	echo -e "\nDownloading Part 2 for ${ver}"
	echo -e "\n"
	curl -#L https://github.com/t2linux/T2-Mint/releases/download/${latest}/${iso}.zip > ${iso}.zip
fi
echo -e "\nCreating ISO"

isofinal=$RANDOM
zip -F ${iso}.zip --out ${isofinal}.zip > /dev/null
unzip ${isofinal}.zip > /dev/null
mv $HOME/Downloads/home/runner/work/T2-Mint/T2-Mint/${iso}.iso $HOME/Downloads

echo -e "\nVerifying sha256 checksums"

actual_iso_chksum=$(curl -sL https://github.com/t2linux/T2-Mint/releases/download/${latest}/sha256-${flavour} | cut -d " " -f 1)

case "$os" in
	(Darwin)
		downloaded_iso_chksum=$(shasum -a 256 $HOME/Downloads/${iso}.iso | cut -d " " -f 1)
		;;
	(Linux)
		downloaded_iso_chksum=$(sha256sum $HOME/Downloads/${iso}.iso | cut -d " " -f 1)
		;;
	(*)
		echo "This script is meant to be run only on Linux or macOS"
		exit 1
		;;
esac

if [[ ${actual_iso_chksum} != ${downloaded_iso_chksum} ]]
then
echo -e "\nError: Failed to verify sha256 checksums of the ISO"
rm $HOME/Downloads/${iso}.iso
fi

rm -r $HOME/Downloads/home
rm $HOME/Downloads/${isofinal}.zip
rm $HOME/Downloads/${iso}.z??

if [[ ${actual_iso_chksum} != ${downloaded_iso_chksum} ]]
then
exit 1
fi

echo -e "\nISO saved to Downloads"
