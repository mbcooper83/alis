#! /bin/sh

echo "#############################################"
echo "      ARCH LINUX - POST INSTALL SCRIPT - MEDIA SERVER CONFIG"
echo "#############################################"
echo ""
read -p "Press any key to start"
echo ""
echo "#############################################"
echo "Install PACMAN Packages"
echo "#############################################"
yay -S --noconfirm nano
echo "Install Open SSHD"
yay -S --noconfirm openssh
echo "Install deluge"
yay -S --noconfirm deluge
echo "Install Python"
yay -S --noconfirm python2-mako
echo "Install Emby Server"
yay -S --noconfirm emby-server
echo "Install XorgRDP"
echo ""
echo "#############################################"
echo "Install YAY Packages"
echo "#############################################"
yay -Sy
yay -S --noconfirm xorgxrdp-git
yay -S --noconfirm xorg-xrdb
echo "Install Teamviewer"
yay -S --noconfirm teamviewer
echo "Install Sickchill"
yay -S --noconfirm sickchill-git
echo "Install Sonarr"
yay -S --noconfirm sonarr
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
