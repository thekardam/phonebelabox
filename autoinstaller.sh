#!/bin/bash

# Auto-install script for BELABOX (pełna wersja)
# Autor: BELABOX Community | Ostatnia aktualizacja: 2023-11-05
# Uruchom jako root: sudo ./belabox_installer.sh

set -e

# Konfiguracja
UBUNTU_TARGET="focal"
BELACODER_DIR="/root/belacoder"
BELAUI_DIR="/root/belaUI"
SRT_REPO="https://github.com/Haivision/srt.git"
SETUP_JSON_HW="rk3588"
NVM_VERSION="v0.39.7"
NODE_VERSION="21"

# Kolory
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

error() { echo -e "${RED}[BŁĄD] $1${NC}"; exit 1; }
step() { echo -e "${GREEN}[KROK] $1${NC}"; }
info() { echo -e "${YELLOW}[INFO] $1${NC}"; }

# =====================================================================
# Sprawdzenie uprawnień
# =====================================================================
if [ "$EUID" -ne 0 ]; then
    error "Uruchom skrypt jako root: sudo $0"
fi

# =====================================================================
# Krok 1: Aktualizacja systemu do Ubuntu 20.04
# =====================================================================
step "1/9 ▸ Aktualizacja do Ubuntu 20.04 Focal"

current_codename=$(lsb_release -cs)
if [ "$current_codename" != "$UBUNTU_TARGET" ]; then
    sed -i "s/${current_codename}/${UBUNTU_TARGET}/g" /etc/apt/sources.list
    DEBIAN_FRONTEND=noninteractive apt update -y
    DEBIAN_FRONTEND=noninteractive apt full-upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"
    apt autoremove -y
else
    info "System już używa Ubuntu 20.04, pomijam aktualizację"
fi

# =====================================================================
# Krok 2: Konfiguracja dostępu SFTP
# =====================================================================
step "2/9 ▸ Konfiguracja SFTP"
read -p "Ustawić hasło root? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    until passwd root; do
        echo -e "${RED}Błąd przy zmianie hasła, spróbuj ponownie${NC}"
    done
fi

# =====================================================================
# Krok 3: Instalacja zależności systemowych
# =====================================================================
step "3/9 ▸ Instalacja pakietów systemowych"
apt install -y \
    net-tools build-essential git nano tcl libssl-dev \
    libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev \
    usb-modeswitch curl cmake pkg-config yasm \
    zlib1g-dev libssl-dev libnuma-dev

# =====================================================================
# Krok 4: Kompilacja SRT
# =====================================================================
step "4/9 ▸ Kompilacja SRT"
cd /root
if [ -d "srt" ]; then
    info "Wykryto istniejącą instalację SRT, usuwam..."
    rm -rf srt
fi
git clone "$SRT_REPO"
cd srt
./configure --prefix=/usr/local
make -j$(nproc)
make install
ldconfig

# =====================================================================
# Krok 5: Kompilacja SRTLA
# =====================================================================
step "5/9 ▸ Kompilacja SRTLA"
cd /root
if [ -d "srtla" ]; then
    info "Wykryto istniejącą instalację SRTLA, usuwam..."
    rm -rf srtla
fi
git clone https://github.com/BELABOX/srtla.git
cd srtla
make


# =====================================================================
# Krok 6: Instalacja belacoder
# =====================================================================
step "6/9 ▸ Instalacja belacoder"
cd /root
if [ -d "belacoder" ]; then
    info "Wykryto istniejącą instalację belacoder, usuwam..."
    rm -rf belacoder
fi
git clone https://github.com/BELABOX/belacoder.git
cd belacoder
make
chmod +x belacoder

# =====================================================================
# Krok 7: Instalacja belaUI
# =====================================================================
step "7/9 ▸ Instalacja belaUI"
cd /root
if [ -d "belaUI" ]; then
    info "Wykryto istniejącą instalację belaUI, usuwam..."
    rm -rf belaUI
fi
git clone https://github.com/BELABOX/belaUI.git
cd belaUI
git checkout ws_nodejs

# Konfiguracja package.json
cat > package.json << 'EOF'
{
  "dependencies": {
    "serve-static": "^1.14.1",
    "finalhandler": "^1.1.2",
    "bcrypt": "^5.1.1",
    "ws": "^7.4.4"
  }
}
EOF

# =====================================================================
# Krok 8: Instalacja Node.js 21
# =====================================================================
step "8/9 ▸ Konfiguracja Node.js"

# Instalacja NVM
export NVM_DIR="/root/.nvm"
curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" | bash

# Ładowanie NVM
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Instalacja Node.js
nvm install "$NODE_VERSION"
nvm use "$NODE_VERSION"

# Aktualizacja systemowych linków
ln -sf "$NVM_DIR/versions/node/v${NODE_VERSION}."*/bin/node /usr/local/bin/node
ln -sf "$NVM_DIR/versions/node/v${NODE_VERSION}."*/bin/npm /usr/local/bin/npm

# Instalacja zależności
npm install

# =====================================================================
# Krok 9: Konfiguracja końcowa
# =====================================================================
step "9/9 ▸ Finalizacja instalacji"

# Tworzenie pliku konfiguracyjnego
cat > setup.json << EOF
{
  "hw": "${SETUP_JSON_HW}",
  "belacoder_path": "${BELACODER_DIR}/",
  "srtla_path": "/root/srtla/",
  "bitrate_file": "/tmp/belacoder_br",
  "ips_file": "/tmp/srtla_ips"
}
EOF

# Nadawanie praw
chmod 755 /root /root/*

# =====================================================================
# Komunikat końcowy
# =====================================================================
ip_address=$(hostname -I | awk '{print $1}')
echo -e "${GREEN}
▓█████▄  ██▀███   ██▓███   ██████  ██████  ▒█████  ██▓███ 
▒██▀ ██▌▓██ ▒ ██▒▓██░  ██▒▒██    ▒ ▒██    ▒ ▒██▒  ██▒▓██░  ██▒
░██   █▌▓██ ░▄█ ▒▓██░ ██▓▒░ ▓██▄   ░ ▓██▄   ▒██░  ██▒▓██░ ██▓▒
░▓█▄   ▌▒██▀▀█▄  ▒██▄█▓▒ ▒  ▒   ██▒  ▒   ██▒▒██   ██░▒██▄█▓▒ ▒
░▒████▓ ░██▓ ▒██▒▒██▒ ░  ░▒██████▒▒▒██████▒▒░ ████▓▒░▒██▒ ░  ░
 ▒▒▓  ▒ ░ ▒▓ ░▒▓░▒▓▒░ ░  ░▒ ▒▓▒ ▒ ░▒ ▒▓▒ ▒ ░░ ▒░▒░▒░ ▒▓▒░ ░  ░
 ░ ▒  ▒   ░▒ ░ ▒░░▒ ░     ░ ░▒  ░ ░░ ░▒  ░ ░  ░ ▒ ▒░ ░▒ ░    
 ░ ░  ░   ░░   ░ ░░       ░  ░  ░  ░  ░  ░  ░ ░ ░ ▒  ░░      
   ░       ░                    ░        ░      ░ ░           
 ░                                                            
                                                                          
===========================================================
INSTALACJA ZAKOŃCZONA SUKCESEM!

Adres IP systemu: ${YELLOW}${ip_address}${GREEN}
Port interfejsu web: ${YELLOW}8080${GREEN}

Uruchomienie:
${YELLOW}cd ${BELAUI_DIR} && node belaUI.js${GREEN}

Wersje komponentów:
- SRT:    $(srt-live-transmit --version | head -n1)
- SRTLA:  $(/root/srtla/srtla -v | awk '{print $2}')
- Node.js: $(node -v)
===========================================================${NC}"
