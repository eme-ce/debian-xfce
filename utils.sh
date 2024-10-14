#!/bin/bash


initialize_script() {
    permission_and_os_verify
}

log() {
    msg="$@"
    echo -e "$(date +"%d/%m/%Y %R") - $msg"
}

log_err() {
    msg="$@"
    echo -e "$(date +"%d/%m/%Y %R") - $msg" && exit 1
}

permission_and_os_verify() {
    if [ "$EUID" -eq 0 ]; then
	    log_err "This script must not be executed as sudo"
    fi
    OS_DISTRO="$(lsb_release -si)"
    DEBIAN_VERSION="$(lsb_release -sr | cut -d. -f1)"
    if [ "$OS_DISTRO" != "Debian" ]; then
    	log_err "Linux distribution not supported"
    elif [ "$DEBIAN_VERSION" != "12" ]; then
	    log_err "Debian version not supported"
    fi
}

show_banner() {
    echo -e "                                                                                           "
    echo -e "██████  ███████ ██████  ██  █████  ███    ██               ██   ██ ███████  ██████ ███████ "
    echo -e "██   ██ ██      ██   ██ ██ ██   ██ ████   ██                ██ ██  ██      ██      ██      "
    echo -e "██   ██ █████   ██████  ██ ███████ ██ ██  ██     █████       ███   █████   ██      █████   "
    echo -e "██   ██ ██      ██   ██ ██ ██   ██ ██  ██ ██                ██ ██  ██      ██      ██      "
    echo -e "██████  ███████ ██████  ██ ██   ██ ██   ████               ██   ██ ██       ██████ ███████ "
    echo -e "                                                                                           "
    echo -e "                                                                                           "
}

show_options() {
	local choice
	read -p "Enter choice [ 1 - 3] " choice
	case $choice in
		1) one ;;
		2) two ;;
		3) exit 0;;
		*) echo -e "${RED}Error...${STD}" && sleep 2
	esac    
}

launch_menu() {
    while true;
    do
        show_banner
        show_options
    done
}

launch_menu