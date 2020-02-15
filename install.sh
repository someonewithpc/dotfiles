#!/bin/sh

function menu() { 
	title=$1
	shift
	options=()
	for op in $@; do
		options+=($op "")
	done
	whiptail --clear --menu "$title" 0 0 0 "${options[@]}" 3>&1 1>&2 2>&3
}

echo "Starting install"

unset format
unset install_packages
unset locale
unset setup_users
unset bootloader
unset install_pikaur

while (( "$#" )); do
	case ${1} in
	-f)
		format="true"
		;;
	-p)
		install_packages="true"
		;;
	-l)
		locale="true"
		;;
	-u)
		setup_users="true"
		;;
	-b)
		bootloader="true"
		;;
	-P)
		install_pikaur="true"
		;;
	-a)	
		format="true"
		install_packages="true"
		locale="true"
		setup_users="true"
		bootloader="true"
		install_pikaur="true"	
	esac
	shift
done

loadkeys us

if [ ! -d /sys/firmware/efi/efivars ]; then
	echo "Not UEFI, quitting"
	exit
fi

timedatectl set-ntp true

if [ -n "$format" ]; then

	disk=$(menu "Select disk" /dev/sd?)

	umount -Rq /mnt

	parted $disk mklabel gpt
	sgdisk $disk -n=1:0:+1024M -t=1:ef00

	swap_size=$(expr $(cat /proc/meminfo | head -n 1 | grep --color=never -o "[0-9]\+") "*" 1024 / 1000 / 1000 / 1000)GB
	sgdisk $disk -n=2:0:+$swap_size -t=2:8200

	echo "Create a root and home partitions..."
	read foo

	cfdisk $disk

	for root in / /boot swap /home; do
		partition=$(menu "Partition for $root" ${disk}?)
		if [ $root = swap ]; then
			mkswap $partition
			swapom $partition
		elif [ $root = /boot ]; then
			mkfs.fat -F32 $partition
			mkdir /mnt$root
			mount $partition /mnt$root
		else
			mkfs.ext4 $partition
			mkdir /mnt$root
			mount $partition /mnt$root
		fi
	done
	
fi

if [ -n "$install_packages" ]; then
	nano /etc/pacman.d/mirrorlist

	pacstrap /mnt base linux-zen linux-firmware

	cp pkgs /mnt/pkgs

	arch-chroot /mnt pacman -Sy --needed - < pkgs
fi

if [ -n "$locale" ]; then
	mkdir -p /mnt/etc/local
	ln -sf /mnt/usr/share/zoneinffo/Europe/Lisbon /mnt/etc/local/time

	arch-chroot /mnt hwclock --systohc

	echo -e "en_US.UTF-8 UTF-8\npt_PT.UTF-8 UTF-8\n" > /mnt/etc/locale.gen
	arch-chroot /mnt locale-gen

	echo -e "LANG=en_US.UTF-8\nLANGUAGE=en_US.UTF-8\nLC_ALL=pt_PT.UTF-8\n" > /mnt/etc/locale.conf
	echo "KEYMAP=us" > /mnt/etc/vconsole.conf
	echo "Enter hostname"
	read foo
	nano /mnt/etc/hostname
	echo -e "127.0.0.1\tlocalhost\n::1\tlocalhost\n" > /mnt/etc/hosts
fi

genfstab -U /mnt > /mnt/etc/fstab


if [ -n "$setup_users" ]; then

	echo "Set root password"
	arch-chroot /mnt passwd

	echo "Set hugo password"
	read foo
	arch-chroot /mnt useradd -m hugo -g users -G wheel
	arch-chroot /mnt passwd hugo

	echo "Setup sudoers"
	read foo
	arch-chroot /mnt visudo
	xdg-user-dirs-update
fi

echo "Add resume to initramfs hooks"
read foo
nano /mnt/etc/mkinitcpio.conf
arch-chroot /mnt mkinitcpio -P

if [ -n "$bootloader" ]; then
	arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=Arch
	arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
#	arch-chroot /mnt efibootmgr -d $disk -L Arch -c -w
fi

arch-chroot /mnt systemctl enable lightdm

: > /mnt/etc/chrony
for i in 0..3; do
	echo "server $i.europe.pool.org offline" >> /mnt/etc/chrony
done


if [ -n "$install_pikaur" ]; then
echo -e 'cd /tmp\n\
	git clone https://github.com/actionless/pikaur pik\n\
	cd pik\n\
	makepkg -fsri --noconfirm' | arch-chroot -u hugo /mnt
fi
