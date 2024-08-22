
# Easy install script of Arch Linux 
Supports Wayland on NVIDIA graphics cards. 

Boots with either GRUB or systemd boot

If you find any bugs or think of a way to make it better, please make an issue!
> [!WARNING]
> **CURRENTLY _ONLY_ SUPPORTS ENGLISH KEYMAPS WITH EST TIMEZONE!!**


## How to use:
1. Boot into your install usb.

2. Put in these commands one by one:
```
pacman -Sy git
git clone https://github.com/oreolord/eZarch.git share
chmod +x share/archinstall.sh
./share/archinstall.sh
```
4. Fill out the options.

The script will start, and reboot the computer when finished.
Enjoy!

Todo:
- Timezone support
- Keymap support
- Post-installation script
