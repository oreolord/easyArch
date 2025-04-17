from functions import setup, find_partitions, install_linux
import os
import subprocess



flags = setup()
drive = f"/dev/{flags[0]}"
cpu = flags[1]
os.system(f"parted {drive} mklabel gpt")
echo_sequence = "echo n\necho  \necho  \necho +512M\necho t\necho 1\necho  n\necho  \necho  \necho +8G\necho t\necho 2\necho 19\necho n\necho  \necho  \necho  \necho w"
os.system(f"({echo_sequence}) | fdisk {drive}")
bootpar, swappar, rootpar = find_partitions(drive)
os.system(f"mkfs.fat -F32 {bootpar}")
os.system(f"mkswap {swappar}")
os.system(f"mkfs.ext4 {rootpar}")
os.system(f"swapon {swappar}")
os.system(f"mount {rootpar} /mnt")
os.system(f"mount -m {bootpar} /mnt/boot")
os.system("reflector --verbose --country 'United States' -l 5 --sort rate --save /etc/pacman.d/mirrorlist")
install_linux(cpu)
os.system("genfstab -U /mnt >> /mnt/etc/fstab")
archconf = "title Arch\nlinux /vmlinuz-linux\ninitrd /initramfs-linux.img"
os.system(f"echo '{archconf} > /boot/loader/entries/arch.conf'")
localegen = "en_US.UTF-8 UTF-8"
os.system(f"echo '{localegen}' > /etc/locale.gen'")
    
sudoers = "%wheel ALL=(ALL:ALL) ALL"
os.system(f"sed -i '114c{sudoers}' /etc/sudoers")
    
pacmans = "[multilib]", "Include = /etc/pacman.d/mirrorlist"    
os.system(f"sed -i '90c{pacmans[0]}' /etc/pacman.conf")    
os.system(f"sed -i '91c{pacmans[1]}' /etc/pacman.conf")
    
nvidiahook = "[Trigger]\nOperation=Install\nOperation=Upgrade\nOperation=Remove\nType=Package\nTarget=nvidia\n\n[Action]\nDepends=mkinitcpio\nWhen=PostTransaction\nExec=/usr/bin/mkinitcpio -P"
os.system("mkdir /etc/pacman.d/hooks")
os.system(f"echo '{nvidiahook}' > /etc/pacman.d/hooks/nvidia.hook")   
nvidiaconf = "options nvidia_drm modeset=1 fbdev=1"
os.system(f"echo '{nvidiaconf}' > /etc/modprobe.d/nvidia.conf")
    
mkinitcpio = "MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)" 
os.system(f"sed -i '7c{mkinitcpio}' /etc/mkinitcpio.conf")
    
grub = "GRUB_CMDLINE_LINUX_DEFAULT=\"loglevel=3 quiet nvidia_drm.modeset=1\""
os.system(f"sed -i '6c{grub}' /etc/default/grub")
