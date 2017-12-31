#!/bin/sh
# shellcheck disable=SC2181
#
# Script to set up the chroot'ed /etc/fstab
#
#################################################################
CHROOT="${CHROOT:-/mnt/ec2-root}"
TARGSWAP=${2:-/dev/VolGroup00/swapVol}
FSTAB="${CHROOT}/etc/fstab"

# Check for arguments
if [ $# -lt 1 ]; then
    echo "Missing parameter(s). Aborting..." > /dev/stderr
    exit 1
fi

# Make sure that chroot'ed /etc/directory exists
if [ ! -d ${CHROOT}/etc ]; then
    mkdir -p "${CHROOT}/etc"
    if [ $? -ne 0 ]; then
        echo "Failed to create /etc" > /dev/stderr && exit 1
    else
        echo "Created ${CHROOT}/etc"
    fi
fi

# Create file-header
cat << EOF > "${FSTAB}"
#
# /etc/fstab
#
# Accessible filesystems, by reference, are maintained under '/dev/disk'
# See man pages fstab(5), findfs(8), mount(8) and/or blkid(8) for more info
#
EOF

_CHROOT=$(echo "${CHROOT}" | sed 's#^/##')

# Read mtab matches into an array
IFS=$'\n'; MTABLNS=( $(grep "${CHROOT}" /etc/mtab | grep ^/dev | sed 's#'"${_CHROOT}"'##') )

for FSLINE in "${MTABLNS[@]}"
do
    BLKDEV=$(echo "${FSLINE}" | awk '{print $1}')
    MNTPNT=$(echo "${FSLINE}" | awk '{print $2}' | sed 's#//#/#')
    if [ $MNTPNT == '/boot' ]; then
        BLKDEV=UUID=$(blkid $BLKDEV | awk '{print $3}' | cut -d '"' -f2)
    fi
    FSTYPE=$(echo "${FSLINE}" | awk '{print $3}')
    printf "%s\t%s\t%s\tdefaults\t0 0\n" "${BLKDEV}" "${MNTPNT}" "${FSTYPE}"
done >> "${FSTAB}"
printf "%s\t%s\t%s\t%s\t0 0\n" "${TARGSWAP}" swap swap '-' >> "${FSTAB}"