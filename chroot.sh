#!/bin/bash

install_desktop() {
    if [ "$1" = "kde" ]; then
        pacman -S --noconfirm plasma-meta firefox konsole sddm pipewire dolphin
    fi
    if [ "$1" = "gnome" ]; then
        pacman -S --noconfirm gnome nautilus firefox gnome-terminal gdm pipewire
    fi
}

install_bootloader() {
    if [ "$1" = "Grub" ]; then
    pacman -S --noconfirm grub efibootmgr dosfstools mtools
    grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=Arch
    grub-mkconfig -o /boot/grub/grub.cfg
    fi
    if [ "$1" = "Systemd" ]; then
        bootctl install
        cp easyarch/arch.conf /boot/loader/entries/arch.conf
    fi
}

install_drivers() {
    if [ "$1" = "AMD" ] && [ "$2" = "Systemd" ] && [ "$3" = "SATA" ]; then
    echo "options root=PARTUUID=$(blkid -s PARTUUID -o value /dev/$4\3) rw quiet" >> /boot/loader/entries/arch.conf
    pacman -S --noconfirm mesa libva-mesa-driver vulkan-radeon xf86-video-amdgpu lib32-vulkan-radeon lib32-mesa
    fi
    if [ "$1" = "AMD" ] && [ "$2" = "Systemd" ] && [ "$3" = "NVME" ]; then
        echo "options root=PARTUUID=$(blkid -s PARTUUID -o value /dev/$4\p3) rw quiet" >> /boot/loader/entries/arch.conf
        pacman -S --noconfirm mesa libva-mesa-driver vulkan-radeon xf86-video-amdgpu lib32-vulkan-radeon lib32-mesa
    fi
    if [ "$1" = "AMD" ] && [ "$2" = "Grub" ]; then
        pacman -S --noconfirm mesa lib32-mesa libva-mesa-driver vulkan-radeon lib32-vulkan-radeon  xf86-video-amdgpu
    fi
    if [ "$1" = "NVIDIA" ] && [ "$2" = "Systemd" ] && [ "$3" = "SATA"]; then
        pacman -S --noconfirm nvidia-open libglvnd nvidia-utils opencl-nvidia lib32-libglvnd lib32-opencl-nvidia nvidia-settings lib32-nvidia-utils
        cp easyarch/mkinitcpio.conf /etc/mkinitcpio.conf
        echo "options root=PARTUUID=$(blkid -s PARTUUID -o value /dev/$4\3) rw nvidia_drm.modeset=1 quiet" >> /boot/loader/entries/arch.conf
        mkdir /etc/pacman.d/hooks
        cp easyarch/nvidia.hook /etc/pacman.d/hooks/nvidia.hook
        cp easyarch/nvidia.conf /etc/modprobe.d/nvidia.conf
    fi
    if [ "$1" = "NVIDIA" ] && [ "$2" = "Systemd" ] && [ "$3" = "NVME"]; then
        pacman -S --noconfirm nvidia-open libglvnd nvidia-utils opencl-nvidia lib32-libglvnd lib32-opencl-nvidia nvidia-settings lib32-nvidia-utils
        cp easyarch/mkinitcpio.conf /etc/mkinitcpio.conf
        echo "options root=PARTUUID=$(blkid -s PARTUUID -o value /dev/$4\p3) rw nvidia_drm.modeset=1 quiet" >> /boot/loader/entries/arch.conf
        mkdir /etc/pacman.d/hooks
        cp easyarch/nvidia.hook /etc/pacman.d/hooks/nvidia.hook
        cp easyarch/nvidia.conf /etc/modprobe.d/nvidia.conf
    fi
    if [ "$1" = "NVIDIA" ] && [ "$2" = "Grub" ]; then
        pacman -S --noconfirm nvidia-open libglvnd nvidia-utils opencl-nvidia lib32-libglvnd lib32-opencl-nvidia nvidia-settings lib32-nvidia-utils
        cp easyarch/mkinitcpio.conf /etc/mkinitcpio.conf
        cp easyarch/grub /etc/default/grub
        mkdir /etc/pacman.d/hooks
        cp easyarch/nvidia.hook /etc/pacman.d/hooks/nvidia.hook
        cp easyarch/nvidia.conf /etc/modprobe.d/nvidia.conf
    fi
}


( echo $rootpw; echo $rootpw ) | passwd
useradd -m -g users -G wheel,power,storage,video,audio -s /bin/bash $username
( echo $password; echo $password ) | passwd  $username
cp easyarch/sudoers /etc/sudoers
ln -sf /usr/share/zoneinfo/US/Eastern /etc/localtime
hwclock --systohc
cp easyarch/locale.gen /etc/locale.gen
locale-gen
echo LANG=en_US.UTF-8 > /etc/locale.conf
echo $hostname > /etc/hostname
cp easyarch/pacman.conf /etc/pacman.conf
pacman -Sy --noconfirm
install_bootloader $booter
systemctl enable fstrim.timer
systemctl enable NetworkManager
install_drivers $gpubrand $booter $type $drive
install_desktop $desktop
