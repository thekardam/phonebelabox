#!/bin/bash

# Auto-install script for BELABOX (100% compilation, no prebuilt SRT)
# Run as root: sudo ./belabox_installer.sh

set -e

# Konfiguracja
UBUNTU_TARGET="focal"          # Ubuntu 20.04
BELACODER_DIR="/root/belacoder"
BELAUI_DIR="/root/belaUI"
SRT_REPO="https://github.com/Haivision/srt.git"
SETUP_JSON_HW="rk3588"         # Zmień na swój sprzęt

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
# Krok 1: Wymuś aktualizację do Ubuntu 20.04
# =====================================================================
step "Wymuszanie aktualizacji do Ubuntu 20.04"

# Pobierz aktualną wersję Ubuntu
CURRENT_CODENAME=$(lsb_release -cs)

# Zmień WSZYSTKIE referencje do obecnej wersji na 'focal'
sed -i "s/${CURRENT_CODENAME}/${UBUNTU_TARGET}/g" /etc/apt/sources.list

# Aktualizuj system
DEBIAN_FRONTEND=noninteractive apt update -y
DEBIAN_FRONTEND=noninteractive apt full-upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"
apt autoremove -y

# =====================================================================
# Krok 2: Konfiguracja SFTP
# =====================================================================
step "Konfiguracja dostępu SFTP"
read -p "Ustawić hasło root dla SFTP? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    until passwd root; do
        echo -e "${RED}Błąd przy zmianie hasła, spróbuj ponownie${NC}"
    done
fi

# =====================================================================
# Krok 3: Instalacja podstawowych zależności
# =====================================================================
step "Instalacja zależności systemowych"
apt install -y \
    build-essential git nano tcl libssl-dev \
    nodejs npm usb-modeswitch \
    libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev

# =====================================================================
# Krok 4: Kompilacja SRT
# =====================================================================
step "Kompilacja SRT z kodu źródłowego"

# Instalacja zależności SRT
apt install -y cmake pkg-config

# Ściągnij i skompiluj SRT
cd /root
git clone "${SRT_REPO}"
cd srt
./configure --prefix=/usr/local
make -j$(nproc)
make install
ldconfig

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

# Utwórz package.json
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

# Instalacja modułów
npm install

# =====================================================================
# Krok 7: Konfiguracja setup.json
# =====================================================================
step "Tworzenie pliku konfiguracyjnego"

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
step "Instalacja zakończona pomyślnie!"

echo -e "${GREEN}
===========================================================
SUKCES! BELABOX został zainstalowany.

Aby uruchomić:
1. Przejdź do katalogu belaUI:
   ${YELLOW}cd ${BELAUI_DIR}${GREEN}
2. Uruchom interfejs:
   ${YELLOW}node belaUI.js${GREEN}

Dostęp przez przeglądarkę: ${YELLOW}http://<IP-telefonu>:8080${GREEN}

Weryfikacja systemu:
${YELLOW}lsb_release -a${GREEN} (powinno pokazać Ubuntu 20.04)
${YELLOW}which belacoder${GREEN} (powinno pokazać ${BELACODER_DIR}/belacoder)
===========================================================${NC}"
