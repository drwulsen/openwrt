#!/bin/sh

# args: Device qdisc down up wifi/wired/etc

IDstring="$1"
#server="netperf.bufferbloat.net"
server="netperf-eu.bufferbloat.net"
ping -c 4 "$server"
flent --ipv4 -l 30 -H "$server" rrul -p all_scaled --figure-height=240 --figure-width=300 -D . -t "$IDstring" -o "${IDstring}.png"
