#!/bin/bash

sudo pacman -Sy --noconfirm --needed nano
sudo pacman -Sy --noconfirm --needed openssh
sudo pacman -Sy --noconfirm --needed python2-mako
sudo pacman -Sy --noconfirm --needed emby-server

yay -Sy
yay -S --noconfirm xorgxrdp-git
yay -S --noconfirm xorg-xrdb
yay -S --noconfirm teamviewer
yay -S --noconfirm sickchill-git
yay -S --noconfirm sonarr
yay -S --noconfirm deluge-git
yay -S --noconfirm samba
yay -S --noconfirm apache

sudo systemctl enable sshd
sudo systemctl enable xrdp
sudo systemctl enable xrdp-sesman
sudo systemctl enable teamviewerd
sudo systemctl enable deluged
sudo systemctl enable deluge-web
sudo systemctl enable sickchill
sudo systemctl enable emby-server
sudo systemctl enable sonarr
sudo systemctl enable httpd

rm  ~/.Xresources-xrdp
echo "Xcursor.core:1" > ~/.Xresources-xrdp
rm ~/.xinitrc
echo "xrdb ~/.Xresources-xrdp" >> ~/.xinitrc
echo "exec startxfce4" >> ~/.xinitrc
sudo rm /etc/samba/smb.conf
sudo wget -O /etc/samba/smb.conf https://raw.githubusercontent.com/mbcooper83/alis/master/smb.conf
sudo wget -O /srv/http/index.html https://raw.githubusercontent.com/mbcooper83/alis/master/index.html
mkdir /mnt/mediashare
sudo chmod -R 0777 /mnt/mediashare
sudo smbpasswd -a mrv

read -p "Post-Build Script Complete - Press any key to exit"
sudo shutdown -r now
