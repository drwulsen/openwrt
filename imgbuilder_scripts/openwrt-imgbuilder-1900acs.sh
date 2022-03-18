#!/bin/bash
#variables default values
dnsname="m1900.lan"
port="2222"
imagebuilder_path="./imagebuilder/"
buildprofile="linksys_wrt1900acs"

#what to scp from the target and include in the image as default configuration
configs=(
/etc/config/{adblock,dhcp,dropbear,firewall,fstab,luci,network,sqm,system,uhttpd,wireless}
/etc/dropbear/{authorized_keys,dropbear_ed25519_host_key,dropbear_rsa_host_key}
/etc/ssh/sshd_config
/etc/{firewall.user,passwd,group,rc.local,shadow,sysupgrade.conf,uhttpd.crt,uhttpd.key}
/usr/local
/www/luci-static/openwrt2020/cascade.css
)

#packages to include in the image
packages_include=(
iptables-mod-conntrack-extra
iptables-mod-extra
kmod-sched
libuhttpd-wolfssl
luci
luci-app-adblock
luci-app-advanced-reboot
luci-app-sqm
luci-app-uhttpd
luci-ssl
luci-theme-openwrt-2020
rsync
tcpdump-mini
ulogd
ulogd-mod-extra
ulogd-mod-nfct
ulogd-mod-syslog
)

#packages to remove from the image
packages_exclude=(
ppp
ppp-mod-pppoe
)

#services to disable by default
disabled_services=(
ulogd
adblock
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
