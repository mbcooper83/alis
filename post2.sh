#!/bin/bash
arch-chroot /mnt systemctl enable sshd
arch-chroot /mnt systemctl enable xrdp
arch-chroot /mnt systemctl enable xrdp-sesman
arch-chroot /mnt systemctl enable teamviewerd
arch-chroot /mnt systemctl enable deluged
arch-chroot /mnt systemctl enable deluge-web
arch-chroot /mnt systemctl enable sickchill
arch-chroot /mnt systemctl enable emby-server
arch-chroot /mnt systemctl enable radarr
arch-chroot /mnt systemctl enable httpd
arch-chroot /mnt smbpasswd -a mrv
arch-chroot /mnt rm /etc/X11/Xwrapper.config
arch-chroot /mnt echo "allowed_users=anybody" > /etc/X11/Xwrapper.config
arch-chroot /mnt rm  ~/.Xresources-xrdp
arch-chroot /mnt echo "Xcursor.core:1" > ~/.Xresources-xrdp
arch-chroot /mnt rm ~/.xinitrc
arch-chroot /mnt echo "xrdb ~/.Xresources-xrdp" >> ~/.xinitrc
arch-chroot /mnt echo "exec startxfce4" >> ~/.xinitrc
arch-chroot /mnt rm /etc/samba/smb.conf
arch-chroot /mnt wget -O /etc/samba/smb.conf https://raw.githubusercontent.com/mbcooper83/alis/master/smb.conf
arch-chroot /mnt wget -O /srv/http/index.html https://raw.githubusercontent.com/mbcooper83/alis/master/index.html
arch-chroot /mnt mkdir /mnt/5tbsidk
arch-chroot /mnt chmod -R 0777 /mnt/5tbdisk
arch-chroot /mnt wget https://raw.githubusercontent.com/mbcooper83/alis/master/configfiles.tar.gz
arch-chroot /mnt tar xvzf configfiles.tar.gz
