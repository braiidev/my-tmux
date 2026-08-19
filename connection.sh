#!/bin/bash

iface=$(ip addr | awk '/state UP/ {print $2; exit}' | tr -d ':')

FULL=false
SHORT=false
COMPATIBLE=false

for arg in "$@"; do
    case "$arg" in
        --full)       FULL=true ;;
        --short)      SHORT=true ;;
        --compatible) COMPATIBLE=true ;;
    esac
done

# Icons
WIFI_ICON=" "
ETH_ICON="󰈀 "
OFFLINE_ICON="󰖪 "

if $COMPATIBLE; then
    WIFI="WIFI"
    ETH="ETH"
    OFFLINE="OFFLINE"
else
    WIFI="$WIFI_ICON"
    ETH="$ETH_ICON"
    OFFLINE="$OFFLINE_ICON"
fi

case "$iface" in

    wlp*)
        ssid=$(nmcli -t -f active,ssid dev wifi |
            awk -F: '$1=="yes" {print $2; exit}')

        ip=$(ip -4 addr show "$iface" |
            awk '/inet / {print $2; exit}')

        if $SHORT; then
            echo "$WIFI"

        elif $FULL; then
            echo "$WIFI ${ssid:-UNKNOWN} (${ip:-NO IP})"

        else
            echo "$WIFI ${ssid:-UNKNOWN}"
        fi
        ;;

    enp*)
        ip=$(ip -4 addr show "$iface" |
            awk '/inet / {print $2; exit}')

        if $SHORT; then
            echo "$ETH"

        elif $FULL; then
            echo "$ETH (${ip:-NO IP})"

        else
            echo "$ETH"
        fi
        ;;

    *)
        echo "$OFFLINE"
        ;;
esac
