#!/usr/bin/env bash
set -e
echo "hello"
#PARTITION_BOOT_NUMBER=0
CONF_FILE="alis.conf"
LOG_FILE="alis.log"
RED='\033[0;31m'
GREEN='\033[0;32m'
LIGHT_BLUE='\033[1;34m'
NC='\033[0m'

function configuration_install() {
clear
echo These are the available storage devices
echo ...
df
echo ...
echo "Enter target storage device for arch media server install - This drive will be formatted!"
read devname
DEVICE="/dev/$devname"
echo ...
echo "Enter desired host name for arch media server"
read hostinput
HOSTNAME="$hostinput"
echo ...
echo "Enter user name for arch media server primary user - pwd will be archlinux"
read usernameinput
ROOT_PASSWORD="archlinux" # Root user password. Warning: change it!
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
# packages
PACKAGES_PACMAN="firefox curl wget openssh gimp blender gnome-initial-setup dosfstools ntfs-3g exfat-utils kcalc python git xorg nano python2-mako emby-server samba apache
AUR="yay !aurman"
PACKAGES_AUR="yay xorgxrdp-git xorg-xrdb sickchill-git radarr deluge-git wine"
}

function sanitize_variable() {
    VARIABLE=$1
    VARIABLE=$(echo $VARIABLE | sed "s/![^ ]*//g") # remove disabled
    VARIABLE=$(echo $VARIABLE | sed "s/ {2,}/ /g") # remove unnecessary white spaces
    VARIABLE=$(echo $VARIABLE | sed 's/^[[:space:]]*//') # trim leading
    VARIABLE=$(echo $VARIABLE | sed 's/[[:space:]]*$//') # trim trailing
    echo "$VARIABLE"
}

function check_variables() {
    check_variables_value "KEYS" "$KEYS"
    check_variables_boolean "LOG" "$LOG"
    check_variables_value "DEVICE" "$DEVICE"
    check_variables_boolean "LVM" "$LVM"
    check_variables_equals "PARTITION_ROOT_ENCRYPTION_PASSWORD" "PARTITION_ROOT_ENCRYPTION_PASSWORD_RETYPE" "$PARTITION_ROOT_ENCRYPTION_PASSWORD" "$PARTITION_ROOT_ENCRYPTION_PASSWORD_RETYPE"
    check_variables_list "FILE_SYSTEM_TYPE" "$FILE_SYSTEM_TYPE" "ext4 btrfs xfs"
    check_variables_value "PING_HOSTNAME" "$PING_HOSTNAME"
    check_variables_value "PACMAN_MIRROR" "$PACMAN_MIRROR"
    check_variables_list "KERNELS" "$KERNELS" "linux-lts linux-lts-headers linux-hardened linux-hardened-headers linux-zen linux-zen-headers" "false"
    check_variables_list "KERNELS_COMPRESSION" "$KERNELS_COMPRESSION" "gzip bzip2 lzma xz lzop lz4" "false"
    check_variables_value "TIMEZONE" "$TIMEZONE"
    check_variables_value "LOCALE" "$LOCALE"
    check_variables_value "LANG" "$LANG"
    check_variables_value "KEYMAP" "$KEYMAP"
    check_variables_value "HOSTNAME" "$HOSTNAME"
    check_variables_value "USER_NAME" "$USER_NAME"
    check_variables_value "USER_PASSWORD" "$USER_PASSWORD"
    check_variables_equals "ROOT_PASSWORD" "ROOT_PASSWORD_RETYPE" "$ROOT_PASSWORD" "$ROOT_PASSWORD_RETYPE"
    check_variables_equals "USER_PASSWORD" "USER_PASSWORD_RETYPE" "$USER_PASSWORD" "$USER_PASSWORD_RETYPE"
    check_variables_list "BOOTLOADER" "$BOOTLOADER" "grub refind systemd"
    check_variables_list "DESKTOP_ENVIRONMENT" "$DESKTOP_ENVIRONMENT" "gnome kde xfce mate cinnamon lxde" "false"
    check_variables_list "DISPLAY_DRIVER" "$DISPLAY_DRIVER" "intel amdgpu ati nvidia nvidia-lts nvidia-dkms nvidia-390xx nvidia-390xx-lts nvidia-390xx-dkms nouveau" "false"
    check_variables_boolean "KMS" "$KMS"
    check_variables_boolean "DISPLAY_DRIVER_DDX" "$DISPLAY_DRIVER_DDX"
    check_variables_boolean "DISPLAY_DRIVER_HARDWARE_ACCELERATION" "$DISPLAY_DRIVER_HARDWARE_ACCELERATION"
    check_variables_list "DISPLAY_DRIVER_HARDWARE_ACCELERATION_INTEL" "$DISPLAY_DRIVER_HARDWARE_ACCELERATION_INTEL" "intel-media-driver libva-intel-driver" "false"
    check_variables_boolean "REBOOT" "$REBOOT"
}

function check_variables_value() {
    NAME=$1
    VALUE=$2
    if [ -z "$VALUE" ]; then
        echo "$NAME environment variable must have a value."
        exit
    fi
}

function check_variables_boolean() {
    NAME=$1
    VALUE=$2
    check_variables_list "$NAME" "$VALUE" "true false"
}

function check_variables_list() {
    NAME=$1
    VALUE=$2
    VALUES=$3
    REQUIRED=$4
    if [ "$REQUIRED" == "" -o "$REQUIRED" == "true" ]; then
        check_variables_value "$NAME" "$VALUE"
    fi

    if [ "$VALUE" != "" -a -z "$(echo "$VALUES" | grep -F -w "$VALUE")" ]; then
        echo "$NAME environment variable value [$VALUE] must be in [$VALUES]."
        exit
    fi
}

function check_variables_equals() {
    NAME1=$1
    NAME2=$2
    VALUE1=$3
    VALUE2=$4
    if [ "$VALUE1" != "$VALUE2" ]; then
        echo "$NAME1 and $NAME2 must be equal [$VALUE1, $VALUE2]."
        exit
    fi
}

function check_variables_size() {
    NAME=$1
    SIZE_EXPECT=$2
    SIZE=$3
    if [ "$SIZE_EXPECT" != "$SIZE" ]; then
        echo "$NAME array size [$SIZE] must be [$SIZE_EXPECT]."
        exit
    fi
}

function warning() {
    echo -e "${LIGHT_BLUE}Welcome to Arch Linux Install Script${NC}"
    echo ""
    echo -e "${RED}Warning"'!'"${NC}"
    echo -e "${RED}This script deletes all partitions of the persistent${NC}"
    echo -e "${RED}storage and continuing all your data in it will be lost.${NC}"
    echo ""
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
}

function init() {
init_log
loadkeys $KEYS
}

function init_log() {
    if [ "$LOG" == "true" ]; then
        exec > >(tee -a $LOG_FILE)
        exec 2> >(tee -a $LOG_FILE >&2)
    fi
    set -o xtrace
}

function facts() {
    echo ""
    echo -e "${LIGHT_BLUE}# facts() step${NC}"
    echo ""

    if [ -d /sys/firmware/efi ]; then
        BIOS_TYPE="uefi"
    else
        BIOS_TYPE="bios"
    fi

    if [ -f "$ASCIINEMA_FILE" ]; then
        ASCIINEMA="true"
    else
        ASCIINEMA="false"
    fi

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

    if [ -n "$(lspci | grep -i virtualbox)" ]; then
        VIRTUALBOX="true"
    fi
}

function check_facts() {
    if [ "$BOOTLOADER" == "refind" ]; then
        check_variables_list "BIOS_TYPE" "$BIOS_TYPE" "uefi"
    fi
    if [ "$BOOTLOADER" == "systemd" ]; then
        check_variables_list "BIOS_TYPE" "$BIOS_TYPE" "uefi"
    fi
}

function prepare() {
    echo ""
    echo -e "${LIGHT_BLUE}# prepare() step${NC}"
    echo ""

    configure_time
    prepare_partition
    configure_network
}

function configure_time() {
    timedatectl set-ntp true
}

function prepare_partition() {
    if [ -d /mnt/boot ]; then
        umount /mnt/boot
        umount /mnt
    fi
    if [ -e "/dev/mapper/$LVM_VOLUME_LOGICAL" ]; then
        if [ -n "$PARTITION_ROOT_ENCRYPTION_PASSWORD" ]; then
            cryptsetup close $LVM_VOLUME_LOGICAL
        fi
    fi
    if [ -e "/dev/mapper/$LVM_VOLUME_PHISICAL" ]; then
        lvremove --force "$LVM_VOLUME_GROUP-$LVM_VOLUME_LOGICAL"
        vgremove --force "/dev/mapper/$LVM_VOLUME_GROUP"
        pvremove "/dev/mapper/$LVM_VOLUME_PHISICAL"
        if [ -n "$PARTITION_ROOT_ENCRYPTION_PASSWORD" ]; then
            cryptsetup close $LVM_VOLUME_PHISICAL
        fi
    fi
    partprobe $DEVICE
}

function configure_network() {
    if [ -n "$WIFI_INTERFACE" ]; then
        cp /etc/netctl/examples/wireless-wpa /etc/netctl
        chmod 600 /etc/netctl/wireless-wpa

        sed -i 's/^Interface=.*/Interface='"$WIFI_INTERFACE"'/' /etc/netctl/wireless-wpa
        sed -i 's/^ESSID=.*/ESSID='"$WIFI_ESSID"'/' /etc/netctl/wireless-wpa
        sed -i 's/^Key=.*/Key='"$WIFI_KEY"'/' /etc/netctl/wireless-wpa
        if [ "$WIFI_HIDDEN" == "true" ]; then
            sed -i 's/^#Hidden=.*/Hidden=yes/' /etc/netctl/wireless-wpa
        fi

        netctl stop-all
        netctl start wireless-wpa
        sleep 10
    fi

    ping -c 5 $PING_HOSTNAME
    if [ $? -ne 0 ]; then
        echo "Network ping check failed. Cannot continue."
        exit
    fi
}

function partition() {
    echo ""
    echo -e "${LIGHT_BLUE}# partition() step${NC}"
    echo ""

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
}

function install() {
    echo ""
    echo -e "${LIGHT_BLUE}# install() step${NC}"
    echo ""

    if [ -n "$PACMAN_MIRROR" ]; then
        echo "Server=$PACMAN_MIRROR" > /etc/pacman.d/mirrorlist
    fi
    sed -i 's/#Color/Color/' /etc/pacman.conf
    sed -i 's/#TotalDownload/TotalDownload/' /etc/pacman.conf

    pacstrap /mnt base base-devel linux

    sed -i 's/#Color/Color/' /mnt/etc/pacman.conf
    sed -i 's/#TotalDownload/TotalDownload/' /mnt/etc/pacman.conf
}

function kernels() {
    echo ""
    echo -e "${LIGHT_BLUE}# kernels() step${NC}"
    echo ""

    pacman_install "linux-headers"
    if [ -n "$KERNELS" ]; then
        pacman_install "$KERNELS"
    fi
}

function configuration() {
    echo ""
    echo -e "${LIGHT_BLUE}# configuration() step${NC}"
    echo ""

    genfstab -U /mnt >> /mnt/etc/fstab

    if [ -n "$SWAP_SIZE" -a "$FILE_SYSTEM_TYPE" != "btrfs" ]; then
        echo "# swap" >> /mnt/etc/fstab
        echo "/swap none swap defaults 0 0" >> /mnt/etc/fstab
        echo "" >> /mnt/etc/fstab
    fi

    if [ "$DEVICE_TRIM" == "true" ]; then
        sed -i 's/relatime/noatime/' /mnt/etc/fstab
        arch-chroot /mnt systemctl enable fstrim.timer
    fi

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
}

function network() {
    echo ""
    echo -e "${LIGHT_BLUE}# network() step${NC}"
    echo ""

    pacman_install "networkmanager"
    arch-chroot /mnt systemctl enable NetworkManager.service
}

function virtualbox() {
    echo ""
    echo -e "${LIGHT_BLUE}# virtualbox() step${NC}"
    echo ""

    if [ -z "$KERNELS" ]; then
        pacman_install "virtualbox-guest-utils virtualbox-guest-modules-arch"
    else
        pacman_install "virtualbox-guest-utils virtualbox-guest-dkms"
    fi
}

function mkinitcpio() {
    echo ""
    echo -e "${LIGHT_BLUE}# mkinitcpio() step${NC}"
    echo ""

    if [ "$KMS" == "true" ]; then
        MODULES=""
        case "$DISPLAY_DRIVER" in
            "intel" )
                MODULES="i915"
                ;;
            "nvidia" | "nvidia-lts"  | "nvidia-dkms" | "nvidia-390xx" | "nvidia-390xx-lts" | "nvidia-390xx-dkms" )
                MODULES="nvidia nvidia_modeset nvidia_uvm nvidia_drm"
                ;;
            "amdgpu" )
                MODULES="amdgpu"
                ;;
            "ati" )
                MODULES="radeon"
                ;;
            "nouveau" )
                MODULES="nouveau"
                ;;
        esac
        arch-chroot /mnt sed -i "s/MODULES=()/MODULES=($MODULES)/" /etc/mkinitcpio.conf
    fi

    if [ "$LVM" == "true" ]; then
        pacman_install "lvm2"
    fi

    if [ "$LVM" == "true" -a -n "$PARTITION_ROOT_ENCRYPTION_PASSWORD" ]; then
        arch-chroot /mnt sed -i 's/ block / block keyboard keymap /' /etc/mkinitcpio.conf
        arch-chroot /mnt sed -i 's/ filesystems keyboard / encrypt lvm2 filesystems /' /etc/mkinitcpio.conf
    elif [ "$LVM" == "true" ]; then
        arch-chroot /mnt sed -i 's/ filesystems / lvm2 filesystems /' /etc/mkinitcpio.conf
    elif [ -n "$PARTITION_ROOT_ENCRYPTION_PASSWORD" ]; then
        arch-chroot /mnt sed -i 's/ block / block keyboard keymap /' /etc/mkinitcpio.conf
        arch-chroot /mnt sed -i 's/ filesystems keyboard / encrypt filesystems /' /etc/mkinitcpio.conf
    fi

    if [ "$KERNELS_COMPRESSION" != "" ]; then
        arch-chroot /mnt sed -i "s/#COMPRESSION=\"$KERNELS_COMPRESSION\"/COMPRESSION=\"$KERNELS_COMPRESSION\"/" /etc/mkinitcpio.conf
    fi

    arch-chroot /mnt mkinitcpio -P
}

function bootloader() {
    echo ""
    echo -e "${LIGHT_BLUE}# bootloader() step${NC}"
    echo ""

    BOOTLOADER_ALLOW_DISCARDS=""

CMDLINE_LINUX_ROOT="root=PARTUUID=$PARTUUID_ROOT"
BOOTLOADER_ALLOW_DISCARDS=":allow-discards"
CMDLINE_LINUX="cryptdevice=PARTUUID=$PARTUUID_ROOT:$LVM_VOLUME_PHISICAL$BOOTLOADER_ALLOW_DISCARDS"

    case "$BOOTLOADER" in
        "grub" )
            grub
            ;;
        "refind" )
            refind
            ;;
        "systemd" )
            systemd
            ;;
    esac
}

function grub() {
    pacman_install "grub dosfstools"
    arch-chroot /mnt sed -i 's/GRUB_DEFAULT=0/GRUB_DEFAULT=saved/' /etc/default/grub
    arch-chroot /mnt sed -i 's/#GRUB_SAVEDEFAULT="true"/GRUB_SAVEDEFAULT="true"/' /etc/default/grub
    arch-chroot /mnt sed -i -E 's/GRUB_CMDLINE_LINUX_DEFAULT="(.*) quiet"/GRUB_CMDLINE_LINUX_DEFAULT="\1"/' /etc/default/grub
    arch-chroot /mnt sed -i 's/GRUB_CMDLINE_LINUX=""/GRUB_CMDLINE_LINUX="'$CMDLINE_LINUX'"/' /etc/default/grub
    echo "" >> /mnt/etc/default/grub
    echo "# alis" >> /mnt/etc/default/grub
    echo "GRUB_DISABLE_SUBMENU=y" >> /mnt/etc/default/grub

pacman_install "efibootmgr"
arch-chroot /mnt grub-install --target=x86_64-efi --bootloader-id=grub --efi-directory=$ESP_DIRECTORY --recheck
#arch-chroot /mnt efibootmgr --create --disk $DEVICE --part $PARTITION_BOOT_NUMBER --loader /EFI/grub/grubx64.efi --label "GRUB Boot Manager"
arch-chroot /mnt grub-mkconfig -o "$BOOT_DIRECTORY/grub/grub.cfg"
}

function refind() {
    pacman_install "refind-efi"
    arch-chroot /mnt refind-install

    arch-chroot /mnt rm /boot/refind_linux.conf
    arch-chroot /mnt sed -i 's/^timeout.*/timeout 5/' "$ESP_DIRECTORY/EFI/refind/refind.conf"
    arch-chroot /mnt sed -i 's/^#scan_all_linux_kernels.*/scan_all_linux_kernels false/' "$ESP_DIRECTORY/EFI/refind/refind.conf"

    #arch-chroot /mnt sed -i 's/^#default_selection "+,bzImage,vmlinuz"/default_selection "+,bzImage,vmlinuz"/' "$ESP_DIRECTORY/EFI/refind/refind.conf"

    REFIND_MICROCODE=""

    echo "" >> "/mnt$ESP_DIRECTORY/EFI/refind/refind.conf"
    echo "# alis" >> "/mnt$ESP_DIRECTORY/EFI/refind/refind.conf"
    echo "menuentry \"Arch Linux\" {" >> "/mnt$ESP_DIRECTORY/EFI/refind/refind.conf"
    echo "    volume   $PARTUUID_BOOT" >> "/mnt$ESP_DIRECTORY/EFI/refind/refind.conf"
    echo "    loader   /vmlinuz-linux" >> "/mnt$ESP_DIRECTORY/EFI/refind/refind.conf"
    echo "    initrd   /initramfs-linux.img" >> "/mnt$ESP_DIRECTORY/EFI/refind/refind.conf"
    echo "    icon     /EFI/refind/icons/os_arch.png" >> "/mnt$ESP_DIRECTORY/EFI/refind/refind.conf"
    echo "    options  \"$REFIND_MICROCODE $CMDLINE_LINUX_ROOT rw $CMDLINE_LINUX\"" >> "/mnt$ESP_DIRECTORY/EFI/refind/refind.conf"
    echo "    submenuentry \"Boot using fallback initramfs\" {" >> "/mnt$ESP_DIRECTORY/EFI/refind/refind.conf"
    echo "	      initrd /initramfs-linux-fallback.img" >> "/mnt$ESP_DIRECTORY/EFI/refind/refind.conf"
    echo "    }" >> "/mnt$ESP_DIRECTORY/EFI/refind/refind.conf"
    echo "    submenuentry \"Boot to terminal\" {" >> "/mnt$ESP_DIRECTORY/EFI/refind/refind.conf"
    echo "	      add_options \"systemd.unit=multi-user.target\"" >> "/mnt$ESP_DIRECTORY/EFI/refind/refind.conf"
    echo "    }" >> "/mnt$ESP_DIRECTORY/EFI/refind/refind.conf"
    echo "}" >> "/mnt$ESP_DIRECTORY/EFI/refind/refind.conf"
    echo "" >> "/mnt$ESP_DIRECTORY/EFI/refind/refind.conf"
    if [[ $KERNELS =~ .*linux-lts.* ]]; then
        echo "menuentry \"Arch Linux (lts)\" {" >> "/mnt$ESP_DIRECTORY/EFI/refind/refind.conf"
        echo "    volume   $PARTUUID_BOOT" >> "/mnt$ESP_DIRECTORY/EFI/refind/refind.conf"
        echo "    loader   /vmlinuz-linux-lts" >> "/mnt$ESP_DIRECTORY/EFI/refind/refind.conf"
        echo "    initrd   /initramfs-linux-lts.img" >> "/mnt$ESP_DIRECTORY/EFI/refind/refind.conf"
        echo "    icon     /EFI/refind/icons/os_arch.png" >> "/mnt$ESP_DIRECTORY/EFI/refind/refind.conf"
        echo "    options  \"$REFIND_MICROCODE $CMDLINE_LINUX_ROOT rw $CMDLINE_LINUX\"" >> "/mnt$ESP_DIRECTORY/EFI/refind/refind.conf"
        echo "    submenuentry \"Boot using fallback initramfs\" {" >> "/mnt$ESP_DIRECTORY/EFI/refind/refind.conf"
        echo "	      initrd /initramfs-linux-lts-fallback.img" >> "/mnt$ESP_DIRECTORY/EFI/refind/refind.conf"
        echo "    }" >> "/mnt$ESP_DIRECTORY/EFI/refind/refind.conf"
        echo "    submenuentry \"Boot to terminal\" {" >> "/mnt$ESP_DIRECTORY/EFI/refind/refind.conf"
        echo "	      add_options \"systemd.unit=multi-user.target\"" >> "/mnt$ESP_DIRECTORY/EFI/refind/refind.conf"
        echo "    }" >> "/mnt$ESP_DIRECTORY/EFI/refind/refind.conf"
        echo "}" >> "/mnt$ESP_DIRECTORY/EFI/refind/refind.conf"
        echo "" >> "/mnt$ESP_DIRECTORY/EFI/refind/refind.conf"
    fi
    if [[ $KERNELS =~ .*linux-hardened.* ]]; then
        echo "menuentry \"Arch Linux (hardened)\" {" >> "/mnt$ESP_DIRECTORY/EFI/refind/refind.conf"
        echo "    volume   $PARTUUID_BOOT" >> "/mnt$ESP_DIRECTORY/EFI/refind/refind.conf"
        echo "    loader   /vmlinuz-linux-hardened" >> "/mnt$ESP_DIRECTORY/EFI/refind/refind.conf"
        echo "    initrd   /initramfs-linux-hardened.img" >> "/mnt$ESP_DIRECTORY/EFI/refind/refind.conf"
        echo "    icon     /EFI/refind/icons/os_arch.png" >> "/mnt$ESP_DIRECTORY/EFI/refind/refind.conf"
        echo "    options  \"$REFIND_MICROCODE $CMDLINE_LINUX_ROOT rw $CMDLINE_LINUX\"" >> "/mnt$ESP_DIRECTORY/EFI/refind/refind.conf"
        echo "    submenuentry \"Boot using fallback initramfs\" {" >> "/mnt$ESP_DIRECTORY/EFI/refind/refind.conf"
        echo "	      initrd /initramfs-linux-hardened-fallback.img" >> "/mnt$ESP_DIRECTORY/EFI/refind/refind.conf"
        echo "    }" >> "/mnt$ESP_DIRECTORY/EFI/refind/refind.conf"
        echo "    submenuentry \"Boot to terminal\" {" >> "/mnt$ESP_DIRECTORY/EFI/refind/refind.conf"
        echo "	      add_options \"systemd.unit=multi-user.target\"" >> "/mnt$ESP_DIRECTORY/EFI/refind/refind.conf"
        echo "    }" >> "/mnt$ESP_DIRECTORY/EFI/refind/refind.conf"
        echo "}" >> "/mnt$ESP_DIRECTORY/EFI/refind/refind.conf"
        echo "" >> "/mnt$ESP_DIRECTORY/EFI/refind/refind.conf"
    fi
    if [[ $KERNELS =~ .*linux-zen.* ]]; then
        echo "menuentry \"Arch Linux (zen)\" {" >> "/mnt$ESP_DIRECTORY/EFI/refind/refind.conf"
        echo "    volume   $PARTUUID_BOOT" >> "/mnt$ESP_DIRECTORY/EFI/refind/refind.conf"
        echo "    loader   /vmlinuz-linux-zen" >> "/mnt$ESP_DIRECTORY/EFI/refind/refind.conf"
        echo "    initrd   /initramfs-linux-zen.img" >> "/mnt$ESP_DIRECTORY/EFI/refind/refind.conf"
        echo "    icon     /EFI/refind/icons/os_arch.png" >> "/mnt$ESP_DIRECTORY/EFI/refind/refind.conf"
        echo "    options  \"$REFIND_MICROCODE $CMDLINE_LINUX_ROOT rw $CMDLINE_LINUX\"" >> "/mnt$ESP_DIRECTORY/EFI/refind/refind.conf"
        echo "    submenuentry \"Boot using fallback initramfs\" {" >> "/mnt$ESP_DIRECTORY/EFI/refind/refind.conf"
        echo "	      initrd /initramfs-linux-zen-fallback.img" >> "/mnt$ESP_DIRECTORY/EFI/refind/refind.conf"
        echo "    }" >> "/mnt$ESP_DIRECTORY/EFI/refind/refind.conf"
        echo "    submenuentry \"Boot to terminal\" {" >> "/mnt$ESP_DIRECTORY/EFI/refind/refind.conf"
        echo "	      add_options \"systemd.unit=multi-user.target\"" >> "/mnt$ESP_DIRECTORY/EFI/refind/refind.conf"
        echo "    }" >> "/mnt$ESP_DIRECTORY/EFI/refind/refind.conf"
        echo "}" >> "/mnt$ESP_DIRECTORY/EFI/refind/refind.conf"
        echo "" >> "/mnt$ESP_DIRECTORY/EFI/refind/refind.conf"
    fi

    if [ "$VIRTUALBOX" == "true" ]; then
        echo -n "\EFI\refind\refind_x64.efi" > "/mnt$ESP_DIRECTORY/startup.nsh"
    fi
}

function systemd() {
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

    SYSTEMD_MICROCODE=""
    SYSTEMD_OPTIONS=""

    if [ "$CPU_INTEL" == "true" -a "$VIRTUALBOX" != "true" ]; then
        SYSTEMD_MICROCODE="/intel-ucode.img"
    fi

    if [ -n "$PARTITION_ROOT_ENCRYPTION_PASSWORD" ]; then
       SYSTEMD_OPTIONS="rd.luks.options=discard"
    fi

    echo "title Arch Linux" >> "/mnt$ESP_DIRECTORY/loader/entries/archlinux.conf"
    echo "efi /vmlinuz-linux" >> "/mnt$ESP_DIRECTORY/loader/entries/archlinux.conf"
    if [ -n "$SYSTEMD_MICROCODE" ]; then
        echo "initrd $SYSTEMD_MICROCODE" >> "/mnt$ESP_DIRECTORY/loader/entries/archlinux.conf"
    fi
    echo "initrd /initramfs-linux.img" >> "/mnt$ESP_DIRECTORY/loader/entries/archlinux.conf"
    echo "options initrd=initramfs-linux.img $CMDLINE_LINUX_ROOT rw $CMDLINE_LINUX $SYSTEMD_OPTIONS" >> "/mnt$ESP_DIRECTORY/loader/entries/archlinux.conf"

    echo "title Arch Linux (fallback)" >> "/mnt$ESP_DIRECTORY/loader/entries/archlinux-fallback.conf"
    echo "efi /vmlinuz-linux" >> "/mnt$ESP_DIRECTORY/loader/entries/archlinux-fallback.conf"
    if [ -n "$SYSTEMD_MICROCODE" ]; then
        echo "initrd $SYSTEMD_MICROCODE" >> "/mnt$ESP_DIRECTORY/loader/entries/archlinux-fallback.conf"
    fi
    echo "initrd /initramfs-linux-fallback.img" >> "/mnt$ESP_DIRECTORY/loader/entries/archlinux-fallback.conf"
    echo "options initrd=initramfs-linux-fallback.img $CMDLINE_LINUX_ROOT rw $CMDLINE_LINUX $SYSTEMD_OPTIONS" >> "/mnt$ESP_DIRECTORY/loader/entries/archlinux-fallback.conf"

    if [[ $KERNELS =~ .*linux-lts.* ]]; then
        echo "title Arch Linux (lts)" >> "/mnt$ESP_DIRECTORY/loader/entries/archlinux-lts.conf"
        echo "efi /vmlinuz-linux-lts" >> "/mnt$ESP_DIRECTORY/loader/entries/archlinux-lts.conf"
        if [ -n "$SYSTEMD_MICROCODE" ]; then
            echo "initrd $SYSTEMD_MICROCODE" >> "/mnt$ESP_DIRECTORY/loader/entries/archlinux.conf"
        fi
        echo "initrd /initramfs-linux-lts.img" >> "/mnt$ESP_DIRECTORY/loader/entries/archlinux-lts.conf"
        echo "options initrd=initramfs-linux-lts.img $CMDLINE_LINUX_ROOT rw $CMDLINE_LINUX $SYSTEMD_OPTIONS" >> "/mnt$ESP_DIRECTORY/loader/entries/archlinux-lts.conf"

        echo "title Arch Linux (lts-fallback)" >> "/mnt$ESP_DIRECTORY/loader/entries/archlinux-lts-fallback.conf"
        echo "efi /vmlinuz-linux-lts" >> "/mnt$ESP_DIRECTORY/loader/entries/archlinux-lts-fallback.conf"
        if [ "$CPU_INTEL" == "true" -a "$VIRTUALBOX" != "true" ]; then
            echo "initrd $SYSTEMD_MICROCODE" >> "/mnt$ESP_DIRECTORY/loader/entries/archlinux-lts-fallback.conf"
        fi
        echo "initrd /initramfs-linux-lts-fallback.img" >> "/mnt$ESP_DIRECTORY/loader/entries/archlinux-lts-fallback.conf"
        echo "options initrd=initramfs-linux-lts-fallback.img $CMDLINE_LINUX_ROOT rw $CMDLINE_LINUX $SYSTEMD_OPTIONS" >> "/mnt$ESP_DIRECTORY/loader/entries/archlinux-lts-fallback.conf"
    fi

    if [[ $KERNELS =~ .*linux-hardened.* ]]; then
        echo "title Arch Linux (hardened)" >> "/mnt$ESP_DIRECTORY/loader/entries/archlinux-hardened.conf"
        echo "efi /vmlinuz-linux-hardened" >> "/mnt$ESP_DIRECTORY/loader/entries/archlinux-hardened.conf"
        if [ -n "$SYSTEMD_MICROCODE" ]; then
            echo "initrd $SYSTEMD_MICROCODE" >> "/mnt$ESP_DIRECTORY/loader/entries/archlinux.conf"
        fi
        echo "initrd /initramfs-linux-hardened.img" >> "/mnt$ESP_DIRECTORY/loader/entries/archlinux-hardened.conf"
        echo "options initrd=initramfs-linux-hardened.img $CMDLINE_LINUX_ROOT rw $CMDLINE_LINUX $SYSTEMD_OPTIONS" >> "/mnt$ESP_DIRECTORY/loader/entries/archlinux-hardened.conf"

        echo "title Arch Linux (hardened-fallback)" >> "/mnt$ESP_DIRECTORY/loader/entries/archlinux-hardened-fallback.conf"
        echo "efi /vmlinuz-linux-hardened" >> "/mnt$ESP_DIRECTORY/loader/entries/archlinux-hardened-fallback.conf"
        if [ -n "$SYSTEMD_MICROCODE" ]; then
            echo "initrd $SYSTEMD_MICROCODE" >> "/mnt$ESP_DIRECTORY/loader/entries/archlinux-hardened-fallback.conf"
        fi
        echo "initrd /initramfs-linux-hardened-fallback.img" >> "/mnt$ESP_DIRECTORY/loader/entries/archlinux-hardened-fallback.conf"
        echo "options initrd=initramfs-linux-hardened-fallback.img $CMDLINE_LINUX_ROOT rw $CMDLINE_LINUX $SYSTEMD_OPTIONS" >> "/mnt$ESP_DIRECTORY/loader/entries/archlinux-hardened-fallback.conf"
    fi

    if [[ $KERNELS =~ .*linux-zen.* ]]; then
        echo "title Arch Linux (zen)" >> "/mnt$ESP_DIRECTORY/loader/entries/archlinux-zen.conf"
        echo "efi /vmlinuz-linux-zen" >> "/mnt$ESP_DIRECTORY/loader/entries/archlinux-zen.conf"
        if [ -n "$SYSTEMD_MICROCODE" ]; then
            echo "initrd $SYSTEMD_MICROCODE" >> "/mnt$ESP_DIRECTORY/loader/entries/archlinux.conf"
        fi
        echo "initrd /initramfs-linux-zen.img" >> "/mnt$ESP_DIRECTORY/loader/entries/archlinux-zen.conf"
        echo "options initrd=initramfs-linux-zen.img $CMDLINE_LINUX_ROOT rw $CMDLINE_LINUX $SYSTEMD_OPTIONS" >> "/mnt$ESP_DIRECTORY/loader/entries/archlinux-zen.conf"

        echo "title Arch Linux (zen-fallback)" >> "/mnt$ESP_DIRECTORY/loader/entries/archlinux-zen-fallback.conf"
        echo "efi /vmlinuz-linux-zen" >> "/mnt$ESP_DIRECTORY/loader/entries/archlinux-zen-fallback.conf"
        if [ -n "$SYSTEMD_MICROCODE" ]; then
            echo "initrd $SYSTEMD_MICROCODE" >> "/mnt$ESP_DIRECTORY/loader/entries/archlinux-zen-fallback.conf"
        fi
        echo "initrd /initramfs-linux-zen-fallback.img" >> "/mnt$ESP_DIRECTORY/loader/entries/archlinux-zen-fallback.conf"
        echo "options initrd=initramfs-linux-zen-fallback.img $CMDLINE_LINUX_ROOT rw $CMDLINE_LINUX $SYSTEMD_OPTIONS" >> "/mnt$ESP_DIRECTORY/loader/entries/archlinux-zen-fallback.conf"
    fi

    if [ "$VIRTUALBOX" == "true" ]; then
        echo -n "\EFI\systemd\systemd-bootx64.efi" > "/mnt$ESP_DIRECTORY/startup.nsh"
    fi
}

function users() {
    create_user $USER_NAME $USER_PASSWORD

    for i in ${!ADDITIONAL_USER_NAMES_ARRAY[@]}; do
        create_user ${ADDITIONAL_USER_NAMES_ARRAY[$i]} ${ADDITIONAL_USER_PASSWORDS_ARRAY[$i]}
    done

	arch-chroot /mnt sed -i 's/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers
}

function create_user() {
    echo ""
    echo -e "${LIGHT_BLUE}# create_user() step${NC}"
    echo ""

    USER_NAME=$1
    USER_PASSWORD=$2
    arch-chroot /mnt useradd -m -G wheel,storage,optical -s /bin/bash $USER_NAME
    printf "$USER_PASSWORD\n$USER_PASSWORD" | arch-chroot /mnt passwd $USER_NAME

    pacman_install "xdg-user-dirs"
}

function desktop_environment() {
    echo ""
    echo -e "${LIGHT_BLUE}# desktop_environment() step${NC}"
    echo ""

pacman_install "mesa $PACKAGES_HARDWARE_ACCELERATION"
pacman_install "xfce4 xfce4-goodies lightdm lightdm-gtk-greeter"
arch-chroot /mnt systemctl enable lightdm.service


function packages() {
    echo ""
    echo -e "${LIGHT_BLUE}# packages() step${NC}"
    echo ""
pacman_install "$PACKAGES_PACMAN"
function packages_aur() {
pacman_install "git"
arch-chroot /mnt sed -i 's/%wheel ALL=(ALL) ALL/%wheel ALL=(ALL) NOPASSWD: ALL/' /etc/sudoers
arch-chroot /mnt bash -c "echo -e \"$USER_PASSWORD\n$USER_PASSWORD\n$USER_PASSWORD\n$USER_PASSWORD\n\" | su $USER_NAME -c \"cd /home/$USER_NAME && git clone https://aur.archlinux.org/yay.git && (cd yay && makepkg -si --noconfirm) && rm -rf yay\""
arch-chroot /mnt sed -i 's/%wheel ALL=(ALL) NOPASSWD: ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers
aur_install "$PACKAGES_AUR"
}

function terminate() {
    cp "$CONF_FILE" "/mnt/etc/$CONF_FILE"

    if [ "$LOG" == "true" ]; then
        mkdir -p /mnt/var/log
        cp "$LOG_FILE" "/mnt/var/log/$LOG_FILE"
    fi
    if [ "$ASCIINEMA" == "true" ]; then
        mkdir -p /mnt/var/log
        cp "$ASCIINEMA_FILE" "/mnt/var/log/$ASCIINEMA_FILE"
    fi
}

function end() {
            done
            set -e
        echo ""
        echo -e "${GREEN}Arch Media Server Installed Successfully"'!'"${NC}"
}

function pacman_install() {
    PACKAGES=$1
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

function aur_install() {
    PACKAGES=$1
    for VARIABLE in {1..5}
    do
        arch-chroot /mnt bash -c "echo -e \"$USER_PASSWORD\n$USER_PASSWORD\n$USER_PASSWORD\n$USER_PASSWORD\n\" | su $USER_NAME -c \"yay -Syu --noconfirm --needed $PACKAGES\""
        if [ $? == 0 ]; then
            break
        else
            sleep 10
        fi
    done
}

function main() {
    configuration_install
    sanitize_variables
    check_variables
    warning
    init
    facts
    check_facts
    prepare
    partition
    install
    kernels
    configuration
    network
    users
    mkinitcpio
    bootloader
    desktop_environment
    packages
    terminate
    end
}

echo "end"
main
