#!/bin/bash
#variables default values
str_dnsname="m1900.lan"
str_port="2222"
str_imagebuilder_path="./imagebuilder"
str_buildprofile="linksys_wrt1900acs"
str_output_dir="/tmp/${str_buildprofile}"

arr_rsync_opts=(
--archive
--verbose
--numeric-ids
--relative
"--rsh=ssh -p ${str_port}"
)

#what to scp from the target and include in the image as default configuration
arr_configs=(
/etc/config/{adblock,dhcp,dropbear,firewall,fstab,luci,network,sqm,system,uhttpd,wireless}
/etc/dropbear/{authorized_keys,dropbear_ed25519_host_key,dropbear_rsa_host_key}
/etc/ssh/sshd_config
/etc/{firewall.user,passwd,group,rc.local,shadow,sysupgrade.conf,uhttpd.crt,uhttpd.key}
/usr/local
/www/luci-static/openwrt2020/cascade.css
)

#packages to include in the image
arr_packages_include=(
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
rsync
)

#packages to remove from the image
arr_packages_exclude=(
ppp
ppp-mod-pppoe
)

#services to disable by default
arr_disabled_services=(
ulogd
adblock
)

#configs: expand to a string with root@dnsname prepended for ease of scp use
arr_configs=( "${arr_configs[@]/#/root@$str_dnsname:}" )

#packages: combine include and exclude list, prepend '-' before any exclude
arr_packages=( "${arr_packages_include[@]}" )
arr_packages+=( "${arr_packages_exclude[@]/#/-}" )

mkdir -p "${str_imagebuilder_path}/files"
rm -rf "${str_imagebuilder_path}/files/"*
#scp -rCOP "$str_port" "${arr_configs[@]}" "${str_imagebuilder_path}/files"
rsync "${arr_rsync_opts[@]}" --verbose "${arr_configs[@]}" "${str_imagebuilder_path}/files"

#create output directory
mkdir -p "$str_output_dir"

#TODO: log and exit
cd "$str_imagebuilder_path" || exit

make clean
make image \
PROFILE="$str_buildprofile" \
BIN_DIR="$str_output_dir" \
PACKAGES="${arr_packages[*]}" \
FILES="files" \
DISABLED_SERVICES="${arr_disabled_services[*]}"
cd ..

#find sysupgrade file and copy to the target
str_sysupgrade_file=$(find "$str_output_dir" -name "*${str_buildprofile}*sysupgrade*.bin")
echo "$str_sysupgrade_file"
scp -COP "$str_port" "$str_sysupgrade_file" "root@${str_dnsname}:/tmp/"
ssh -p "$str_port" root@"$str_dnsname"
