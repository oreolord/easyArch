
# Easy install script of Arch Linux 
Supports Wayland on NVIDIA graphics cards. 

Boots with either GRUB or systemd boot,
The script may work if you copy it to the install USB, but I haven't tried

If you find any bugs or think of a way to make it better, please make an issue!
> [!WARNING]
> **CURRENTLY _ONLY_ SUPPORTS ENGLISH KEYMAPS WITH EST TIMEZONE!!**


## How to use:
1. Copy all repository files into a USB (preferrably formatted as FAT32).

> [!IMPORTANT]
> **Make sure the files are not in a separate folder inside the usb!**

2. Boot into your arch install medium.

3. Type ```lsblk``` into terminal and find the USB and it's partition with the script on it (Ex. sdb1).
_Remember this name!_

Type these commands one by one:
```
mkdir share
mount /dev/USB share # Substitute USB with the USB name from earlier
./share/eZarch.sh
```
4. Fill out the options.

The script will start, and reboot the computer when finished.
Enjoy!

Todo:
- Timezone support
- Keymap support
- Post-installation script
