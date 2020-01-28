#!/bin/sh
echo "#############################################"
echo "      ARCH LINUX - POST INSTALL SCRIPT - MEDIA SERVER CONFIG"
echo "#############################################"
echo ""
read -p "Press ENTER to start"
echo ""
echo "#############################################"
echo "Install PACMAN Packages"
echo "#############################################"
sudo pacman -S nano
echo "Install Open SSHD"
sudo pacman -S openssh
echo "Install deluge"
sudo pacman -S deluge
echo "Install Python"
sudo pacman -S python2-mako
echo "Install Emby Server"
sudo pacman -S emby-server
echo "Install XorgRDP"
echo ""
echo "#############################################"
echo "Install YAY Packages"
echo "#############################################"
yay -Sy
yay -S xorgxrdp-git
yay -S xorg-xrdb
echo "Install Teamviewer"
yay -S teamviewer
echo "Install Sickchill"
yay -S sickchill-git
echo "Install Sonarr"
yay -S sonarr
echo ""
echo "#############################################"
echo "Write Config Files"
echo "#############################################"
echo "X11 Wrapper Config File"
sudo rm /etc/X11/Xwrapper.config
sudo echo "allowed_users=anybody" > /etc/X11/Xwrapper.config
echo "Configure Xinitrc for XFCE4"
rm  ~/.Xresources-xrdp
echo "Xcursor.core:1" > ~/.Xresources-xrdp
rm ~/.xinitrc
echo "xrdb ~/.Xresources-xrdp" >> ~/.xinitrc
echo "exec startxfce4" >> ~/.xinitrc
echo ""
echo "#############################################"
echo "Enable Services"
echo "#############################################"
sudo systemctl enable sshd
sudo systemctl enable xrdp
sudo systemctl enable xrdp-sesman
sudo systemctl enable teamviewerd
sudo systemctl enable teamviewerd
sudo systemctl enable deluged
sudo systemctl enable deluge-web
sudo systemctl enable sickchill
sudo systemctl enable emby-serversyste
sudo systemctl enable sonarr
echo ""
echo "#############################################"
echo "DONE!"
echo "#############################################"
echo ""
read -p "Post-Build Script Complete - Press any key to exit"
