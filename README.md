My configuration.nix

Instalation

Create key for decrypting

`$ dd if=/dev/urandom of=./keyfile0.bin bs=1024 count=4`

Enter the passphrase which is used to unlock disk. You will enter this in grub on every boot

`$ cryptsetup luksFormat --type luks1 -c aes-xts-plain64 -s 256 -h sha512 /dev/nvme0n1p2`

Add a second key which will be used by nixos. You will need to enter the pasphrase from previous step
```
$ cryptsetup luksAddKey /dev/nvme0n1p2 keyfile0.bin
$ cryptsetup luksOpen /dev/nvme0n1p2 crypted-nixos -d keyfile0.bin
```

Create LVM
```
$ pvcreate /dev/mapper/crypted-nixos
$ vgcreate vg /dev/mapper/crypted-nixos
$ lvcreate -L 64G -n root vg
$ lvcreate -L 24G -n swap vg
$ lvcreate -l '100%FREE' -n home vg
```

Make filesystems
```
$ mkfs.fat -F 32 /dev/nvme0n1p1
$ mkswap -L swap /dev/vg/swap
$ mkfs.btrfs -L root /dev/vg/root
$ mkfs.btrfs -L home /dev/vg/root
```

Mount filesystems
```
$ mount /dev/vg/root /mnt
$ mount --mkdir /dev/nvme0n1p1 /mnt/boot/efi
$ mount /dev/vg/home /mnt/home
$ swapon /dev/vg/swap
```

Copy key to new root
```
$ mkdir -p /mnt/etc/secrets/initrd/
$ cp keyfile0.bin /mnt/etc/secrets/initrd
$ chmod 000 /mnt/etc/secrets/initrd/keyfile0.bin`
```

Create base configuration.nix
```
$ nixos-generate-config --root /mnt
nano /mnt/etc/nixos/configuration.nix
```

Install
```
nix-install
reboot
```
