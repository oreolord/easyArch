import subprocess
import os

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

        print("Select your CPU's brand.")
        cpu = subprocess.run(generate_list(["Intel", "AMD"]), stdout=subprocess.PIPE, text=True).stdout.rstrip()
        clear()

        print("Select your GPU's brand.")
        gpu = subprocess.run(generate_list(["NVIDIA", "AMD"]), stdout=subprocess.PIPE, text=True).stdout.rstrip()
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
    return [drive, cpu, gpu, bootloader, desktop, hostname, username, password, rootpswd]
