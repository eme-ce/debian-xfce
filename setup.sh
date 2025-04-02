#!/bin/bash

set -x

xfce_desktop=(xfce4 xfce4-power-manager xfce4-weather-plugin xfce4-screenshooter thunar-volman thunar-archive-plugin xscreensaver network-manager network-manager-gnome bluetooth blueman bluez pulseaudio pavucontrol pulseaudio-module-bluetooth)
utils=(curl plocate zip unzip rar unrar p7zip-full git ffmpeg wget gpg fwupd gufw nmap gdebi htop qt5ct adwaita-qt rsync)
dev_tools=(gcc make linux-headers-$(uname -r) build-essential python3 python3-pip python3-venv)
firmwares=(firmware-realtek firmware-atheros firmware-iwlwifi firmware-linux-nonfree)
applications=(vlc transmission gparted bleachbit menulibre filezilla ristretto)

log() {
    echo -e "$(date +"%d/%m/%Y %R") - $@"
}

log_err() {
    echo -e "$(date +"%d/%m/%Y %R") - $@" &&
    exit 1
}

if [ "$EUID" -eq 0 ]; then
    log_err "This script must not be executed as sudo"
fi

distro="$(lsb_release -si)"
ver_num="$(lsb_release -sr | cut -d. -f1)"

if [ "$distro" != "Debian" ]; then
    log_err "Linux distribution not supported"
elif [ "$ver_num" != "12" ]; then
    log_err "Version not supported"
fi

install_system_packages() {
    sudo apt install -y ${xfce_desktop[@]} &&
    sudo apt install -y ${utils[@]} &&
    sudo apt install -y ${dev_tools[@]} &&
    sudo apt install -y ${firmwares[@]} &&
    sudo apt install -y ${applications[@]}
}

apt_sources_edit() {
    local sources_file="/etc/apt/sources.list"
    sudo sed -i -e '/bookworm main( |$)/ s/bookworm main/bookworm main contrib non-free/;/bookworm-updates main( |$)/ s/bookworm-updates main/bookworm-updates main contrib non-free/' "$sources_file"
    grep -q 'bookworm-backports' "$sources_file" || 
    echo 'deb http://ftp.us.debian.org/debian/ bookworm-backports main contrib non-free non-free-firmware' | 
    sudo tee -a "$sources_file" > /dev/null
}

update_home_dir() {
    local config_file="$HOME/.config/user-dirs.dirs"

    if xdg-user-dirs-update; then
        local folder_list=(Pictures Public Templates Videos Music Desktop)

        for folder in "${folder_list[@]}"; do
            [ -d "$HOME/$folder" ] && rm -rf "$HOME/$folder"
        done

        for dir in "Downloads downloads" "Documents documents"; do
            set -- $dir
            [ -d "$HOME/$1" ] && mv "$HOME/$1" "$HOME/$2"
        done

        sed -i 's|HOME/Downloads|HOME/downloads|g' "$config_file"
        sed -i 's|HOME/Documents|HOME/documents|g' "$config_file"

        xdg-user-dirs-update
    else
        echo "Error: No se pudo ejecutar xdg-user-dirs-update" >&2
        return 1
    fi
    ln -s "$HOME/.config" "$HOME/config" && log "Created: $HOME/.config"
}

wifi_powersave() {
    local config_file="/etc/NetworkManager/conf.d/wifi-powersave-off.conf"

    echo "[connection]
wifi.powersave = 2 # 0=default 1=existing 2=disabled 3=enabled" | 
    sudo tee "$config_file" > /dev/null
 
    sudo chmod 644 "$config_file"
    if sudo systemctl restart NetworkManager; then
        echo "WiFi powersave deshabilitado correctamente."
    else
        echo "Error: No se pudo reiniciar NetworkManager." >&2
        return 1
    fi
}

visual_studio() {
    temp_key=$(mktemp)
    curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | sudo tee "$temp_key" > /dev/null
    sudo install -o root -g root -m 644 "$temp_key" /usr/share/keyrings/microsoft-archive-keyring.gpg
    rm -f "$temp_key"

    echo "deb [arch=amd64,arm64,armhf signed-by=/usr/share/keyrings/microsoft-archive-keyring.gpg] \
    https://packages.microsoft.com/repos/vscode stable main" | sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null

    sudo apt update && sudo apt install -y code
}

themes_install() {
    sudo apt update && sudo apt install -y \
        papirus-icon-theme bibata-cursor-theme \
        fonts-hack fonts-recommended fonts-ubuntu fonts-liberation2 fonts-cantarell fonts-jetbrains-mono
    temp_dir=$(mktemp -d)
    git clone https://github.com/EliverLara/Sweet.git "$temp_dir/Sweet"
    sudo rsync -a "$temp_dir/Sweet" /usr/share/themes/
    sudo git -C /usr/share/themes/Sweet checkout nova && rm -rf "$temp_dir" && log "Instalación completada exitosamente."   
}

plocate_update() {
    sudo updatedb && echo -e "now, u could use plocate %"
}

telegram_install() {
    local temp_dir
    temp_dir=$(mktemp -d)
    echo "Descargando Telegram..." && curl -fsSL "https://telegram.org/dl/desktop/linux" -o "$temp_dir/tsetup.tgz"

    if [ ! -s "$temp_dir/tsetup.tgz" ]; then
        echo "Error: No se pudo descargar Telegram." >&2
        return 1
    fi

    echo "Instalando Telegram..." && sudo mkdir -p /opt/Telegram && sudo tar xf "$temp_dir/tsetup.tgz" -C /opt/Telegram --strip-components=1
    rm -rf "$temp_dir"
    
    sudo ln -sf /opt/Telegram/Telegram /usr/local/bin/telegram && sudo ln -sf /opt/Telegram/Updater /usr/local/bin/telegramUpdater
    echo "Telegram instalado correctamente."
}

steam_install() {
    wget https://cdn.cloudflare.steamstatic.com/client/installer/steam.deb &&
    sudo gdebi "$(pwd)"/steam.deb &&
    rm "$(pwd)"/steam.deb
}

spotify_install() {
    local keyring="/usr/share/keyrings/spotify-archive-keyring.gpg"
    local repo_file="/etc/apt/sources.list.d/spotify.list"

    echo "Descargando clave GPG de Spotify..."
    curl -fsSL "https://download.spotify.com/debian/pubkey_C85668DF69375001.gpg" | sudo gpg --dearmor -o "$keyring"
    sudo chmod 644 "$keyring"
    echo "deb [signed-by=$keyring] http://repository.spotify.com stable non-free" | sudo tee "$repo_file" > /dev/null
    sudo apt update && sudo apt install -y spotify-client && echo "Spotify instalado correctamente."
}

mega_install() {
    wget https://mega.nz/linux/repo/Debian_12/amd64/megasync-Debian_12_amd64.deb &&
    sudo gdebi "$(pwd)"/megasync-Debian_12_amd64.deb &&
    rm "$(pwd)"/megasync-Debian_12_amd64.deb
}

fingerprint_install() {
    wget https://launchpad.net/~uunicorn/+archive/ubuntu/open-fprintd/+files/fprintd-clients_1.90.1-1ubuntu3_amd64.deb -O fprintd-clients.deb &&
    wget https://launchpad.net/~/uunicorn/+archive/ubuntu/open-fprintd/+files/python3-validity_0.14~ppa1_all.deb -O python3-validity.deb &&
    wget https://launchpad.net/~/uunicorn/+archive/ubuntu/open-fprintd/+files/open-fprintd_0.6~ppa1_all.deb -O open-fprintd.deb

    sudo gdebi fprintd-clients.deb &&
    sudo gdebi open-fprintd.deb &&
    sudo gdebi python3-validity.deb &&

    cp configs/fingerprint-restart.service /etc/systemd/fingerprint-restart.service
    rm fprintd-clients.deb open-fprintd.deb python3-validity.deb
    sudo systemctl daemon-reload &&
    sudo systemctl enable fingerprint-restart.service &&
    sudo pam-auth-update
}

docker_install() {
    local keyring="/usr/share/keyrings/docker-archive-keyring.gpg"
    local repo_file="/etc/apt/sources.list.d/docker.list"

    echo "Configurando claves de Docker..."
    sudo install -m 0755 -d /usr/share/keyrings
    curl -fsSL "https://download.docker.com/linux/debian/gpg" | sudo gpg --dearmor -o "$keyring"

    sudo chmod 644 "$keyring"

    echo "Agregando repositorio de Docker..."
    echo "deb [arch=$(dpkg --print-architecture) signed-by=$keyring] \
    https://download.docker.com/linux/debian $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee "$repo_file" > /dev/null

    echo "Instalando Docker..."
    sudo apt update && sudo apt install -y docker-ce docker-ce-cli containerd.io

    echo "Agregando usuario al grupo docker..."
    sudo usermod -aG docker "$USER"

    echo "Habilitando y arrancando Docker..."
    sudo systemctl enable --now docker.service
    sudo systemctl enable --now containerd.service

    echo "Instalación de Docker completada. Es posible que necesites cerrar sesión y volver a entrar para que los cambios en el grupo 'docker' surtan efecto."
}

google_chrome_install() {
    wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb -O google-chrome-stable_current_amd64.deb &&
    sudo gdebi google-chrome-stable_current_amd64.deb && rm google-chrome-stable_current_amd64.deb
}

aliases_file() {
    echo "Configurando alias en ~/.bash_aliases..."

    cat << EOF > ~/.bash_aliases
alias ll='ls -lrth --color=auto'
alias LL='ls -lArth --color=auto'
alias LA='ls -lARth --color=auto'
alias df='df -h'
alias top='htop'
EOF

    if [[ $- == *i* ]]; then
        echo "Recargando ~/.bash_aliases..."
        source ~/.bash_aliases
    fi

    echo "Alias configurados correctamente."
}

network_config() {
    readonly interfaces_file="/etc/network/interfaces"
    readonly network_manager_file="/etc/NetworkManager/NetworkManager.conf"

    if [[ ! -f "$interfaces_file" ]]; then
        log_err "Error: No se encontró $interfaces_file"
    fi

    if [[ ! -f "$network_manager_file" ]]; then
        log_err "Error: No se encontró $network_manager_file"
    fi

    echo "Deshabilitando configuración manual en $interfaces_file..."
    sudo sed -i -e 's+allow-hotplug+#allow-hotplug+g' "$interfaces_file"
    sudo sed -i -e 's+iface wlp61s0+#iface wlp61s0+g' "$interfaces_file"
    sudo sed -i -e 's+iface wlp6s0+#iface wlp6s0+g' "$interfaces_file"
    sudo sed -i -e 's+wpa-ssid+#wpa-ssid+g' "$interfaces_file"
    sudo sed -i -e 's+wpa-psk+#wpa-psk+g' "$interfaces_file"

    echo "Activando NetworkManager en $network_manager_file..."
    sudo sed -i -e 's/^managed=false/managed=true/' "$network_manager_file"

    echo "Configuración de red actualizada."

    read -p "restart NetworkManager now? (y/n): " answer
    if [[ "$answer" =~ ^[yY]$ ]]; then
        echo "Reiniciando NetworkManager..."
        sudo systemctl restart NetworkManager
    else
        echo "Recuerda reiniciar NetworkManager manualmente con: sudo systemctl restart NetworkManager"
    fi
}

vim_config() {
    mkdir -p ~/.vim ~/.vim/autoload ~/.vim/backup ~/.vim/colors ~/.vim/plugged
    if [[ ! -f ~/.vimrc ]]; then
        touch ~/.vimrc
    fi
    if awk '/set nocompatible/ {exit 1} END {exit 0}' ~/.vimrc; then
        cat << EOF > ~/.vimrc
set nocompatible
filetype on
filetype plugin on
filetype indent on
syntax on
set number
set cursorline
set shiftwidth=4
set tabstop=4
set expandtab
set nobackup
set scrolloff=10
set nowrap
set incsearch
set ignorecase
set smartcase
set showcmd
set showmode
set showmatch
set hlsearch
set history=1000
set wildmenu
set wildmode=list:longest
set wildignore=*.docx,*.jpg,*.png,*.gif,*.pdf,*.pyc,*.exe,*.flv,*.img,*.xlsx
EOF
    fi

    if [[ ! -f ~/.vim/autoload/plug.vim ]]; then
        plugin_url=https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
        curl -fLo ~/.vim/autoload/plug.vim --create-dirs "$plugin_url"
    fi

    if awk '/call plug/ {exit 1} END {exit 0}' ~/.vimrc; then
        cat << EOF >> ~/.vimrc
call plug#begin('~/.vim/plugged')
call plug#end()
EOF
    fi

}