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

file="/root/sites.dat"


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
    wget https://raw.githubusercontent.com/dev-ir/speedtest-ban/master/sites.dat
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

    echo "+---------------------------------------------------------------------------------------------------------------------------+"
    echo "|   #####   ######   #######  #######  #####    ######## #######   #####   ########          ######     ###    ##   ##      |"
    echo "|  ##   ##   ##  ##   ##   #   ##   #   ## ##   ## ## ##  ##   #  ##   ##  ## ## ##           ##  ##   ## ##   ###  ##      |"
    echo "|  ##        ##  ##   ##       ##       ##  ##     ##     ##      ##          ##              ##  ##  ##   ##  #### ##      |"
    echo "|   #####    #####    ####     ####     ##  ##     ##     ####     #####      ##              #####   ##   ##  #######      |"
    echo "|       ##   ##       ##       ##       ##  ##     ##     ##           ##     ##              ##  ##  #######  ## ####      |"
    echo "|  ##   ##   ##       ##   #   ##   #   ## ##      ##     ##   #  ##   ##     ##              ##  ##  ##   ##  ##  ###      |"
    echo "|   #####   ####     #######  #######  #####      ####   #######   #####     ####            ######   ##   ##  ##   ##      |"
    echo "+---------------------------------------------------------------------------------------------------------------------------+"                                                                                                         
    echo -e "|${GREEN}Server Country    |${NC} $SERVER_COUNTRY"
    echo -e "|${GREEN}Server IP         |${NC} $SERVER_IP"
    echo -e "|${GREEN}Server ISP        |${NC} $SERVER_ISP"
    echo "+---------------------------------------------------------------------------------------------------------------------------+"
    echo -e "|${YELLOW}Please choose an option:${NC}"
    echo "+---------------------------------------------------------------------------------------------------------------------------+"
    echo -e $1
    echo "+---------------------------------------------------------------------------------------------------------------------------+"
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
    # dig +short $1
    # nslookup $1 | awk '/^Address: / { print $2 }'
}

block_sites() {
    while IFS= read -r site; do
        ips=$(resolve_domain $site)
        for ip in $ips; do
            sudo iptables -A OUTPUT -d $ip -j REJECT
            sudo iptables -A INPUT -s $ip -j REJECT
            echo "Blocked $site ($ip)"
        done
    done < "$file"
    sudo iptables-save | sudo tee /etc/iptables/rules.v4
}

unblock_sites() {
    while IFS= read -r site; do
        ips=$(resolve_domain $site)
        for ip in $ips; do
            sudo iptables -D OUTPUT -d $ip -j REJECT
            sudo iptables -D INPUT -s $ip -j REJECT
            echo "Unblocked $site ($ip)"
        done
    done < "$file"
    sudo iptables-save | sudo tee /etc/iptables/rules.v4
}

check_block_status() {
    while IFS= read -r site; do
        ips=$(resolve_domain $site)
        blocked="false"
        for ip in $ips; do
            output=$(sudo iptables -L -v -n | grep $ip)
            if [[ -n $output ]]; then
                blocked="true"
                break
            fi
        done

        if [[ $blocked == "true" ]]; then
            echo "$site is Enable"
        else
            echo "$site is Disable"
        fi
    done < "$file"
}
require_command
loader