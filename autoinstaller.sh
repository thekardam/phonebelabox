#!/bin/bash

# Auto-install script for BELABOX (100% compatible with the tutorial)
# Autorun: sudo ./belabox_installer.sh

set -e

# Konfiguracja
UBUNTU_VERSION="focal"         # Ubuntu 20.04
BELACODER_DIR="/root/belacoder"
BELAUI_DIR="/root/belaUI"
SRT_DIR="/root/srt"
SETUP_JSON_HW="rk3588"         # Zmień na swój sprzęt (np. raspberrypi)

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
# Krok 1: Aktualizacja Ubuntu do 20.04 LTS
# =====================================================================
step "Aktualizacja Ubuntu do 20.04 LTS (Focal Fossa)"

cp /etc/apt/sources.list /etc/apt/sources.list.bak
sed -i 's/jammy/focal/g' /etc/apt/sources.list

# Automatyczna odpowiedź na pytanie o konfigurację SSH
echo "libc6 libraries/restart-without-asking boolean true" | debconf-set-selections

DEBIAN_FRONTEND=noninteractive apt update -y
DEBIAN_FRONTEND=noninteractive apt full-upgrade -y
apt autoremove -y

# =====================================================================
# Krok 2: Konfiguracja SFTP (opcjonalne hasło root)
# =====================================================================
step "Konfiguracja dostępu SFTP"
read -p "Ustawić hasło root dla SFTP? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    passwd root
fi

# =====================================================================
# Krok 3: Instalacja zależności dla belacoder
# =====================================================================
step "Instalacja zależności"
apt install -y \
    build-essential git \
    libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev \
    libsrt-dev nano tcl libssl-dev nodejs npm usb-modeswitch

# =====================================================================
# Krok 4: Kompilacja belacoder (+ SRT jeśli wymagane)
# =====================================================================
step "Kompilacja belacoder"

compile_belacoder() {
    cd "$BELACODER_DIR"
    make || {
        info "Kompilacja belacoder nieudana - budowanie SRT..."
        cd /root
        git clone https://github.com/BELABOX/srt.git
        cd srt
        ./configure --prefix=/usr/local
        make -j$(nproc)
        make install
        ldconfig
        cd "$BELACODER_DIR"
        make
    }
}

[ -d "$BELACODER_DIR" ] || git clone https://github.com/BELABOX/belacoder.git "$BELACODER_DIR"
compile_belacoder
chmod +x "${BELACODER_DIR}/belacoder"

# =====================================================================
# Krok 5: Instalacja belaUI
# =====================================================================
step "Instalacja belaUI"

# Instalacja zależności
apt install -y libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev

# Klonowanie repozytorium
[ -d "$BELAUI_DIR" ] || git clone https://github.com/BELABOX/belaUI.git "$BELAUI_DIR"
cd "$BELAUI_DIR"
git checkout ws_nodejs

# Tworzenie package.json
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

# Instalacja modułów Node.js
npm install

# =====================================================================
# Krok 6: Konfiguracja setup.json
# =====================================================================
step "Tworzenie pliku konfiguracyjnego"

cat > "${BELAUI_DIR}/setup.json" << EOF
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
SUKCES! BELABOX został zainstalowany.

Aby uruchomić:
1. Przejdź do katalogu belaUI:
   ${YELLOW}cd ${BELAUI_DIR}${GREEN}
2. Uruchom interfejs:
   ${YELLOW}node belaUI.js${GREEN}

Dostęp przez przeglądarkę: ${YELLOW}http://<IP-telefonu>:8080${GREEN}

Weryfikacja wersji Ubuntu: ${YELLOW}lsb_release -a${GREEN}
===========================================================${NC}"
