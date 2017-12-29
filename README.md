ami-02e98f78

```
#cloud-config
package_upgrade: true
packages:
  - coreutils
  - device-mapper
  - device-mapper-event
  - device-mapper-event-libs
  - device-mapper-libs
  - device-mapper-persistent-data
  - e2fsprogs
  - gawk
  - git
  - grep
  - grub2
  - grub2-tools
  - grubby
  - lvm2
  - lvm2-libs
  - openssl
  - parted
  - sed
  - sysvinit-tools
  - unzip
  - util-linux-ng
  - yum-utils
  - zip
```