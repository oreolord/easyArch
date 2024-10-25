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
genfstab -U -p /mnt >> /mnt/etc/fstab
echo "( echo $rootpw; echo $rootpw ) | passwd " | arch-chroot /mnt
echo "useradd -m -g users -G wheel,power,storage,video,audio -s /bin/bash $username" | arch-chroot /mnt
echo "( echo $password; echo $password ) | passwd  $username" | arch-chroot /mnt
cp share/sudoers /mnt/etc/sudoers
echo 'ln -sf /usr/share/zoneinfo/US/Eastern /etc/localtime' | arch-chroot /mnt
echo 'hwclock --systohc' | arch-chroot /mnt
cp share/locale.gen /mnt/etc/locale.gen
echo 'locale-gen' | arch-chroot /mnt
echo 'echo LANG=en_US.UTF-8 > /etc/locale.conf' | arch-chroot /mnt
echo "echo $hostname > /etc/hostname" | arch-chroot /mnt
cp share/pacman.conf /mnt/etc/pacman.conf
echo 'pacman -Sy --noconfirm' | arch-chroot /mnt
if [ "$booter" = "Grub" ]; then
    echo 'pacman -S --noconfirm grub efibootmgr dosfstools mtools' | arch-chroot /mnt
    echo 'grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=Arch' | arch-chroot /mnt
    echo 'grub-mkconfig -o /boot/grub/grub.cfg' | arch-chroot /mnt
fi
if [ "$booter" = "Systemd" ]; then
    echo 'bootctl install' | arch-chroot /mnt
    cp share/arch.conf /mnt/boot/loader/entries/arch.conf
fi
echo 'systemctl enable fstrim.timer' | arch-chroot /mnt
echo 'systemctl enable NetworkManager' | arch-chroot /mnt
if [ "$gpubrand" = "AMD" ] && [ "$booter" = "Systemd" ] && [ "$type" = "SATA" ]; then
    echo "echo "options root=PARTUUID=$(blkid -s PARTUUID -o value /dev/$drive\3) rw quiet" >> /boot/loader/entries/arch.conf" | arch-chroot /mnt
    echo 'pacman -S --noconfirm mesa libva-mesa-driver vulkan-radeon xf86-video-amdgpu' | arch-chroot /mnt
fi
if [ "$gpubrand" = "AMD" ] && [ "$booter" = "Systemd" ] && [ "$type" = "NVME" ]; then
    echo "echo "options root=PARTUUID=$(blkid -s PARTUUID -o value /dev/$drive\p3) rw quiet" >> /boot/loader/entries/arch.conf" | arch-chroot /mnt
    echo 'pacman -S --noconfirm mesa libva-mesa-driver vulkan-radeon xf86-video-amdgpu' | arch-chroot /mnt
fi
if [ "$gpubrand" = "AMD" ] && [ "$booter" = "Grub" ]; then
    echo 'pacman -S --noconfirm mesa libva-mesa-driver vulkan-radeon xf86-video-amdgpu' | arch-chroot /mnt
fi
if [ "$gpubrand" = "NVIDIA" ] && [ "$booter" = "Systemd" ] && [ "$type" = "SATA"]; then
    echo 'pacman -S --noconfirm nvidia-open libglvnd nvidia-utils opencl-nvidia lib32-libglvnd lib32-opencl-nvidia nvidia-settings' | arch-chroot /mnt
    cp share/mkinitcpio.conf /mnt/etc/mkinitcpio.conf
    echo "echo "options root=PARTUUID=$(blkid -s PARTUUID -o value /dev/$drive\3) rw nvidia_drm.modeset=1 quiet" >> /boot/loader/entries/arch.conf" | arch-chroot /mnt
    mkdir /mnt/etc/pacman.d/hooks
    cp share/nvidia.hook /mnt/etc/pacman.d/hooks/nvidia.hook
    cp share/nvidia.conf /mnt/etc/modprobe.d/nvidia.conf
fi
if [ "$gpubrand" = "NVIDIA" ] && [ "$booter" = "Systemd" ] && [ "$type" = "NVME"]; then
    echo 'pacman -S --noconfirm nvidia-open libglvnd nvidia-utils opencl-nvidia lib32-libglvnd lib32-opencl-nvidia nvidia-settings' | arch-chroot /mnt
    cp share/mkinitcpio.conf /mnt/etc/mkinitcpio.conf
    echo "echo "options root=PARTUUID=$(blkid -s PARTUUID -o value /dev/$drive\p3) rw nvidia_drm.modeset=1 quiet" >> /boot/loader/entries/arch.conf" | arch-chroot /mnt
    mkdir /mnt/etc/pacman.d/hooks
    cp share/nvidia.hook /mnt/etc/pacman.d/hooks/nvidia.hook
    cp share/nvidia.conf /mnt/etc/modprobe.d/nvidia.conf
fi
if [ "$gpubrand" = "NVIDIA" ] && [ "$booter" = "Grub" ]; then
    echo 'pacman -S --noconfirm nvidia-open libglvnd nvidia-utils opencl-nvidia lib32-libglvnd lib32-opencl-nvidia nvidia-settings' | arch-chroot /mnt
    cp share/mkinitcpio.conf /mnt/etc/mkinitcpio.conf
    cp share/grub /mnt/etc/default/grub
    mkdir /mnt/etc/pacman.d/hooks
    cp share/nvidia.hook /mnt/etc/pacman.d/hooks/nvidia.hook
    cp share/nvidia.conf /mnt/etc/modprobe.d/nvidia.conf
fi
umount -R /mnt
reboot
