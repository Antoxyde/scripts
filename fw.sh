#!/bin/bash

set -x


if [ "$EUID" -ne 0 ]
  then echo "Please run as root."
  exit 1
fi

WIFI_IF=wlp1s0

iptables -F

# Default policies
iptables -P INPUT DROP
iptables -P OUTPUT ACCEPT
iptables -P FORWARD DROP

# Accepts loopback and already established connection
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -i "$WIFI_IF" -m state --state ESTABLISHED,RELATED -j ACCEPT

iptables -A INPUT -i "$WIFI_IF" -p icmp -j ACCEPT

