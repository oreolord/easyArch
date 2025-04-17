from functions import setup, find_partitions, install_linux
import os


drive, cpu, gpu, bootloader, desktop, hostname, username, password, rootpswd = setup()
drive = f"/dev/{drive}"
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
