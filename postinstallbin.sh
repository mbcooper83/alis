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
echo "X11 Wrapper Config File"
sudo rm /etc/X11/Xwrapper.config
sudo echo "allowed_users=anybody" > /etc/X11/Xwrapper.config
echo "Configure Xinitrc for XFCE4"
rm  ~/.Xresources-xrdp
echo "Xcursor.core:1" > ~/.Xresources-xrdp
rm ~/.xinitrc
echo "xrdb ~/.Xresources-xrdp" >> ~/.xinitrc
echo "exec startxfce4" >> ~/.xinitrc
su root
rm /etc/samba/smb.conf
wget -O /etc/samba/smb.conf https://raw.githubusercontent.com/mbcooper83/alis/master/smb.conf
mkdir /mnt/mediashare
chmod -R 0777 /mnt/mediashare
"Set Samba Passwords"
smbpasswd -a mrv
smbpasswd -a noone
systemctl enable smb
su mrv
sudo systemctl enable sshd
sudo systemctl enable xrdp
sudo systemctl enable xrdp-sesman
sudo systemctl enable teamviewerd
sudo systemctl enable deluged
sudo systemctl enable deluge-web
sudo systemctl enable sickchill
sudo systemctl enable emby-server
sudo systemctl enable sonarr
echo ""
echo "#############################################"
echo "DONE!"
echo "#############################################"
echo ""
read -p "Post-Build Script Complete - Press any key to exit"

