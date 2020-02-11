#!/usr/bin/env bash
set -e
#PARTITION_BOOT_NUMBER=0
LOG_FILE="alis.log"
echo -e "Welcome to Arch Media Server Install Script"
read -p "Do you want to continue? [y/N] " yn
case $yn in
[Yy]* )
;;
[Nn]* )
exit
;;
* )
exit
;;
esac
clear
echo -e "These are the available storage devices"
echo "..."
df
echo -e "..."
echo -e "Enter target storage device for arch media server install - This drive will be formatted!"
read devname
DEVICE="/dev/$devname"
echo -e "..."
echo -e "Enter desired host name for arch media server"
read hostinput
HOSTNAME="$hostinput"
echo -e "..."
echo -e "Enter user name for arch media server primary user - pwd will be archlinux"
read usernameinput
ROOT_PASSWORD="archlinux"
ROOT_PASSWORD_RETYPE="archlinux"
USER_NAME="$usernameinput"
USER_PASSWORD="archlinux"
USER_PASSWORD_RETYPE="archlinux"
echo ...
KEYS="uk"
LOG="false"
DEVICE_TRIM="true" # If DEVICE supports TRIM
PARTITION_ROOT_ENCRYPTION_PASSWORD=""
PARTITION_ROOT_ENCRYPTION_PASSWORD_RETYPE=""
FILE_SYSTEM_TYPE="ext4"
SWAP_SIZE="!GiB"
PING_HOSTNAME="mirrors.kernel.org"
PACMAN_MIRROR="https://mirrors.kernel.org/archlinux/\$repo/os/\$arch"
TIMEZONE="/usr/share/zoneinfo/Europe/London"
LOCALE="en_GB.UTF-8 UTF-8"
LANG="LANG=en_GB.UTF-8"
LANGUAGE="LANGUAGE=en_GB:en"
KEYMAP="KEYMAP=uk"
BOOTLOADER="grub"
DESKTOP_ENVIRONMENT="gnome"
DISPLAY_DRIVER="intel"
KMS="false"
DISPLAY_DRIVER_DDX="false"
VULKAN="false"
DISPLAY_DRIVER_HARDWARE_ACCELERATION="false"
DISPLAY_DRIVER_HARDWARE_ACCELERATION_INTEL="libva-intel-driver"
PACKAGES_PACMAN="firefox curl wget openssh gimp blender gnome-initial-setup dosfstools ntfs-3g exfat-utils kcalc python git xorg nano python2-mako emby-server samba apache
AUR="yay"
PACKAGES_AUR="xrdp-git xrdb sickchill-git radarr deluge-git wine"
set -o xtrace
if [ -d /sys/firmware/efi ]; then
BIOS_TYPE="uefi"
else
BIOS_TYPE="bios"
fi
ASCIINEMA="false"
DEVICE_SATA="false"
DEVICE_NVME="false"
DEVICE_MMC="false"
if [ -n "$(echo $DEVICE | grep "^/dev/[a-z]d[a-z]")" ]; then
DEVICE_SATA="true"
elif [ -n "$(echo $DEVICE | grep "^/dev/nvme")" ]; then
DEVICE_NVME="true"
elif [ -n "$(echo $DEVICE | grep "^/dev/mmc")" ]; then
DEVICE_MMC="true"
fi
if [ -n "$(lscpu | grep GenuineIntel)" ]; then
CPU_INTEL="true"
fi
timedatectl set-ntp true
if [ -d /mnt/boot ]; then
umount /mnt/boot
umount /mnt
fi
partprobe $DEVICE
ping -c 5 $PING_HOSTNAME
if [ $? -ne 0 ]; then
exit
fi
sgdisk --zap-all $DEVICE
wipefs -a $DEVICE
if [ "$BIOS_TYPE" == "uefi" ]; then
if [ "$DEVICE_SATA" == "true" ]; then
PARTITION_BOOT="${DEVICE}1"
PARTITION_ROOT="${DEVICE}2"
#PARTITION_BOOT_NUMBER=1
DEVICE_ROOT="${DEVICE}2"
fi
if [ "$DEVICE_NVME" == "true" ]; then
PARTITION_BOOT="${DEVICE}p1"
PARTITION_ROOT="${DEVICE}p2"
#PARTITION_BOOT_NUMBER=1
DEVICE_ROOT="${DEVICE}p2"
fi
parted -s $DEVICE mklabel gpt mkpart primary fat32 1MiB 512MiB mkpart primary $FILE_SYSTEM_TYPE 512MiB 100% set 1 boot on
sgdisk -t=1:ef00 $DEVICE
if [ "$LVM" == "true" ]; then
sgdisk -t=2:8e00 $DEVICE
fi
fi
if [ "$BIOS_TYPE" == "bios" ]; then
if [ "$DEVICE_SATA" == "true" ]; then
PARTITION_BIOS="${DEVICE}1"
PARTITION_BOOT="${DEVICE}2"
PARTITION_ROOT="${DEVICE}3"
#PARTITION_BOOT_NUMBER=2
DEVICE_ROOT="${DEVICE}3"
fi
if [ "$DEVICE_NVME" == "true" ]; then
PARTITION_BIOS="${DEVICE}p1"
PARTITION_BOOT="${DEVICE}p2"
PARTITION_ROOT="${DEVICE}p3"
#PARTITION_BOOT_NUMBER=2
DEVICE_ROOT="${DEVICE}p3"
fi
parted -s $DEVICE mklabel gpt mkpart primary fat32 1MiB 128MiB mkpart primary $FILE_SYSTEM_TYPE 128MiB 512MiB mkpart primary $FILE_SYSTEM_TYPE 512MiB 100% set 1 boot on
sgdisk -t=1:ef02 $DEVICE
if [ "$LVM" == "true" ]; then
sgdisk -t=3:8e00 $DEVICE
fi
fi
if [ -n "$PARTITION_ROOT_ENCRYPTION_PASSWORD" ]; then
LVM_DEVICE="/dev/mapper/$LVM_VOLUME_PHISICAL"
else
LVM_DEVICE="$PARTITION_ROOT"
fi
if [ -n "$PARTITION_ROOT_ENCRYPTION_PASSWORD" ]; then
echo -n "$PARTITION_ROOT_ENCRYPTION_PASSWORD" | cryptsetup --key-size=512 --key-file=- luksFormat --type luks2 $PARTITION_ROOT
echo -n "$PARTITION_ROOT_ENCRYPTION_PASSWORD" | cryptsetup --key-file=- open $PARTITION_ROOT $LVM_VOLUME_PHISICAL
sleep 5
fi
if [ "$BIOS_TYPE" == "uefi" ]; then
wipefs -a $PARTITION_BOOT
wipefs -a $DEVICE_ROOT
mkfs.fat -n ESP -F32 $PARTITION_BOOT
mkfs."$FILE_SYSTEM_TYPE" -L root $DEVICE_ROOT
fi
if [ "$BIOS_TYPE" == "bios" ]; then
wipefs -a $PARTITION_BIOS
wipefs -a $PARTITION_BOOT
wipefs -a $DEVICE_ROOT
mkfs.fat -n BIOS -F32 $PARTITION_BIOS
mkfs."$FILE_SYSTEM_TYPE" -L boot $PARTITION_BOOT
mkfs."$FILE_SYSTEM_TYPE" -L root $DEVICE_ROOT
fi
PARTITION_OPTIONS=""
if [ "$DEVICE_TRIM" == "true" ]; then
PARTITION_OPTIONS="defaults,noatime"
fi
mount -o "$PARTITION_OPTIONS" "$DEVICE_ROOT" /mnt
mkdir /mnt/boot
mount -o "$PARTITION_OPTIONS" "$PARTITION_BOOT" /mnt/boot
if [ -n "$SWAP_SIZE" -a "$FILE_SYSTEM_TYPE" != "btrfs" ]; then
fallocate -l $SWAP_SIZE /mnt/swap
chmod 600 /mnt/swap
mkswap /mnt/swap
fi
BOOT_DIRECTORY=/boot
ESP_DIRECTORY=/boot
UUID_BOOT=$(blkid -s UUID -o value $PARTITION_BOOT)
UUID_ROOT=$(blkid -s UUID -o value $PARTITION_ROOT)
PARTUUID_BOOT=$(blkid -s PARTUUID -o value $PARTITION_BOOT)
PARTUUID_ROOT=$(blkid -s PARTUUID -o value $PARTITION_ROOT)
sed -i 's/#Color/Color/' /etc/pacman.conf
sed -i 's/#TotalDownload/TotalDownload/' /etc/pacman.conf
pacstrap /mnt base base-devel linux
sed -i 's/#Color/Color/' /mnt/etc/pacman.conf
sed -i 's/#TotalDownload/TotalDownload/' /mnt/etc/pacman.conf
pacman_install "linux-headers"
genfstab -U /mnt >> /mnt/etc/fstab
echo "/swap none swap defaults 0 0" >> /mnt/etc/fstab
echo "" >> /mnt/etc/fstab
sed -i 's/relatime/noatime/' /mnt/etc/fstab
arch-chroot /mnt systemctl enable fstrim.timer
arch-chroot /mnt ln -s -f $TIMEZONE /etc/localtime
arch-chroot /mnt hwclock --systohc
sed -i "s/#$LOCALE/$LOCALE/" /mnt/etc/locale.gen
arch-chroot /mnt locale-gen
echo -e "$LANG\n$LANGUAGE" > /mnt/etc/locale.conf
echo -e "$KEYMAP\n$FONT\n$FONT_MAP" > /mnt/etc/vconsole.conf
echo $HOSTNAME > /mnt/etc/hostname
if [ -n "$SWAP_SIZE" ]; then
echo "vm.swappiness=10" > /mnt/etc/sysctl.d/99-sysctl.conf
fi
printf "$ROOT_PASSWORD\n$ROOT_PASSWORD" | arch-chroot /mnt passwd
pacman_install "networkmanager"
arch-chroot /mnt systemctl enable NetworkManager.service
arch-chroot /mnt sed -i "s/MODULES=i915/" /etc/mkinitcpio.conf
arch-chroot /mnt sed -i 's/ filesystems / lvm2 filesystems /' /etc/mkinitcpio.conf
elif [ -n "$PARTITION_ROOT_ENCRYPTION_PASSWORD" ]; then
arch-chroot /mnt sed -i 's/ block / block keyboard keymap /' /etc/mkinitcpio.conf
arch-chroot /mnt sed -i 's/ filesystems keyboard / encrypt filesystems /' /etc/mkinitcpio.conf
arch-chroot /mnt mkinitcpio -P
BOOTLOADER_ALLOW_DISCARDS=""
CMDLINE_LINUX_ROOT="root=PARTUUID=$PARTUUID_ROOT"
BOOTLOADER_ALLOW_DISCARDS=":allow-discards"
CMDLINE_LINUX="cryptdevice=PARTUUID=$PARTUUID_ROOT:$LVM_VOLUME_PHISICAL$BOOTLOADER_ALLOW_DISCARDS"
pacman_install "grub dosfstools"
arch-chroot /mnt sed -i 's/GRUB_DEFAULT=0/GRUB_DEFAULT=saved/' /etc/default/grub
arch-chroot /mnt sed -i 's/#GRUB_SAVEDEFAULT="true"/GRUB_SAVEDEFAULT="true"/' /etc/default/grub
arch-chroot /mnt sed -i -E "s/GRUB_CMDLINE_LINUX_DEFAULT="(.*) quiet"/GRUB_CMDLINE_LINUX_DEFAULT="\1"/" /etc/default/grub
arch-chroot /mnt sed -i 's/GRUB_CMDLINE_LINUX=""/GRUB_CMDLINE_LINUX="'$CMDLINE_LINUX'"/' /etc/default/grub
echo "" >> /mnt/etc/default/grub
echo "# alis" >> /mnt/etc/default/grub
echo "GRUB_DISABLE_SUBMENU=y" >> /mnt/etc/default/grub
function refind() {
pacman_install "refind-efi"
arch-chroot /mnt refind-install
arch-chroot /mnt rm /boot/refind_linux.conf
arch-chroot /mnt sed -i 's/^timeout.*/timeout 5/' "$ESP_DIRECTORY/EFI/refind/refind.conf"
arch-chroot /mnt sed -i 's/^#scan_all_linux_kernels.*/scan_all_linux_kernels false/' "$ESP_DIRECTORY/EFI/refind/refind.conf"
#arch-chroot /mnt sed -i 's/^#default_selection "+,bzImage,vmlinuz"/default_selection "+,bzImage,vmlinuz"/' "$ESP_DIRECTORY/EFI/refind/refind.conf"
echo "" >> "/mnt$ESP_DIRECTORY/EFI/refind/refind.conf"
echo "# alis" >> "/mnt$ESP_DIRECTORY/EFI/refind/refind.conf"
echo "menuentry \"Arch Linux\" {" >> "/mnt$ESP_DIRECTORY/EFI/refind/refind.conf"
echo "volume   $PARTUUID_BOOT" >> "/mnt$ESP_DIRECTORY/EFI/refind/refind.conf"
echo "loader   /vmlinuz-linux" >> "/mnt$ESP_DIRECTORY/EFI/refind/refind.conf"
echo "initrd   /initramfs-linux.img" >> "/mnt$ESP_DIRECTORY/EFI/refind/refind.conf"
echo "icon /EFI/refind/icons/os_arch.png" >> "/mnt$ESP_DIRECTORY/EFI/refind/refind.conf"
echo "options  \"$REFIND_MICROCODE $CMDLINE_LINUX_ROOT rw $CMDLINE_LINUX\"" >> "/mnt$ESP_DIRECTORY/EFI/refind/refind.conf"
echo "submenuentry \"Boot using fallback initramfs\" {" >> "/mnt$ESP_DIRECTORY/EFI/refind/refind.conf"
echo "	  initrd /initramfs-linux-fallback.img" >> "/mnt$ESP_DIRECTORY/EFI/refind/refind.conf"
echo "}" >> "/mnt$ESP_DIRECTORY/EFI/refind/refind.conf"
echo "submenuentry \"Boot to terminal\" {" >> "/mnt$ESP_DIRECTORY/EFI/refind/refind.conf"
echo "	  add_options \"systemd.unit=multi-user.target\"" >> "/mnt$ESP_DIRECTORY/EFI/refind/refind.conf"
echo "}" >> "/mnt$ESP_DIRECTORY/EFI/refind/refind.conf"
echo "}" >> "/mnt$ESP_DIRECTORY/EFI/refind/refind.conf"
echo "" >> "/mnt$ESP_DIRECTORY/EFI/refind/refind.conf"
arch-chroot /mnt bootctl --path="$ESP_DIRECTORY" install
arch-chroot /mnt mkdir -p "$ESP_DIRECTORY/loader/"
arch-chroot /mnt mkdir -p "$ESP_DIRECTORY/loader/entries/"
echo "# alis" > "/mnt$ESP_DIRECTORY/loader/loader.conf"
echo "timeout 5" >> "/mnt$ESP_DIRECTORY/loader/loader.conf"
echo "default archlinux" >> "/mnt$ESP_DIRECTORY/loader/loader.conf"
echo "editor 0" >> "/mnt$ESP_DIRECTORY/loader/loader.conf"
arch-chroot /mnt mkdir -p "/etc/pacman.d/hooks/"
echo "[Trigger]" >> /mnt/etc/pacman.d/hooks/systemd-boot.hook
echo "Type = Package" >> /mnt/etc/pacman.d/hooks/systemd-boot.hook
echo "Operation = Upgrade" >> /mnt/etc/pacman.d/hooks/systemd-boot.hook
echo "Target = systemd" >> /mnt/etc/pacman.d/hooks/systemd-boot.hook
echo "" >> /mnt/etc/pacman.d/hooks/systemd-boot.hook
echo "[Action]" >> /mnt/etc/pacman.d/hooks/systemd-boot.hook
echo "Description = Updating systemd-boot..." >> /mnt/etc/pacman.d/hooks/systemd-boot.hook
echo "When = PostTransaction" >> /mnt/etc/pacman.d/hooks/systemd-boot.hook
echo "Exec = /usr/bin/bootctl update" >> /mnt/etc/pacman.d/hooks/systemd-boot.hook
SYSTEMD_MICROCODE="/intel-ucode.img"
echo "title Arch Media Server" >> "/mnt$ESP_DIRECTORY/loader/entries/archlinux.conf"
echo "efi /vmlinuz-linux" >> "/mnt$ESP_DIRECTORY/loader/entries/archlinux.conf"
echo "initrd $SYSTEMD_MICROCODE" >> "/mnt$ESP_DIRECTORY/loader/entries/archlinux.conf"
echo "initrd /initramfs-linux.img" >> "/mnt$ESP_DIRECTORY/loader/entries/archlinux.conf"
echo "options initrd=initramfs-linux.img $CMDLINE_LINUX_ROOT rw $CMDLINE_LINUX $SYSTEMD_OPTIONS" >> "/mnt$ESP_DIRECTORY/loader/entries/archlinux.conf"
echo "initrd $SYSTEMD_MICROCODE" >> "/mnt$ESP_DIRECTORY/loader/entries/archlinux.conf"
create_user $USER_NAME $USER_PASSWORD
arch-chroot /mnt sed -i 's/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers
USER_NAME=$1
USER_PASSWORD=$2
arch-chroot /mnt useradd -m -G wheel,storage,optical -s /bin/bash $USER_NAME
printf "$USER_PASSWORD\n$USER_PASSWORD" | arch-chroot /mnt passwd $USER_NAME
pacman_install "xdg-user-dirs"
pacman_install "xfce4 xfce4-goodies lightdm lightdm-gtk-greeter"
arch-chroot /mnt systemctl enable lightdm.service

pacman_install "$PACKAGES_PACMAN"
pacman_install "git"
arch-chroot /mnt sed -i 's/%wheel ALL=(ALL) ALL/%wheel ALL=(ALL) NOPASSWD: ALL/' /etc/sudoers
arch-chroot /mnt bash -c "echo -e \"$USER_PASSWORD\n$USER_PASSWORD\n$USER_PASSWORD\n$USER_PASSWORD\n\"" | su $USER_NAME -c \"cd /home/$USER_NAME && git clone https://aur.archlinux.org/yay.git && (cd yay && makepkg -si --noconfirm) && rm -rf yay\""
arch-chroot /mnt sed -i 's/%wheel ALL=(ALL) NOPASSWD: ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers
aur_install $PACKAGES_AUR


function terminate() {
done
}

function pacman_install() {
PACKAGES=$PACKAGES_PACMAN
for VARIABLE in {1..5}
do
arch-chroot /mnt pacman -Syu --noconfirm --needed $PACKAGES
if [ $? == 0 ]; then
break
else
sleep 10
fi
done
}
