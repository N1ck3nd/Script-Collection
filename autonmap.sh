#!/bin/bash

# Script to kick off Nmap scans
# Add to .zshrc / .bashrc: alias autonmap='sudo bash <PATH>/autonmap.sh'


# Argument(s)
IP=$1

# Check if running as root
function check_root() {
    if [[ $EUID -ne 0 ]]; then
    echo -e "\e[1;33m[!] This script must be run as root\e[0m" 
    exit 1
    fi
}

# Create directory
function create_nmapdirectory() {
    if [[ -d "nmap" ]]; then
        echo -e "\n\e[1;33m[!] Nmap directory already exists\e[0m"
    else
        echo "\e[31m\nCreating nmap directory\e[0m"
        mkdir nmap
    fi
}

# Run initial Nmap scan
function initial_scan() {
    nmap --top-ports 50 --open -vvv -T4 -oA nmap/initial-tcp $IP -Pn
    OPENPORTSINITIAL=$(cat nmap/initial-tcp.nmap | grep ' open' | awk -F/ '{print $1 ","}' ORS=' ' | xargs echo | sed -e 's/,$//')
    echo "Top 50 ports - Open TCP Ports: $OPENPORTSINITIAL" | tee nmap/summary.txt
}

# Run heavy (TCP) Nmap scan
function heavy_scan() {
    nmap -sV -sC -T4 -p- --open -vvv -oA nmap/full-tcp $IP -Pn
    OPENPORTSHEAVY=$(cat nmap/full-tcp.nmap | grep ' open' | awk -F/ '{print $1 ","}' ORS=' ' | xargs echo | sed -e 's/,$//')
    echo "All port - Open TCP Ports: $OPENPORTSHEAVY" | tee -a nmap/summary.txt
}

# Run UDP Nmap scan
function udp_scan() {
    nmap -sU -sV --top-ports 100 --open -vvv -oA nmap/initial-udp $IP -Pn
    OPENPORTSUDP=$(cat nmap/initial-tcp.nmap | grep ' open' | awk -F/ '{print $1 ","}' ORS=' ' | xargs echo | sed -e 's/,$//')
    echo "Top 100 ports - Open UDP Ports: $OPENPORTSUDP" | tee -a nmap/summary.txt
}

# Main function
function main() {

    if [ -z "$IP" ]; then
        echo -e "\e[1;33m[!] Please supply a valid IP address\e[0m"
        exit
    fi

    check_root

    create_nmapdirectory

    echo -e "\e[31m\n[*] Starting initial TCP scan\n\e[0m"

    initial_scan

    echo -e "\e[31m\n[*] Starting heavy TCP scan\n\e[0m"

    heavy_scan

    echo -e "\e[31m\n[*] Starting initial UDP scan\n\e[0m"

    udp_scan

    echo -e "\e[31m\n[*] Converting scan results to markdown\e[0m"

    nmap2md

    echo -e "\e[1;32m[*] Done!\n\e[0m"
}

main
