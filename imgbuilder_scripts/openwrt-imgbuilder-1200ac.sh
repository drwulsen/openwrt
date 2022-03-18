#!/bin/bash
#variables default values
dnsname="m1200.lan"
port="2222"
imagebuilder_path="./imagebuilder/"
buildprofile="linksys_wrt1200ac"

#what to scp from the target and include in the image as default configuration
configs=(
/etc/config/{dhcp,dropbear,firewall,fstab,luci,network,system,uhttpd,wireless}
/etc/dropbear/{authorized_keys,dropbear_ed25519_host_key,dropbear_rsa_host_key}
/etc/ssh/sshd_config
/etc/{passwd,group,rc.local,shadow,sysupgrade.conf,uhttpd.crt,uhttpd.key}
/usr/local
/www/luci-static/openwrt2020/cascade.css
)

#packages to include in the image
packages_include=(
block-mount
f2fsck
kmod-fs-f2fs
kmod-usb-storage-uas
kmod-usb3
libuhttpd-wolfssl
luci
luci-app-advanced-reboot
luci-app-uhttpd
luci-ssl
luci-theme-openwrt-2020
openssh-server
rsync
)

#packages to remove from the image
packages_exclude=(
ppp
ppp-mod-pppoe
)

#services to disable by default
disabled_services=(
dnsmasq
odhcpd
)

#create argument lists from arrays
packages_combined=(
"${packages_include[@]}"
"${packages_exclude[@]/#/-}"
)

packages="${packages_combined[@]@P}"
config_list="${configs[@]@P}"
d_services_list="${disabled_services[@]@P}"

echo "Files to pull:"
for i in "${config_list[@]}"; do
	echo "$i";
done

rm -rf "${imagebuilder_path}"/files/*
rsync -Ravz -e "ssh -p $port" "root@${dnsname}":"${config_list}" "${imagebuilder_path}/files"

sleep 5

cd "$imagebuilder_path"
make image \
PROFILE="$buildprofile" \
BIN_DIR="/tmp/${buildprofile}" \
PACKAGES="${packages}" \
FILES="files" \
DISABLED_SERVICES="$d_services_list"
cd -

scp -P 2222 /tmp/"${buildprofile}"/*sysupgrade* root@"${dnsname}":/tmp/
