#!/bin/bash

#add color for text
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
plain='\033[0m'
NC='\033[0m' # No Color


cur_dir=$(pwd)
# check root
# [[ $EUID -ne 0 ]] && echo -e "${RED}Fatal error: ${plain} Please run this script with root privilege \n " && exit 1

file="/root/speedtest_sites.dat"


install_jq() {
    if ! command -v jq &> /dev/null; then
        # Check if the system is using apt package manager
        if command -v apt-get &> /dev/null; then
            echo -e "${RED}jq is not installed. Installing...${NC}"
            sleep 1
            sudo apt-get update
            sudo apt-get install -y jq
        else
            echo -e "${RED}Error: Unsupported package manager. Please install jq manually.${NC}\n"
            read -p "Press any key to continue..."
            exit 1
        fi
    fi
}

require_command(){
    sudo apt-get install dnsutils -y
    apt install sqlite3
    rm speedtest_sites.dat*
    wget https://raw.githubusercontent.com/dev-ir/speedtest-ban/master/speedtest_sites.dat
    install_jq
}


menu(){
    
    clear
    
    # Get server IP
    SERVER_IP=$(hostname -I | awk '{print $1}')
    
    # Fetch server country using ip-api.com
    SERVER_COUNTRY=$(curl -sS "http://ip-api.com/json/$SERVER_IP" | jq -r '.country')
    
    # Fetch server isp using ip-api.com
    SERVER_ISP=$(curl -sS "http://ip-api.com/json/$SERVER_IP" | jq -r '.isp')
    
    echo "+-------------------------------------------------------------------------------------------------------------------------+"
    echo "|   #####   ######   #######  #######  #####    ######## #######   #####   ########    ######     ###    ##   ##         |"
    echo "|  ##   ##   ##  ##   ##   #   ##   #   ## ##   ## ## ##  ##   #  ##   ##  ## ## ##     ##  ##   ## ##   ###  ##         |"
    echo "|  ##        ##  ##   ##       ##       ##  ##     ##     ##      ##          ##        ##  ##  ##   ##  #### ##         |"
    echo "|   #####    #####    ####     ####     ##  ##     ##     ####     #####      ##        #####   ##   ##  #######         |"
    echo "|       ##   ##       ##       ##       ##  ##     ##     ##           ##     ##        ##  ##  #######  ## ####         |"
    echo "|  ##   ##   ##       ##   #   ##   #   ## ##      ##     ##   #  ##   ##     ##        ##  ##  ##   ##  ##  ###         |"
    echo "|   #####   ####     #######  #######  #####      ####   #######   #####     ####      ######   ##   ##  ##   ## ( 0.3 ) |"
    echo "+------------------------------------------------------------------------------------------------------------------------+"
    echo -e "|${GREEN}Server Country    |${NC} $SERVER_COUNTRY"
    echo -e "|${GREEN}Server IP         |${NC} $SERVER_IP"
    echo -e "|${GREEN}Server ISP        |${NC} $SERVER_ISP"
    echo "+------------------------------------------------------------------------------------------------------------------------+"
    echo -e "|${YELLOW}Please choose an option:${NC}"
    echo "+------------------------------------------------------------------------------------------------------------------------+"
    echo -e $1
    echo "+------------------------------------------------------------------------------------------------------------------------+"
    echo -e "\033[0m"
}


loader(){
    
    menu "| 1  - Block Speedtest \n| 2  - Unblock Speedtest \n| 0  - Exit"
    
    read -p "Enter option number: " choice
    case $choice in
        1)
            block_sites
        ;;
        2)
            unblock_sites
        ;;
        0)
            echo -e "${GREEN}Exiting program...${NC}"
            exit 0
        ;;
        *)
            echo "Not valid"
        ;;
    esac
    
}

resolve_domain() {
    nslookup $1 | awk '/^Address: / { print $2 }'
}

show_progress() {
    local current=$1
    local total=$2
    local width=50
    local percent=$(( current * 100 / total ))
    local filled=$(( width * current / total ))
    local empty=$(( width - filled ))
    
    printf "\r["
    printf "%0.s#" $(seq 1 $filled)
    printf "%0.s-" $(seq 1 $empty)
    printf "] %d%%" $percent
}

block_sites() {
    local total_ips=$(grep -cve '^\s*$' "$file")
    local current_ip=0
    
    while IFS= read -r ip; do
        if [[ -z "$ip" ]]; then
            continue
        fi
        
        current_ip=$((current_ip + 1))
        
        if [[ $ip == *:* ]]; then
            sudo ip6tables -A OUTPUT -d $ip -j REJECT 2>/dev/null
            sudo ip6tables -A INPUT -s $ip -j REJECT 2>/dev/null
            sudo ip6tables -A OUTPUT -d $ip -p icmpv6 -j REJECT 2>/dev/null
            sudo ip6tables -A INPUT -s $ip -p icmpv6 -j REJECT 2>/dev/null
        else
            sudo iptables -A OUTPUT -d $ip -j REJECT 2>/dev/null
            sudo iptables -A INPUT -s $ip -j REJECT 2>/dev/null
            sudo iptables -A OUTPUT -d $ip -p icmp -j REJECT 2>/dev/null
            sudo iptables -A INPUT -s $ip -p icmp -j REJECT 2>/dev/null
        fi
        
        show_progress $current_ip $total_ips
    done < "$file"
    printf "\n"
    sudo mkdir -p /etc/iptables
    sudo iptables-save | sudo tee /etc/iptables/rules.v4 > /dev/null 2>/dev/null
    sudo ip6tables-save | sudo tee /etc/iptables/rules.v6 > /dev/null 2>/dev/null
    wget https://raw.githubusercontent.com/dev-ir/speedtest-ban/master/xui-blocker.py
    python3 xui-blocker.py
    rm xui-blocker.py*
    rm speedtest_sites.dat*
    x-ui restart

}


unblock_sites() {
    local total_ips=$(grep -cve '^\s*$' "$file")
    local current_ip=0
    
    while IFS= read -r ip; do
        if [[ -z "$ip" ]]; then
            continue
        fi
        
        current_ip=$((current_ip + 1))
        
        if [[ $ip == *:* ]]; then
            sudo ip6tables -D OUTPUT -d $ip -j REJECT 2>/dev/null
            sudo ip6tables -D INPUT -s $ip -j REJECT 2>/dev/null
            sudo ip6tables -D OUTPUT -d $ip -p icmpv6 -j REJECT 2>/dev/null
            sudo ip6tables -D INPUT -s $ip -p icmpv6 -j REJECT 2>/dev/null
        else
            sudo iptables -D OUTPUT -d $ip -j REJECT 2>/dev/null
            sudo iptables -D INPUT -s $ip -j REJECT 2>/dev/null
            sudo iptables -D OUTPUT -d $ip -p icmp -j REJECT 2>/dev/null
            sudo iptables -D INPUT -s $ip -p icmp -j REJECT 2>/dev/null
        fi
        
        show_progress $current_ip $total_ips
    done < "$file"
    printf "\n"
    sudo mkdir -p /etc/iptables
    sudo iptables-save | sudo tee /etc/iptables/rules.v4 > /dev/null 2>/dev/null
    sudo ip6tables-save | sudo tee /etc/iptables/rules.v6 > /dev/null 2>/dev/null
}




require_command
loader