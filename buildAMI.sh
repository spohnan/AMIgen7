#!/usr/bin/env bash

VOLUME=$1

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