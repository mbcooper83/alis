#!/bin/bash

sudo rm /etc/X11/Xwrapper.config
sudo echo "allowed_users=anybody" > /etc/X11/Xwrapper.config
rm  ~/.Xresources-xrdp
echo "Xcursor.core:1" > ~/.Xresources-xrdp
rm ~/.xinitrc
echo "xrdb ~/.Xresources-xrdp" >> ~/.xinitrc
echo "exec startxfce4" >> ~/.xinitrc
sudo rm /etc/samba/smb.conf
sudo wget -O /etc/samba/smb.conf https://raw.githubusercontent.com/mbcooper83/alis/master/smb.conf
sudo wget -O /srv/http/index.html https://raw.githubusercontent.com/mbcooper83/alis/master/index.html
mkdir /mnt/5tbsidk
sudo chmod -R 0777 /mnt/5tbdisk
sudo smbpasswd -a mrv

sudo systemctl enable sshd
sudo systemctl enable xrdp
sudo systemctl enable xrdp-sesman
sudo systemctl enable teamviewerd
sudo systemctl enable deluged
sudo systemctl enable deluge-web
sudo systemctl enable sickchill
sudo systemctl enable emby-server
sudo systemctl enable radarr
sudo systemctl enable httpd

read -p "Post-Build Script Complete - Press any key to exit"
sudo shutdown -r now


