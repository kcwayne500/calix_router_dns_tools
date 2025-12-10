#!/bin/sh

DNS_LOG="/var/log/dnsmasq.log"
LEASES="/exa_data/calix/dhcp.leases"

banner() {
    clear
    echo "======================================="
    echo "          DNS TRAFFIC MONITOR"
    echo "======================================="
    echo
}

# Parse Calix DHCP leases
# Format: <expiry> <mac> <ip> <hostname> <clientid>
list_devices() {
    awk '{print $3, $4, $2}' "$LEASES"
}

select_device() {
    banner
    echo "Detected Devices:"
    echo

    COUNT=1
    DEVLIST=""

    while read -r IP HOST MAC; do
        [ "$HOST" = "*" ] && HOST="Unknown"
        echo "  [$COUNT]  $HOST  ($IP)"
        DEVLIST="$DEVLIST $COUNT:$IP:$HOST:$MAC"
        COUNT=$((COUNT + 1))
    done <<EOF
$(list_devices)
EOF

    echo
    printf "Enter device number: "
    read NUM

    SELECTED=$(echo "$DEVLIST" | tr ' ' '\n' | grep "^$NUM:")

    if [ -z "$SELECTED" ]; then
        echo "Invalid selection."
        sleep 1
        return
    fi

    DEVICE_IP=$(echo "$SELECTED" | cut -d: -f2)
    DEVICE_HOST=$(echo "$SELECTED" | cut -d: -f3)

    device_menu "$DEVICE_IP" "$DEVICE_HOST"
}

show_device_logs() {
    IP="$1"
    banner
    echo "DNS Queries for device: $IP"
    echo "---------------------------------------"
    echo

    grep "from $IP" "$DNS_LOG" | sed 's/.*query/Query/'

    echo
    printf "Press Enter to return..."
    read x
}

# FIXED: BusyBox-safe live monitor
live_monitor() {
    IP="$1"
    banner
    echo "LIVE DNS TRAFFIC for $IP"
    echo "---------------------------------------"
    echo "Press CTRL+C to stop."
    echo

    tail -n 0 -f "$DNS_LOG" | while read LINE; do
        echo "$LINE" | grep "from $IP"
    done
}

top_domains() {
    IP="$1"
    banner
    echo "Top domains for $IP:"
    echo "---------------------------------------"
    echo

    grep "from $IP" "$DNS_LOG" \
        | awk '{print $6}' \
        | sort \
        | uniq -c \
        | sort -nr \
        | head

    echo
    printf "Press Enter to return..."
    read x
}

device_menu() {
    IP="$1"
    HOST="$2"

    while true; do
        banner
        echo "Device: $HOST ($IP)"
        echo
        echo "  [1] View DNS log entries"
        echo "  [2] Live monitor"
        echo "  [3] Top domains"
        echo "  [4] Back"
        echo
        printf "Choose an option: "
        read CHOICE

        case "$CHOICE" in
            1) show_device_logs "$IP" ;;
            2) live_monitor "$IP" ;;
            3) top_domains "$IP" ;;
            4) return ;;
            *) echo "Invalid option"; sleep 1 ;;
        esac
    done
}

main_menu() {
    while true; do
        banner
        echo "  [1] Select device to monitor"
        echo "  [2] View all devices"
        echo "  [3] Clear DNS log"
        echo "  [4] Exit"
        echo
        printf "Choose an option: "
        read CHOICE

        case "$CHOICE" in
            1) select_device ;;
            2) list_devices; echo; read x ;;
            3) : > "$DNS_LOG"; echo "DNS log cleared."; sleep 1 ;;
            4) clear; exit 0 ;;
            *) echo "Invalid option"; sleep 1 ;;
        esac
    done
}

main_menu
