#!/usr/bin/env bash

VOLUME=$1

yum -y update

yum -y install coreutils device-mapper device-mapper-event device-mapper-event-libs device-mapper-libs \
    device-mapper-persistent-data e2fsprogs gawk git grep grub grub2 grub2-tools grubby libudev lvm2 \
    lvm2-libs openssl parted sed sysvinit-tools unzip util-linux-ng yum-utils zip

./DiskSetup.sh -b /boot -v VolGroup00 -d $VOLUME ; \
./MkChrootTree.sh $VOLUME ; \
./MkTabs.sh $VOLUME ; \
./ChrootBuild.sh ; \
./AWScliSetup.sh ; \
./ChrootCfg.sh ; \
./GrubSetup.sh $VOLUME ; \
./NetSet.sh ; \
./CleanChroot.sh ; \
./PreRelabel.sh	 ; \
./Umount.sh

