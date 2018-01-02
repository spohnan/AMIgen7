#!/usr/bin/env bash
# ami-02e98f78

REPORT_DIR=/opt/openscap-reports
PROFILE=stig-rhel7-disa

yum -y update
yum -y install aide dracut-fips dracut-fips-aesni openscap openscap-utils prelink scap-security-guide sssd

if [ ! -d $REPORT_DIR ]; then
    mkdir -p $REPORT_DIR
fi
cd $REPORT_DIR/tmp

oscap xccdf eval --remediate \
    --profile xccdf_org.ssgproject.content_profile_stig-rhel7-disa \
    --results scan-xccdf-results.xml \
    --report $(hostname)-scap-report-$(date +%Y%m%d)-before.html \
    --fetch-remote-resources /usr/share/xml/scap/ssg/content/ssg-centos7-ds.xml

# Configure Notification of Post-AIDE Scan Details
if grep --silent '.*aide --check$' /etc/crontab; then
    sed -i "s/.*aide --check$/05 4 * * * root \/usr\/sbin\/aide --check | \/bin\/mail -s \"$(hostname) - AIDE Integrity Check\" root@localhost/g" /etc/crontab
fi

# Add nosuid Option to /home
if grep --silent '/home.*defaults[[:space:]]' /etc/fstab; then
    sed -i 's/\(.*\/home.*\)defaults/\1defaults,nosuid\t/' /etc/fstab
fi

#TODO
# Set Password Retry Prompts Permitted Per-Session
var_password_pam_retry="3"
if grep -q "retry=" /etc/pam.d/system-auth; then
	sed -i --follow-symlinks "s/\(retry *= *\).*/\1$var_password_pam_retry/" /etc/pam.d/system-auth
else
	sed -i --follow-symlinks "/pam_pwquality.so/ s/$/ retry=$var_password_pam_retry/" /etc/pam.d/system-auth
fi

#TODO
# Ensure Home Directories are Created for New Users
sed -i 's/CREATE_HOME.*/CREATE_HOME\tyes/' /etc/login.defs

# Set Default firewalld Zone for Incoming Packets
sed -i 's/DefaultZone.*/DefaultZone=drop/' /etc/firewalld/firewalld.conf

# Configure Multiple DNS Servers in /etc/resolv.conf
# In AWS the nameserver is a highly available virtual device, just copy to silence the finding
# https://docs.aws.amazon.com/AmazonVPC/latest/UserGuide/VPC_DHCP_Options.html#AmazonDNS
if [ $(grep nameserver /etc/resolv.conf | wc -l) -lt 2 ]; then
sed -i 's/\(nameserver.*\)/&\
\1/' /etc/resolv.conf
fi

# Use Only FIPS 140-2 Validated Ciphers
sed -i 's/Ciphers.*/Ciphers aes128-ctr,aes192-ctr,aes256-ctr/' /etc/ssh/sshd_config

# Use Only FIPS 140-2 Validated MACs
sed -i 's/MACs.*/MACs hmac-sha2-512,hmac-sha2-256/' /etc/ssh/sshd_config

# Configure PAM in SSSD Services
echo -e '[sssd]\nservices = sudo, autofs, pam' > /etc/sssd/sssd.conf

# Configure NTP Maxpoll Interval
if grep --silent ^maxpoll /etc/ntp.conf; then
    sed -i 's/maxpoll.*/maxpoll 17/' /etc/ntp.conf
else
    echo "maxpoll 17" >> /etc/ntp.conf
fi

# ClamAV
yum -y install epel-release
yum -y install clamav clamav-scanner-systemd clamav-update
sed -i 's/^Example/#Example/g' /etc/freshclam.conf
freshclam
echo -e '#!/bin/sh\nfreshclam\n' > /etc/cron.daily/freshclam
chmod 755 /etc/cron.daily/freshclam
ln -s /etc/clamd.d/scan.conf /etc/clamd.conf
sed -i 's/^Example/#Example/g' /etc/clamd.d/scan.conf
sed -i 's/^#LocalSocket /LocalSocket /g' /etc/clamd.d/scan.conf
sed -i 's/^#LogFile /LogFile /g' /etc/clamd.d/scan.conf
touch /var/log/clamd.scan
chown clamscan:clamscan /var/log/clamd.scan
setsebool -P antivirus_can_scan_system 1
setsebool -P clamd_use_jit 1
cat /etc/fstab | grep nfs | awk '{printf "%s%s\n", "ExcludePath ^", $2}' >> /etc/clamd.d/scan.conf
echo "ExcludePath ^/proc" >> /etc/clamd.d/scan.conf
echo "ExcludePath ^/sys" >> /etc/clamd.d/scan.conf
echo "VirusEvent aws sns publish --topic-arn shared-services-ErrorTopic-QT3ZJ7CLXCKS --region us-east-1 --subject \"VIRUS ALERT: %v\" --message \"VIRUS ALERT: %v\"" >> /etc/clamd.d/scan.conf
systemctl start clamd@scan
systemctl enable clamd@scan

oscap xccdf eval \
    --profile xccdf_org.ssgproject.content_profile_stig-rhel7-disa \
    --results scan-xccdf-results.xml \
    --report $(hostname)-scap-report-$(date +%Y%m%d)-after2.html \
    --fetch-remote-resources /usr/share/xml/scap/ssg/content/ssg-centos7-ds.xml --oval-results
