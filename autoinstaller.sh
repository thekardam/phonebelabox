#!/bin/bash

# Auto-install script for BELABOX (z SRTLA i net-tools)
# Run as root: sudo ./belabox_installer.sh

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

# Sprawdź root
[ "$EUID" -ne 0 ] && error "Uruchom skrypt jako root (sudo $0)"

# =====================================================================
# Krok 1: Aktualizacja Ubuntu
# =====================================================================
step "Aktualizacja Ubuntu do 20.04"

CURRENT_CODENAME=$(lsb_release -cs)
sed -i "s/${CURRENT_CODENAME}/${UBUNTU_TARGET}/g" /etc/apt/sources.list

DEBIAN_FRONTEND=noninteractive apt update -y
DEBIAN_FRONTEND=noninteractive apt full-upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"
apt autoremove -y

# =====================================================================
# Krok 2: Konfiguracja SFTP
# =====================================================================
step "Konfiguracja SFTP"
read -p "Ustawić hasło root? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    until passwd root; do
        echo -e "${RED}Błąd, spróbuj ponownie${NC}"
    done
fi

# =====================================================================
# Krok 3: Zależności systemowe
# =====================================================================
step "Instalacja zależności"
apt install -y \
    net-tools build-essential git nano tcl libssl-dev \
    libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev \
    usb-modeswitch curl

# =====================================================================
# Krok 4: Kompilacja SRT
# =====================================================================
step "Kompilacja SRT"
cd /root
git clone "${SRT_REPO}"
cd srt
./configure --prefix=/usr/local
make -j$(nproc)
make install
ldconfig

# =====================================================================
# Krok 4.5: Kompilacja SRTLA
# =====================================================================
step "Kompilacja SRTLA"
cd /root
git clone https://github.com/BELABOX/srtla.git
cd srtla
make
chmod +x srtla

# =====================================================================
# Krok 5: Kompilacja belacoder
# =====================================================================
step "Kompilacja belacoder"
cd /root
git clone https://github.com/BELABOX/belacoder.git
cd belacoder
make
chmod +x belacoder

# =====================================================================
# Krok 6: Instalacja belaUI
# =====================================================================
step "Instalacja belaUI"
cd /root
git clone https://github.com/BELABOX/belaUI.git
cd belaUI
git checkout ws_nodejs

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
# Krok 6.5: Instalacja Node.js 21
# =====================================================================
step "Instalacja Node.js 21 via NVM"

# Instalacja NVM
curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" | bash

# Ładowanie NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Node.js 21
nvm install ${NODE_VERSION}
nvm use ${NODE_VERSION}

# Aktualizacja systemowego Node
ln -sf "$NVM_DIR/versions/node/v${NODE_VERSION}.*/bin/node" /usr/local/bin/node
ln -sf "$NVM_DIR/versions/node/v${NODE_VERSION}.*/bin/npm" /usr/local/bin/npm
npm install

# =====================================================================
# Krok 7: Konfiguracja setup.json
# =====================================================================
step "Tworzenie setup.json"
cat > setup.json << EOF
{
  "hw": "${SETUP_JSON_HW}",
  "belacoder_path": "${BELACODER_DIR}/",
  "srtla_path": "/root/srtla/",
  "bitrate_file": "/tmp/belacoder_br",
  "ips_file": "/tmp/srtla_ips"
}
EOF

# =====================================================================
# Końcowa konfiguracja
# =====================================================================
step "Instalacja zakończona!"

echo -e "${GREEN}
===========================================================
SUKCES! Wszystkie komponenty zainstalowane:
- SRT  $(srt-live-transmit --version | head -n1)
- SRTLA $(/root/srtla/srtla -v)
- Node.js $(node -v)

Uruchomienie: 
cd ${BELAUI_DIR} && node belaUI.js
===========================================================${NC}"
