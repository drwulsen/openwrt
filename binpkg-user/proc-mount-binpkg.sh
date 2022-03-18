#!/bin/sh
src="/proc"
dst="/mnt/usb/binpkg/proc"
token="/mnt/usb/.plugged_in"
if [ -f "$token" ]; then
  mkdir -p "$dst"
  mount -t proc "$src" "$dst"
  if [ $? -ne 0 ]; then
    logger user.err "Error mounting $src to $dst"
  else
    logger user.info echo "Mounted $src to $dst"
  fi
else
  logger user.err "Flash drive not plugged in?"
fi
