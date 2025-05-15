#!/bin/bash

# ╔════════════════════════════════════════════════════════╗
# ║           Universal Printer Auto-Installer v1.0        ║
# ║              Creador: Santana Oliva                    ║
# ║      GitHub: https://github.com/santanaoliva          ║
# ╚════════════════════════════════════════════════════════╝

APP_NAME="printerwiz"
VERSION="1.0"
GITHUB_URL="https://github.com/santanaoliva"

clear
echo -e "\e[1;34m"
echo "██████╗ ██████╗ ██╗███╗   ██╗████████╗███████╗██████╗ ██╗    ██╗██╗███████╗"
echo "██╔══██╗██╔══██╗██║████╗  ██║╚══██╔══╝██╔════╝██╔══██╗██║    ██║██║██╔════╝"
echo "██████╔╝██████╔╝██║██╔██╗ ██║   ██║   █████╗  ██████╔╝██║ █╗ ██║██║███████╗"
echo "██╔═══╝ ██╔═══╝ ██║██║╚██╗██║   ██║   ██╔══╝  ██╔═══╝ ██║███╗██║██║╚════██║"
echo "██║     ██║     ██║██║ ╚████║   ██║   ███████╗██║     ╚███╔███╔╝██║███████║"
echo "╚═╝     ╚═╝     ╚═╝╚═╝  ╚═══╝   ╚═╝   ╚══════╝╚═╝      ╚══╝╚══╝ ╚═╝╚══════╝"
echo -e "\e[0m"
echo "👉 Versión $VERSION | Creador: Santana Oliva"
echo "🌐 GitHub: $GITHUB_URL"
echo ""

sleep 1
echo "🔍 Detectando sistema operativo y entorno..."

OS=""
PM=""
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
fi

case "$OS" in
    arch|manjaro|blackarch)
        PM="sudo pacman -Sy --noconfirm"
        INSTALL_PKGS="cups cups-pdf cups-filters system-config-printer avahi nss-mdns xorg-xwayland"
        ;;
    debian|ubuntu|kali|parrot)
        PM="sudo apt update && sudo apt install -y"
        INSTALL_PKGS="cups cups-pdf printer-driver-all avahi-daemon libnss-mdns x11-utils"
        ;;
    fedora)
        PM="sudo dnf install -y"
        INSTALL_PKGS="cups cups-pdf system-config-printer avahi nss-mdns"
        ;;
    opensuse*)
        PM="sudo zypper install -y"
        INSTALL_PKGS="cups cups-pdf system-config-printer avahi nss-mdns"
        ;;
    *)
        echo "⚠️  Sistema operativo no soportado directamente. Intentando con paquetes básicos..."
        PM="sudo apt install -y"
        INSTALL_PKGS="cups avahi-daemon"
        ;;
esac

echo "📦 Instalando dependencias con: $PM"
eval "$PM $INSTALL_PKGS"

echo "🛠️ Activando servicios..."
sudo systemctl enable --now cups.service || true
sudo systemctl enable --now avahi-daemon.service || true

echo "🔧 Configurando mDNS en /etc/nsswitch.conf..."
if grep -q '^hosts:' /etc/nsswitch.conf; then
    sudo sed -i 's/^hosts:.*/hosts: files mdns_minimal [NOTFOUND=return] dns/' /etc/nsswitch.conf
fi

echo "🔎 Buscando impresoras de red (Epson, IPP)..."
PRINTER_URI=$(lpinfo -v | grep -Eo 'ipps?://[^ ]+' | grep -i 'epson' | head -n 1)

if [ -z "$PRINTER_URI" ]; then
    echo "❌ No se encontró una impresora en red. Verifica que esté encendida y conectada al router."
    exit 1
fi

echo "✅ Impresora detectada: $PRINTER_URI"

echo "🖨️ Añadiendo impresora EpsonL1250 al sistema..."
sudo lpadmin -p EpsonL1250 -E -v "$PRINTER_URI" -m everywhere
sudo lpoptions -d EpsonL1250

echo "📌 Impresora EpsonL1250 configurada como predeterminada."

# Instalar el comando como binario global
BIN_PATH="/usr/local/bin/$APP_NAME"
if [ "$EUID" -ne 0 ]; then
    echo "🔁 Requiere privilegios para instalar como comando del sistema..."
    sudo cp --force "$0" "$BIN_PATH"
    sudo chmod +x "$BIN_PATH"
else
    cp --force "$0" "$BIN_PATH"
    chmod +x "$BIN_PATH"
fi

echo ""
echo -e "\e[1;32m✅ Instalación completada. Puedes usar este instalador en cualquier momento con el comando: \e[0;33m$APP_NAME\e[0m"
echo ""
