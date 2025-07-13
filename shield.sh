#!/bin/bash

MINECRAFT_PORT=25565
SSH_PORT=22

iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X
iptables -t mangle -F
iptables -t mangle -X

iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

iptables -A INPUT -m conntrack --ctstate INVALID -j DROP

iptables -A INPUT -p tcp --dport $MINECRAFT_PORT -m conntrack --ctstate NEW -m limit --limit 15/second --limit-burst 25 -j ACCEPT
iptables -A INPUT -p tcp --syn -m limit --limit 2/second --limit-burst 5 -j ACCEPT
iptables -A INPUT -p tcp --syn -j DROP

iptables -A INPUT -m recent --name scanner --rcheck --seconds 3600 -j DROP
iptables -A INPUT -m recent --name scanner --remove
iptables -A INPUT -p tcp -m tcp --dport 1:1000 -m recent --name scanner --set -j DROP

iptables -A INPUT -p tcp --dport $MINECRAFT_PORT -m connlimit --connlimit-above 8 -j REJECT --reject-with tcp-reset

iptables -A INPUT -p icmp -m limit --limit 2/second --limit-burst 3 -j ACCEPT
iptables -A INPUT -p icmp -j DROP

iptables -A INPUT -p tcp --dport $MINECRAFT_PORT -m recent --name mcflood --set
iptables -A INPUT -p tcp --dport $MINECRAFT_PORT -m recent --name mcflood --rcheck --seconds 45 --hitcount 25 -j DROP
iptables -A INPUT -p tcp --dport $MINECRAFT_PORT -j ACCEPT

iptables -A INPUT -p udp --dport $MINECRAFT_PORT -m recent --name mcudp --set
iptables -A INPUT -p udp --dport $MINECRAFT_PORT -m recent --name mcudp --rcheck --seconds 30 --hitcount 15 -j DROP
iptables -A INPUT -p udp --dport $MINECRAFT_PORT -j ACCEPT

iptables -A INPUT -p tcp --tcp-flags ALL NONE -j DROP
iptables -A INPUT -p tcp --tcp-flags ALL ALL -j DROP
iptables -A INPUT -p tcp --tcp-flags ALL FIN,URG,PSH -j DROP
iptables -A INPUT -p tcp --tcp-flags ALL SYN,RST,ACK,FIN,URG -j DROP
iptables -A INPUT -p tcp --tcp-flags SYN,RST SYN,RST -j DROP
iptables -A INPUT -p tcp --tcp-flags SYN,FIN SYN,FIN -j DROP

iptables -A INPUT -f -j DROP

iptables -A INPUT -p tcp --tcp-flags FIN,SYN,RST,PSH,ACK,URG NONE -j DROP
iptables -A INPUT -p tcp --tcp-flags FIN,SYN FIN,SYN -j DROP
iptables -A INPUT -p tcp --tcp-flags SYN,RST SYN,RST -j DROP
iptables -A INPUT -p tcp --tcp-flags FIN,RST FIN,RST -j DROP
iptables -A INPUT -p tcp --tcp-flags FIN,ACK FIN -j DROP
iptables -A INPUT -p tcp --tcp-flags ACK,URG URG -j DROP

iptables -A INPUT -s 127.0.0.0/8 ! -i lo -j DROP
iptables -A INPUT -s 0.0.0.0/8 -j DROP
iptables -A INPUT -s 169.254.0.0/16 -j DROP
iptables -A INPUT -s 224.0.0.0/4 -j DROP
iptables -A INPUT -s 240.0.0.0/5 -j DROP

iptables -A INPUT -p tcp --dport $SSH_PORT -m recent --name ssh --set
iptables -A INPUT -p tcp --dport $SSH_PORT -m recent --name ssh --rcheck --seconds 120 --hitcount 5 -j DROP
iptables -A INPUT -p tcp --dport $SSH_PORT -j ACCEPT

iptables -A OUTPUT -p udp --dport 53 -j ACCEPT
iptables -A OUTPUT -p tcp --dport 53 -j ACCEPT

iptables -A INPUT -j DROP

if command -v iptables-save > /dev/null; then
    iptables-save > /etc/iptables/rules.v4
fi

if command -v service > /dev/null && service iptables status > /dev/null 2>&1; then
    service iptables save
fi
