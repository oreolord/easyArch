import subprocess
import os

def install_bootloader(bootloader, gpu, rootpar):
    match bootloader:
        case "Grub":
            subprocess.run(['bash', '-c', 'pacman -S --noconfirm grub efibootmgr dosfstools mtools'])
            subprocess.run(['bash', '-c', 'grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=Arch'])
            subprocess.run(['bash', '-c', 'grub-mkconfig -o /boot/grub/grub.cfg'])
            if gpu == "NVIDIA":
                grub = "GRUB_CMDLINE_LINUX_DEFAULT=\"loglevel=3 quiet nvidia_drm.modeset=1\""
                subprocess.run(['bash', '-c', f'sed -i \'6c{grub}\' /etc/default/grub'])
        case "Systemd":
            subprocess.run(['bash', '-c', 'bootctl install'])
            archconf = "title Arch\nlinux /vmlinuz-linux\ninitrd /initramfs-linux.img"
            subprocess.run(['bash', '-c', f'echo \'{archconf} > /boot/loader/entries/arch.conf\''])
            if gpu == "NVIDIA":
                echo = f'echo \"options root=PARTUUID=$(blkid -s PARTUUID -o value {rootpar}) rw nvidia_drm.modeset=1 quiet splash loglevel=3\" >> /boot/loader/entries/arch.conf'
                subprocess.run(['bash', '-c', echo])
            else:
                echo = f'echo \"options root=PARTUUID=$(blkid -s PARTUUID -o value {rootpar}) rw quiet splash loglevel=3\" >> /boot/loader/entries/arch.conf'
                subprocess.run(['bash', '-c', echo])

def install_drivers(gpu):
    match gpu:
        case "AMD":
            subprocess.run(['bash', '-c', 'pacman -S --noconfirm mesa libva-mesa-driver vulkan-radeon xf86-video-amdgpu lib32-vulkan-radeon lib32-mesa'])
        case "NVIDIA":
            subprocess.run(['bash', '-c', 'pacman -S --noconfirm nvidia-open libglvnd nvidia-utils opencl-nvidia lib32-libglvnd lib32-opencl-nvidia nvidia-settings lib32-nvidia-utils'])
            mkinitcpio = "MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)" 
            subprocess.run(['bash', '-c', f'sed -i \'7c{mkinitcpio}\' /etc/mkinitcpio.conf'])
            subprocess.run(['bash', '-c', 'mkdir /etc/pacman.d/hooks'])
            nvidiahook = "[Trigger]\nOperation=Install\nOperation=Upgrade\nOperation=Remove\nType=Package\nTarget=nvidia\n\n[Action]\nDepends=mkinitcpio\nWhen=PostTransaction\nExec=/usr/bin/mkinitcpio -P"
            subprocess.run(['bash', '-c', f'echo \'{nvidiahook}\' > /etc/pacman.d/hooks/nvidia.hook'])
            nvidiaconf = "options nvidia_drm modeset=1 fbdev=1"
            subprocess.run(['bash', '-c', f'echo \'{nvidiaconf}\' > /etc/modprobe.d/nvidia.conf'])

def install_desktop(desktop):
    match desktop:
        case "KDE":
            subprocess.run(['bash', '-c', 'pacman -S --noconfirm plasma-meta firefox konsole sddm pipewire dolphin'])
            subprocess.run(['bash', '-c', 'systemctl enable sddm'])
        case "GNOME":
            subprocess.run(['bash', '-c', 'pacman -S --noconfirm gnome nautilus firefox gnome-terminal gdm pipewire'])
            subprocess.run(['bash', '-c', 'systemctl enable gdm'])

def get_gpu():
    data = subprocess.run(['bash', '-c', 'lspci | grep -i "VGA" | awk -F ": " \'{print $2}\' | awk \'{print $1}\''], capture_output=True, text=True).stdout.rstrip()
    for line in data.splitlines():
        if line == "NVIDIA":
            return "NVIDIA"
    return "AMD"

def get_cpu():
    data = subprocess.run(['bash', '-c', 'lscpu | grep \"Vendor ID\" | awk -F\":\" \'{print $2}\' | sed \'s/ //g\''], capture_output=True, text=True).stdout.rstrip()
    for line in data.splitlines():
        if line == "GenuineIntel":
            return "Intel"
    return "AMD"

def find_partitions(drive):
    if drive[5:8] == "nvm":
        return drive + "p1", drive + "p2", drive + "p3"
    else:
        return drive + "1", drive + "2", drive + "3"

def generate_list(list):
    target = ["gum", "choose"]
    for obj in list:
        target.append(obj)
    return target

def search_disks():
    data = subprocess.run(["lsblk", "-dpno", "name"], stdout=subprocess.PIPE, text=True).stdout.rstrip()
    disks = []
    for line in data.splitlines():
        disks.append(line[5:])
    return disks

def install_linux(cpu):
    if cpu == "Intel":
        os.system("pacstrap -K /mnt base base-devel linux linux-firmware git curl intel-ucode nano bash-completion networkmanager linux-headers os-prober python3")
    elif cpu == "AMD":
        os.system("pacstrap -K /mnt base base-devel linux linux-firmware git curl amd-ucode nano bash-completion networkmanager linux-headers os-prober python3")

def clear():
    subprocess.run("clear")

def setup():
    confirm = False
    while confirm == False:
        clear()
        print("Select a drive.")
        drive = subprocess.run(generate_list(search_disks()), stdout=subprocess.PIPE, text=True).stdout.rstrip()
        clear()

        print("Select a bootloader.")
        bootloader = subprocess.run(generate_list(["Grub", "Systemd"]), stdout=subprocess.PIPE, text=True).stdout.rstrip()
        clear()

        print("Select a desktop environment.")
        desktop = subprocess.run(generate_list(["KDE", "GNOME", "Minimal"]), stdout=subprocess.PIPE, text=True).stdout.rstrip()
        clear()

        print("Type your desired hostname.")
        hostname = subprocess.run(["gum", "input"], stdout=subprocess.PIPE, text=True).stdout.rstrip()
        clear()

        print("Type your desired username.")
        username = subprocess.run(["gum", "input"], stdout=subprocess.PIPE, text=True).stdout.rstrip()
        clear()

        print("Type your desired password.")
        password = subprocess.run(["gum", "input", "--password"], stdout=subprocess.PIPE, text=True).stdout.rstrip()
        clear()

        print("Type your desired root password.")
        rootpswd = subprocess.run(["gum", "input", "--password"], stdout=subprocess.PIPE, text=True).stdout.rstrip()
        clear()

        confirm = subprocess.check_output("gum confirm && echo 'True' || echo 'False'", shell=True).rstrip()
        if 'True' in confirm.decode():
            confirm = True
        else:
            confirm = False
        print(confirm)
        clear()
    return [drive, get_cpu(), get_gpu(), bootloader, desktop, hostname, username, password, rootpswd]
