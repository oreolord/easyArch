
import os
from sys import argv
from functions import install_bootloader, install_desktop, install_drivers

script, bootloader, desktop, hostname, username, password, rootpswd, gpu, rootpar = argv

os.system(f"( echo {rootpswd}; echo {rootpswd} ) | passwd")
os.system(f"useradd -m -g users -G wheel,power,storage,video,audio -s /bin/bash {username}")
os.system(f"( echo {password}; echo {password} ) | passwd {username}")

sudoers = "%wheel ALL=(ALL:ALL) ALL"
os.system(f"sed -i '114c{sudoers}' /etc/sudoers")

os.system("ln -sf /usr/share/zoneinfo/US/Eastern /etc/localtime")
os.system("hwclock --systohc")

localegen = "en_US.UTF-8 UTF-8"
os.system(f"echo '{localegen}' > /etc/locale.gen")
os.system("locale-gen")

os.system("echo LANG=en_US.UTF-8 > /etc/locale.conf")
os.system(f"echo {hostname} > /etc/hostname")

pacmans = "[multilib]", "Include = /etc/pacman.d/mirrorlist"    
os.system(f"sed -i '90c{pacmans[0]}' /etc/pacman.conf")    
os.system(f"sed -i '91c{pacmans[1]}' /etc/pacman.conf")
os.system("pacman -Sy --noconfirm")    

install_bootloader(bootloader, gpu, rootpar)
install_drivers(gpu)
install_desktop(desktop)
os.system("systemctl enable fstrim.timer")
os.system("systemctl enable NetworkManager")

