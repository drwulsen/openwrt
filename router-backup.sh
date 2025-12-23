#!/bin/bash
routers=(wrt1200 wrt1900 nanopi)
backupdir=/home/wula/backup-router
router=""
function backup () {
	ssh -q -o ConnectTimeout=5 root@"${router}" 'sysupgrade -k -b -' > "${backupdir%/}/${router}/${router}.tgz"
	exitvalue="$?"
}
for router in "${routers[@]}"; do
echo "Backing up $router"
test -d "${backupdir}/${router}" || mkdir -p "${backupdir}/${router}"
backup
if [ "$exitvalue" -ne 0 ]; then
	logger -p error --stderr "Error backing up $router"
else
	logger -p info --stderr "SUCCESS: Backup of $router"
fi
done
