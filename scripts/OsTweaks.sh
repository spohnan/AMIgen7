#!/usr/bin/env bash

cat << EOF > /usr/lib/sysctl.d/99-ami_sysctl.conf
vm.swappiness=10
vm.vfs_cache_pressure=50
EOF