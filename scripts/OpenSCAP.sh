#!/usr/bin/env bash
# ami-02e98f78

SCAP_VERSION=0.1.36
REPORT_DIR=/opt/openscap-reports
PROFILE=stig-rhel7-disa

yum -y update
yum -y install aide curl dracut-fips dracut-fips-aesni openscap openscap-utils prelink scap-security-guide sssd unzip

if [ ! -d $REPORT_DIR/tmp ]; then
    mkdir -p $REPORT_DIR/tmp
    cd $REPORT_DIR/tmp
    curl -OL https://github.com/OpenSCAP/scap-security-guide/releases/download/v${SCAP_VERSION}/scap-security-guide-${SCAP_VERSION}.zip
    unzip *.zip
fi
cd $REPORT_DIR

oscap xccdf eval --remediate \
    --profile xccdf_org.ssgproject.content_profile_stig-rhel7-disa \
    --results scan-xccdf-results.xml \
    --report $(hostname)-scap-report-$(date +%Y%m%d)-before.html \
    --fetch-remote-resources /opt/openscap-reports/tmp/scap-security-guide-${SCAP_VERSION}/ssg-centos7-ds.xml

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

# Ensure gpgcheck Enabled for Repository Metadata
if ! grep --silent '.*repo_gpgcheck' /etc/yum.conf; then
    echo "repo_gpgcheck=1" >> /etc/yum.conf
else
    sed -i 's/repo_gpgcheck.*/repo_gpgcheck=1/' /etc/yum.conf
fi

# Configure auditd space_left Action on Low Disk Space
var_auditd_space_left_action="email"
grep -q ^space_left_action /etc/audit/auditd.conf && \
  sed -i "s/space_left_action.*/space_left_action = $var_auditd_space_left_action/g" /etc/audit/auditd.conf
if ! [ $? -eq 0 ]; then
    echo "space_left_action = $var_auditd_space_left_action" >> /etc/audit/auditd.conf
fi

oscap xccdf eval \
    --profile xccdf_org.ssgproject.content_profile_stig-rhel7-disa \
    --results scan-xccdf-results.xml \
    --report $(hostname)-scap-report-$(date +%Y%m%d)-after2.html \
    --fetch-remote-resources --fetch-remote-resources /opt/openscap-reports/tmp/scap-security-guide-${SCAP_VERSION}/ssg-centos7-ds.xml
