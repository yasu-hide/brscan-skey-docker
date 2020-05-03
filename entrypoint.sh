#!/bin/bash
set -e

start () {
    dbus-daemon --system
    avahi-daemon --daemon
    while ! avahi-daemon -c; do echo "waiting avahi-daemon"; sleep 1; done
    avahi-browse -rkpt _uscans._tcp | awk -F\; '$1=="="&&$3=="IPv4" {print $4,$7,$8}' | while read model name ip; do
        /usr/bin/brsaneconfig4 -a name=${name%%.*} model=$model ip=$ip
    done
    /usr/bin/brscan-skey
}

stop () {
    /usr/bin/brscan-skey --terminate
    avahi-daemon -k
}

trap stop 1 2 3 15

if [ "$1" = "start" ]; then
    start
    exec /app/pause
fi

exec $@