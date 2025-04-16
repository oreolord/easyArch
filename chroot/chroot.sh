#!/bin/bash

install_desktop() {
    if [ "$1" = "kde" ]; then
        pacman -S --noconfirm plasma-meta firefox konsole sddm pipewire dolphin
        systemctl enable sddm
    fi
    if [ "$1" = "gnome" ]; then
        pacman -S --noconfirm gnome nautilus firefox gnome-terminal gdm pipewire
        systemctl enable gdm
    fi
}

install_bootloader() {
    if [ "$1" = "Grub" ]; then
        pacman -S --noconfirm grub efibootmgr dosfstools mtools
        grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=Arch
        grub-mkconfig -o /boot/grub/grub.cfg
        if [ "$2" == "NVIDIA" ]; then
            cp easyarch/grub /etc/default/grub
        fi

    fi
    if [ "$1" = "Systemd" ]; then
        bootctl install
        cp easyarch/arch.conf /boot/loader/entries/arch.conf
        if [ "$2" == "NVIDIA" ]; then
            echo "options root=PARTUUID=$(blkid -s PARTUUID -o value $rootpar)) rw nvidia_drm.modeset=1 quiet splash loglevel=3" >> /boot/loader/entries/arch.conf
        else
            echo "options root=PARTUUID=$(blkid -s PARTUUID -o value $rootpar) rw quiet splash loglevel=3" >> /boot/loader/entries/arch.conf
        fi
    fi
}

install_drivers() {
    if [ "$1" = "AMD" ]; then
        pacman -S --noconfirm mesa libva-mesa-driver vulkan-radeon xf86-video-amdgpu lib32-vulkan-radeon lib32-mesa
    fi
    if [ "$1" = "NVIDIA" ]; then
        pacman -S --noconfirm nvidia-open libglvnd nvidia-utils opencl-nvidia lib32-libglvnd lib32-opencl-nvidia nvidia-settings lib32-nvidia-utils
        cp easyarch/mkinitcpio.conf /etc/mkinitcpio.conf
        mkdir /etc/pacman.d/hooks
        cp easyarch/nvidia.hook /etc/pacman.d/hooks/nvidia.hook
        cp easyarch/nvidia.conf /etc/modprobe.d/nvidia.conf
    fi
}

install_aur_helper() {
    if [ "$1" == "paru" ]; then
        git clone https://aur.archlinux.org/paru.git
        chgrp $username /paru
        chmod g+ws /paru
        setfacl -m u::rwx,g::rwx /paru
        setfacl -d --set u::rwx,g::rwx,o::- /paru
        cd paru
        sudo -u $username makepkg -si
        cd
    elif [ "$1" == "yay" ]; then
        git clone https://aur.archlinux.org/yay.git
        chgrp $username /yay
        chmod g+ws /yay
        setfacl -m u::rwx,g::rwx /yay
        setfacl -d --set u::rwx,g::rwx,o::- /yay
        cd yay
        runuser -u $username makepkg -si
        cd
    fi
}

# Set up passwords, users, locales, and time
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

# Install necessities
cp easyarch/pacman.conf /etc/pacman.conf
pacman -Sy --noconfirm
install_bootloader $booter $gpubrand
install_drivers $gpubrand $booter $type $rootpar
install_desktop $desktop
install_aur_helper $aurhelper
systemctl enable fstrim.timer
systemctl enable NetworkManager
