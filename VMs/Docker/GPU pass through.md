 489 reboot
 490  lspci -nnv | grep VGA
 491 lsmod | grep i915
 492 modprobe i915
 493 apk add linux-lts linux-firmware-intel
 494 grub-mkconfig -o /boot/grub/grub.cfg
 495 uname -a
 496 reboot
 497 uname -a
 498 modprobe i915
 499 lsmod | grep i915
 500 vim /etc/modules-load.d/i915.conf
 501 /etc/modules-load.d/
 502 echo 'i915' | sudo tee /etc/modules-load.d/i915.conf
 503 apk add sudo
 504 echo 'i915' | sudo tee /etc/modules-load.d/i915.conf
 505 less
 506 lesse /etc/modules-load.d/i915.conf
 507 less /etc/modules-load.d/i915.conf
 508 reboot
 509 lsmod | grep i915
 510 ls /dev/dri
 511 vainfo
 512 apk add libva-utils
 513 vainfo
 514 apk add intel-media-driver
 515 vainfo
 516 ls /lib/firmware/i915
 517 apk add linux-firmware-intel
 518 dmesg | grep -i i915
 519 vainfo
 520 reboot
 521 dmesg | grep -i i915
 522 apk add linux-firmware
 523 mkinitfs
 524 reboot
 525 ls /lib/firmware/i915/
 526 dmesg | grep -i i915
 527 vainfo
 528 history