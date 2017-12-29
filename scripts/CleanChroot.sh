#!/bin/bash
# shellcheck disable=
#
# Do some file cleanup...
#
#########################
CHROOT=${CHROOT:-/mnt/ec2-root}
CLOUDCFG="$CHROOT/etc/cloud/cloud.cfg"
JRNLCNF="$CHROOT/etc/systemd/journald.conf"

# Disable EPEL repos
chroot "${CHROOT}" yum-config-manager --disable "*epel*" > /dev/null

# Get rid of stale RPM data
chroot "${CHROOT}" yum clean --enablerepo=* -y packages
chroot "${CHROOT}" rm -rf /var/cache/yum
chroot "${CHROOT}" rm -rf /var/lib/yum

# Nuke any history data
cat /dev/null > "${CHROOT}/root/.bash_history"

# Clean up all the log files
# shellcheck disable=SC2044
for FILE in $(find "${CHROOT}/var/log" -type f)
do
   cat /dev/null > "${FILE}"
done

# Enable persistent journal logging
if [[ $(grep -q ^Storage "${JRNLCNF}")$? -ne 0 ]]
then
   echo 'Storage=persistent' >> "${JRNLCNF}"
   install -d -m 0755 "${CHROOT}/var/log/journal"
   chroot "${CHROOT}" systemd-tmpfiles --create --prefix /var/log/journal
fi

# Set TZ to UTC
rm "${CHROOT}/etc/localtime"
cp "${CHROOT}/usr/share/zoneinfo/UTC" "${CHROOT}/etc/localtime"
