#!/usr/bin/env bash

CHROOT="${CHROOT:-/mnt/ec2-root}"

cat << EOF > ${CHROOT}/usr/lib/sysctl.d/99-ami_sysctl.conf
vm.swappiness=10
vm.vfs_cache_pressure=50
EOF