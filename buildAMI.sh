#!/usr/bin/env bash

VOLUME=$1
if [ -z $VOLUME ]; then
    VOLUME=/dev/xvdb
fi

yum -y install coreutils device-mapper device-mapper-event device-mapper-event-libs device-mapper-libs \
    device-mapper-persistent-data e2fsprogs gawk git grep grub2 grub2-tools grubby lvm2 lvm2-libs openssl \
    parted sed sysvinit-tools unzip util-linux-ng yum-utils zip

scripts/DiskSetup.sh -b /boot -v VolGroup00 -d $VOLUME
scripts/MkChrootTree.sh $VOLUME
scripts/MkTabs.sh $VOLUME
scripts/ChrootBuild.sh
scripts/ChrootCfg.sh
scripts/GrubSetup.sh $VOLUME
scripts/NetSet.sh
scripts/CleanChroot.sh
scripts/PreRelabel.sh
