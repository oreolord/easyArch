#!/bin/bash
start="n"
while [ "$start" != "y" ]
do
    lsblk
    echo "Which drive would you like to install on?"
    read drive
    type=""
    gpubrand=""
    cpubrand=""
    booter=""

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
    select optionc in "Grub" "Systemd"; do
        case $optionc in
            "Grub")
                booter="Grub"
                break
                ;;
            "Systemd")
                booter="Systemd"
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
    echo "|   CPU: $cpubrand      | Hostname: $hostname   |"
    echo "|   GPU: $gpubrand      | Username: $username  |"
    echo "|   Boot: $booter    | Password: $password   |"
    echo "|   Drive: $drive     | Rootpswd: $rootpw     |"
    echo "|   Type: $type     |                      |"
    echo "Are these settings correct? y/n"
    read start
done
parted /dev/$drive mklabel gpt
(
echo n # Add a new partition
echo   # Partition number
echo   # First sector (Accept default: 1)
echo +512M # Last sector (Accept default: varies)
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
) | fdisk /dev/$drive
if [ "$type" = "SATA" ]; then
    mkfs.fat -F32 /dev/$drive\1
    mkswap /dev/$drive\2
    mkfs.ext4 /dev/$drive\3
    swapon /dev/$drive\2
    mount /dev/$drive\3 /mnt
    mkdir /mnt/boot
    mount /dev/$drive\1 /mnt/boot
elif [ "$type" = "NVME" ]; then
    mkfs.fat -F32 /dev/$drive\p1
    mkswap /dev/$drive\p2
    mkfs.ext4 /dev/$drive\p3
    swapon /dev/$drive\p2
    mount /dev/$drive\p3 /mnt
    mkdir /mnt/boot
    mount /dev/$drive\p1 /mnt/boot
fi
if [ "$cpubrand" = "Intel" ]; then
    pacstrap -K /mnt base base-devel linux linux-firmware git curl intel-ucode nano bash-completion networkmanager linux-headers
elif [ "$cpubrand" = "AMD" ]; then
    pacstrap -K /mnt base base-devel linux linux-firmware git curl amd-ucode nano bash-completion networkmanager linux-headers
else
    pacstrap -K /mnt base base-devel linux linux-firmware git curl nano bash-completion networkmanager linux-headers
fi
genfstab -U /mnt >> /mnt/etc/fstab
cp -R easyarch /mnt/easyarch
chmod +x /mnt/easyarch/chroot.sh
export username
export booter
export gpubrand
export type
export rootpw
export password
arch-chroot /mnt ./easyarch/chroot.sh
