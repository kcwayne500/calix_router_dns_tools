#!/bin/sh

DNSMASQ_CONF="/etc/dnsmasq.conf"
RULE_PREFIX="address=/"

CHANGED=0   # Tracks if user added/removed anything

banner() {
    clear
    echo "======================================="
    echo "        DNS BLOCK MANAGER v1.2"
    echo "======================================="
    echo
}

restart_dnsmasq() {
    /etc/init.d/dnsmasq restart >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "dnsmasq restarted."
    else
        echo "Failed to restart dnsmasq!"
    fi
}

view_blocks() {
    banner
    echo "Current Blocked Domains:"
    echo

    COUNT=1
    grep "$RULE_PREFIX" $DNSMASQ_CONF | while read -r line; do
        DOMAIN=$(echo "$line" | sed 's/address=\///;s/\/0.0.0.0//')
        echo "$COUNT) $DOMAIN"
        COUNT=$((COUNT + 1))
    done

    echo
    echo "Press Enter to return..."
    read x
}

add_block() {
    banner
    echo "Enter a domain to block (example: facebook.com):"
    read DOMAIN

    [ -z "$DOMAIN" ] && echo "No domain entered." && sleep 1 && return

    RULE="address=/$DOMAIN/0.0.0.0"

    if grep -q "$RULE" "$DNSMASQ_CONF"; then
        echo "Domain already blocked."
    else
        echo "$RULE" >> "$DNSMASQ_CONF"
        echo "$DOMAIN added."
        CHANGED=1
    fi
    sleep 1
}

remove_block() {
    banner
    echo "Enter the domain to remove (example: facebook.com):"
    read DOMAIN

    [ -z "$DOMAIN" ] && echo "No domain entered." && sleep 1 && return

    RULE="address=/$DOMAIN/0.0.0.0"

    if grep -q "$RULE" "$DNSMASQ_CONF"; then
        sed -i "\|$RULE|d" "$DNSMASQ_CONF"
        echo "$DOMAIN removed."
        CHANGED=1
    else
        echo "$DOMAIN is not currently blocked."
    fi
    sleep 1
}

exit_handler() {
    if [ "$CHANGED" -eq 1 ]; then
        echo
        echo "You made changes."
        echo "Restart dnsmasq now to apply settings? (y/n)"
        read ANSWER

        case "$ANSWER" in
            y|Y)
                restart_dnsmasq
                ;;
            *)
                echo "Okay, not restarting."
                ;;
        esac
    else
        echo "No changes made, exiting."
    fi

    echo
    exit 0
}

menu() {
    while true; do
        banner
        echo "1) View blocked domains"
        echo "2) Add a domain"
        echo "3) Remove a domain"
        echo "4) Exit"
        echo
        echo "Enter choice:"
        read CHOICE

        case "$CHOICE" in
            1) view_blocks ;;
            2) add_block ;;
            3) remove_block ;;
            4) exit_handler ;;
            *) echo "Invalid option"; sleep 1 ;;
        esac
    done
}

menu
