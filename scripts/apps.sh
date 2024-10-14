#!/bin/bash

#apt_sources_edit() {
#    sources_file=/etc/apt/sources.list
#    sudo sed -i -e 's+bookworm main+bookworm main contrib non-free+g' "$sources_file"
#    sudo sed -i -e 's+bookworm-updates main+bookworm-updates main contrib non-free+g' "$sources_file"
#    if [ `grep backports $sources_file | wc -l` -eq 0 ]; then
#        sudo sed -i -e '$adeb http://ftp.us.debian.org/debian/ bookworm-backports main contrib non-free non-free-firmware' "$sources_file"
#    fi
#}


xdg_update_dirs() {
    rm -r ~/Pictures ~/Public ~/Templates ~/Videos ~/Music ~/Desktop
    xdg-user-dirs-update
    mv ~/Downloads ~/downloads
    mv ~/Documents ~/documents
    user_dirs_config=$HOME/.config/user-dirs.dirs
    sed -i -e 's+HOME/Downloads+HOME/downloads+g' "$user_dirs_config"
    sed -i -e 's+HOME/Documents+HOME/documents+g' "$user_dirs_config"
    xdg-user-dirs-update
}

wifi_powersave() {
    cat <<EOF | sudo tee /etc/NetworkManager/conf.d/wifi-powersave-off.conf
[connection]
wifi.powersave = 2 # 0=default 1=existing 2=disabled 3=enabled 
EOF
    sudo systemctl restart NetworkManager 2>&1
}

visual_studio() {
    curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor >microsoft.gpg
    sudo install -o root -g root -m 644 "$(pwd)/microsoft.gpg" /usr/share/keyrings/microsoft-archive-keyring.gpg
    echo "deb [arch=amd64,arm64,armhf signed-by=/usr/share/keyrings/microsoft-archive-keyring.gpg] https://packages.microsoft.com/repos/vscode stable main" | sudo tee /etc/apt/sources.list.d/vscode.list
    sudo apt update &&
    sudo apt install -y code
}

themes_install() {
    sudo apt install -y papirus-icon-theme bibata-cursor-theme
    sudo apt install -y fonts-hack fonts-recommended fonts-ubuntu fonts-liberation2 fonts-cantarell fonts-jetbrains-mono
    git clone https://github.com/EliverLara/Sweet.git /tmp/
    sudo mv /tmp/Sweet /usr/share/themes &&
    cd /usr/share/themes/Sweet &&
    sudo git checkout nova
}

plocate_update() {
    sudo updatedb && echo -e "now, u could use plocate %"
}

telegram_install() {
    wget https://telegram.org/dl/desktop/linux -O tsetup.tgz &&
    sudo mkdir -p /opt/Telegram &&
    sudo tar xf "$(pwd)"/tsetup.tgz -C /opt/Telegram --strip-components=1 &&
    rm "$(pwd)"/tsetup.tgz
    sudo ln -s /opt/Telegram/Telegram /usr/local/bin/telegram &&
    sudo ln -s /opt/Telegram/Updater /usr/local/bin/telegramUpdater
}

steam_install() {
    wget https://cdn.cloudflare.steamstatic.com/client/installer/steam.deb &&
    sudo gdebi "$(pwd)"/steam.deb &&
    rm "$(pwd)"/steam.deb
}

spotify_install() {
    curl -sS https://download.spotify.com/debian/pubkey_6224F9941A8AA6D1.gpg | sudo gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/spotify.gpg
    echo "deb http://repository.spotify.com stable non-free" | sudo tee /etc/apt/sources.list.d/spotify.list
    sudo apt update &&
    sudo apt install -y spotify-client
}

mega_install() {
    wget https://mega.nz/linux/repo/Debian_12/amd64/megasync-Debian_12_amd64.deb &&
    sudo gdebi "$(pwd)"/megasync-Debian_12_amd64.deb &&
    rm "$(pwd)"/megasync-Debian_12_amd64.deb
}

gammastep_install() {
    sudo apt intstall -y gammastep-indicator &&
    mkdir -p ~/.config/gammastep &&
    cp ./configs/gammastep.conf ~/.config/gammastep/
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
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc &&
    sudo chmod a+r /etc/apt/keyrings/docker.asc
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
    https://download.docker.com/linux/debian $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt update &&
    sudo apt install -y docker-ce docker-ce-cli containerd.io
    sudo usermod -aG docker $USER &&
    newgrp docker
    sudo systemctl enable docker.service &&
    sudo systemctl enable containerd.service
}

google_chrome_install() {
    wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb -O google-chrome-stable_current_amd64.deb &&
    sudo gdebi google-chrome-stable_current_amd64.deb && rm google-chrome-stable_current_amd64.deb
}

aliases_file() {
    cat << EOF | tee ~/.bash_aliases
alias ll='ls -lrth --color=auto'
alias LL='ls -lArth --color=auto'
alias LA='ls -lARth --color=auto'
alias df='df -h'
alias top='htop'
EOF
}

network_config() {
    interfaces_file=/etc/network/interfaces
    sudo sed -i -e 's+allow-hotplug+#allow-hotplug+g' "$interfaces_file"
    sudo sed -i -e 's+iface wlp61s0+#iface wlp61s0+g' "$interfaces_file"
    sudo sed -i -e 's+wpa-ssid+#wpa-ssid+g' "$interfaces_file"
    sudo sed -i -e 's+wpa-psk+#wpa-psk+g' "$interfaces_file"

    network_manager_file=/etc/NetworkManager/NetworkManager.conf
    sudo sed -i -e 's+managed=false+managed=true+g' "$network_manager_file"
}