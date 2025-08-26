#!/bin/bash

# Define color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Check if required commands are available
for cmd in systemctl ip macchanger netstat; do
    command -v $cmd &> /dev/null || { echo -e "${RED}Error: $cmd is not installed.${NC}"; exit 1; }
done

# Check service and module status
check_status() {
    local type="$1"
    local name="$2"
    if [[ "$type" == "service" ]]; then
        systemctl is-active --quiet "$name" && printf "${GREEN}%s active${NC}; " "$name" || printf "${RED}%s inactive${NC}; " "$name"
    else
        if [[ "$name" == "silk" ]]; then
            lsmod | grep -q "$name" && printf "${GREEN}%s loaded${NC}; " "$name" || printf "${RED}%s not loaded${NC}; " "$name"
        else
            lsmod | grep -q "$name" && printf "${RED}%s loaded${NC}; " "$name" || printf "${GREEN}%s not loaded${NC}; " "$name"
        fi
    fi
}

# Display statuses
for module in "uvcvideo" "bluetooth" "silk"; do check_status "module" "$module"; done
printf "\n"
for service in "usbguard.service" "tor.service"; do check_status "service" "$service"; done
printf "\n"

# Iterate through interfaces
for interface in $(ip link show | awk -F': ' '{print $2}' | grep -v lo); do
    echo -e "Interface: $interface"
    ip_address=$(ip addr show $interface | grep 'inet ' | awk '{print $2}' | cut -d'/' -f1)
    echo -e "IP: ${ip_address:-${YELLOW}Not assigned${NC}}"
    
    # Display MAC address
    mac_info=$(macchanger -s $interface)
    current_mac=$(echo "$mac_info" | grep "Current MAC" | awk '{print $3}')
    original_mac=$(echo "$mac_info" | grep "Permanent MAC" | awk '{print $3}')
    
    if [ "$current_mac" == "$original_mac" ]; then
        echo -e "${RED}Current MAC: $current_mac${NC}"
    else
        echo -e "${GREEN}Current MAC: $current_mac${NC}"
    fi
done

# Display open ports
printf "\n"
netstat -tuln | awk -v yellow="$YELLOW" -v green="$GREEN" -v nc="$NC" '
NR>2 {
    split($1, proto, "/");
    ip_port = $4;
    if (ip_port == "127.0.0.1:9050") {
        printf "%s%s %s%s\n", green, proto[1], ip_port, nc
    } else {
        printf "%s%s %s%s\n", yellow, proto[1], ip_port, nc
    }
}'
