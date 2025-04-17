from functions import setup, find_partitions, install_linux
import os
import subprocess



flags = setup()
drive = f"/dev/{flags[0]}"
cpu = f"/dev/{flags[1]}"
subprocess.run(["parted", drive, "mklabel", "gpt"], shell=True)
echo_sequence = "echo n\necho  \necho  \necho +512M\necho t\necho 1\necho  n\necho  \necho  \necho +8G\necho t\necho 2\necho 19\necho n\necho  \necho  \necho  \necho w"
subprocess.run(f"({echo_sequence}) | fdisk {drive}", shell=True)
bootpar, swappar, rootpar = find_partitions(drive)
subprocess.run(["mkfs.fat", "-F32", bootpar], shell=True)
subprocess.run(["mkswap", swappar], shell=True)
subprocess.run(["mkfs.ext4", rootpar], shell=True)
subprocess.run(["swapon", swappar], shell=True)
subprocess.run(["mount", rootpar, "/mnt"], shell=True)
subprocess.run(["mount", "-m", bootpar, "/mnt/boot"], shell=True)
os.system("reflector --verbose --country 'United States' -l 5 --sort rate --save /etc/pacman.d/mirrorlist")
install_linux(cpu)
os.system("genfstab -U /mnt >> /mnt/etc/fstab")
