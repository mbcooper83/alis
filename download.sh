#!/usr/bin/env bash
set -e

rm /etc/pacman.d/mirrorlist
echo 'Server=https://mirrors.nix.org.ua/linux/archlinux/$repo/os/$arch' > /etc/pacman.d/mirrorlist
pacman -Sy --noconfirm wget nano git

rm -f alis.conf
rm -f alis.sh
rm -f alis-asciinema.sh
rm -f alis-reboot.sh

rm -f alis-recovery.conf
rm -f alis-recovery.sh
rm -f alis-recovery-asciinema.sh
rm -f alis-recovery-reboot.sh

wget https://raw.githubusercontent.com/mbcooper83/alis/master/alis.conf
wget https://raw.githubusercontent.com/mbcooper83/alis/master/alis.sh
wget https://raw.githubusercontent.com/mbcooper83/alis/master/alis-asciinema.sh
wget https://raw.githubusercontent.com/mbcooper83/alis/master/alis-reboot.sh

wget https://raw.githubusercontent.com/mbcooper83/alis/master/alis-recovery.conf
wget https://raw.githubusercontent.com/mbcooper83/alis/master/alis-recovery.sh
wget https://raw.githubusercontent.com/mbcooper83/alis/master/alis-recovery-asciinema.sh
wget https://raw.githubusercontent.com/mbcooper83/alis/master/alis-recovery-reboot.sh

chmod +x alis.sh
chmod +x alis-asciinema.sh
chmod +x alis-reboot.sh

chmod +x alis-recovery.sh
chmod +x alis-recovery-asciinema.sh
chmod +x alis-recovery-reboot.sh
