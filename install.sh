#!/bin/bash

set_drive_vars() {
    if [ "$2" == "SATA" ]; then
        bootpar="$1""1"
        swappar="$1""2"
        rootpar="$1""3"
    else
        bootpar="$1""p1"
        swappar="$1""p2"
        rootpar="$1""p3"
    fi
}

install_linux() {
    if [ "$1" = "Intel" ]; then
        pacstrap -K /mnt base base-devel linux linux-firmware git curl intel-ucode nano bash-completion networkmanager linux-headers os-prober
    elif [ "$1" = "AMD" ]; then
        pacstrap -K /mnt base base-devel linux linux-firmware git curl amd-ucode nano bash-completion networkmanager linux-headers os-prober
    else
        pacstrap -K /mnt base base-devel linux linux-firmware git curl nano bash-completion networkmanager linux-headers os-prober
    fi
}

# Ask system specs
start="n"
while [ "$start" != "y" ]
do
    lsblk
    echo "Which drive would you like to install on?"
    read drivetemp
    drive="/dev/$drivetemp"
    type=""
    gpubrand=""
    cpubrand=""
    booter=""
    desktop=""
    
    if [[ "${drive:0:3}" == "nvm" ]]; then
        type="NVME"
    else
        type="SATA"
    fi
    PS3="What is your CPU brand? "
    select optiona in "Intel" "AMD"; do
        case $optiona in
            "Intel")
                cpubrand="Intel"
                break
                ;;
            "AMD")
                cpubrand="AMD"
                break
                ;;
        esac
    done
    PS3="What is your GPU brand? "
    select optionb in "NVIDIA" "AMD"; do
        case $optionb in
            "NVIDIA")
                gpubrand="NVIDIA"
                break
                ;;
            "AMD")
                gpubrand="AMD"
                break
                ;;
        esac
    done
    PS3="Pick a bootloader: "
    select optionc in "Grub (recommended)" "Systemd (faster)"; do
        case $optionc in
            "Grub (recommended)")
                booter="Grub"
                break
                ;;
            "Systemd (faster)")
                booter="Systemd"
                break
                ;;
        esac
    done
    PS3="Pick a desktop: "
    select optiond in "KDE" "GNOME" "Minimal"; do
        case $optiond in
            "KDE")
                desktop="kde"
                break
                ;;
            "GNOME")
                desktop="gnome"
                break
                ;;
            "Minimal")
                desktop="minimal"
                break
                ;;
        esac
    done
    PS3="Pick an AUR helper: "
    select optione in "paru" "yay"; do
        case $optione in
            "paru")
                aurhelper="paru"
                break
                ;;
            "yay")
                aurhelper="yay"
                break
                ;;
        esac
    done
    echo "Please type your desired hostname:"
    read hostname
    echo "Please type your desired username:"
    read username
    echo "Please type your desired password:"
    read password
    echo "Please type your desired root password:"
    read rootpw
    echo "Selected options:"
    echo "|       System       |        Users       |"
    echo "-------------------------------------------"
    echo "   CPU: $cpubrand      | Hostname: $hostname   "
    echo "   GPU: $gpubrand      | Username: $username  "
    echo "   Boot: $booter    | Password: $password   "
    echo "   Drive: $drivetemp     | Rootpswd: $rootpw     "
    echo "   AUR: $aurhelper     | Desktop: $desktop  "
    echo "Are these settings correct? y/n"
    read start
done

# Wipe and partition drive
parted $drive mklabel gpt
(
echo n # Add a new partition
echo   # Partition number
echo   # First sector
echo +512M # Size
echo t # Change type
echo 1 # Efi system
echo n
echo
echo
echo +8G
echo t
echo 2
echo 19
echo n
echo
echo
echo
echo w
) | fdisk $drive

# Set drive variables for easy formatting
set_drive_vars $drive $type

# Format and mount partitions
mkfs.fat -F32 $bootpar
mkswap $swappar
mkfs.ext4 $rootpar
swapon $swappar
mount $rootpar /mnt
mount -m $bootpar /mnt/boot

# Rate mirrors
reflector --verbose --country 'United States' -l 5 --sort rate --save /etc/pacman.d/mirrorlist

# Install linux
install_linux $cpubrand
genfstab -U /mnt >> /mnt/etc/fstab

# Set up and start chroot script
cp -R easyarch/chroot /mnt/easyarch
chmod +x /mnt/easyarch/chroot.sh

# Export environment variables for chroot use
export username
export booter
export gpubrand
export type
export rootpw
export password
export hostname
export desktop
export rootpar
export aurhelper
arch-chroot /mnt ./easyarch/chroot.sh
