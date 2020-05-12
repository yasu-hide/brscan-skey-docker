#!/bin/bash
set -e

start () {
    echo "user=$SCANKEY_USR" >> /opt/brother/scanner/brscan-skey/brscan-skey-0.2.4-0.cfg 
    dbus-daemon --system
    avahi-daemon --daemon
    while ! avahi-daemon -c; do echo "waiting avahi-daemon"; sleep 1; done
    avahi-browse -rkpt _uscans._tcp | awk -F\; '$1=="="&&$3=="IPv4" {print $4,$7,$8}' | while read model name ip; do
        /usr/bin/brsaneconfig4 -a name=${name%%.*} model=$model ip=$ip
    done
    /usr/bin/brscan-skey
    if [ -n "${EMAIL_FROM}" -a -n "${EMAIL_USER}" -a -n "${EMAIL_PASS}" ]; then
        echo "account default" >> /etc/msmtprc
        echo "host ${EMAIL_HOST}" >> /etc/msmtprc
        echo "port ${EMAIL_PORT}" >> /etc/msmtprc
        echo "from ${EMAIL_FROM}" >> /etc/msmtprc
        echo "user ${EMAIL_USER}" >> /etc/msmtprc
        echo "password ${EMAIL_PASS}" >> /etc/msmtprc
    fi
    echo "Running."
}

stop () {
    /usr/bin/brscan-skey --terminate
    avahi-daemon -k
    echo "Stopped."
}

trap stop 1 2 3 15

if [ "$1" = "start" ]; then
    start
    exec /app/pause
fi

exec $@
