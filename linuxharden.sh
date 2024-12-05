#!/bin/bash

# Update and upgrade packages
pkg update -y
pkg upgrade -y

# Install essential packages
pkg install -y git openssh openssl termux-api

# Configure SSH
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa
echo "PermitRootLogin no" >> $PREFIX/etc/ssh/sshd_config
echo "PasswordAuthentication no" >> $PREFIX/etc/ssh/sshd_config
sshd

# Set up firewall rules
ufw enable
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh

# Install and set up a VPN
pkg install -y openvpn easy-rsa
mkdir -p ~/openvpn
cd ~/openvpn
cp -r $PREFIX/share/easy-rsa/* .
chmod 700 ~/openvpn
cd ~/openvpn/easyrsa3
./easyrsa init-pki
./easyrsa build-ca
./easyrsa gen-req server nopass
./easyrsa sign-req server server
./easyrsa gen-dh
openvpn --genkey --secret ta.key
cp pki/ca.crt pki/private/server.key pki/issued/server.crt pki/dh.pem ta.key $HOME/openvpn

# Enable SELinux
setenforce 1

# Install and configure a firewall
pkg install -y iptables
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A INPUT -p tcp --dport 22 -j ACCEPT
iptables -A INPUT -p icmp --icmp-type echo-request -j ACCEPT
iptables -A INPUT -j DROP

# Disable unnecessary services
# (Note: Some services may not be available in Termux)
# systemctl disable bluetooth.service
# systemctl disable cups.service
# systemctl disable cups-browsed.service

# Clean up
pkg clean

# Check for Android Security Bulletins
adb shell "am start -a android.intent.action.VIEW -d https://source.android.com/security/bulletin"

# Check and update packages through adb
adb shell "su -c 'pkg update -y && pkg upgrade -y'"
