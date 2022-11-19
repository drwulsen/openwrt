#!/bin/bash
#variables default values
str_dnsname="m1200.lan"
str_port="2222"
str_imagebuilder_path="./imagebuilder"
str_buildprofile="linksys_wrt1200ac"
str_logfile="./logfile"

#what to scp from the target and include in the image as default configuration
arr_configs=(
/etc/config/{dhcp,dropbear,firewall,fstab,luci,network,system,uhttpd,wireless}
/etc/dropbear/{authorized_keys,dropbear_ed25519_host_key,dropbear_rsa_host_key}
/etc/ssh/sshd_config
/etc/{firewall.user,passwd,group,rc.local,shadow,sysupgrade.conf,uhttpd.crt,uhttpd.key}
/usr/local
/www/luci-static/openwrt2020/cascade.css
)

#packages to include in the image
arr_packages_include=(
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
arr_packages_exclude=(
ppp
ppp-mod-pppoe
)

#services to disable by default
arr_disabled_services=(
dnsmasq
odhcpd
)

#configs: expand to a string with root@dnsname prepended for ease of scp use
arr_configs=( "${arr_configs[@]/#/root@$str_dnsname:}" )

#packages: combine include and exclude list, prepend '-' before any exclude
arr_packages=( "${arr_packages_include[@]}" )
arr_packages+=( "${arr_packages_exclude[@]/#/-}" )

echo "Files to pull:"
for i in ${arr_configs[@]}; do
echo "$i";
done

mkdir -p "${str_imagebuilder_path}/files"
rm -rf "${str_imagebuilder_path}/files/"*
scp -rCpOP "$str_port" "${arr_configs[@]}" "${str_imagebuilder_path}/files"

#sleep 5

cd "$str_imagebuilder_path"
#make image \
PROFILE="$str_buildprofile" \
BIN_DIR="/tmp/$str_buildprofile" \
PACKAGES="${arr_packages[*]}" \
FILES="files" \
DISABLED_SERVICES="${arr_disabled_services[*]}"
cd -

#find sysupgrade file and copy to the target
str_sysupgrade_file=$(find -name *${buildprofile}*sysupgrade*.bin)
scp -CpOP "$str_port" "$str_sysupgrade_file" "root@${str_dnsname}:/tmp/"
