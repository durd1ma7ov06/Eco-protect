#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
DESKTOP_DIR="$HOME/Desktop"
AUTOSTART_DIR="$HOME/.config/autostart"

chmod +x "$DIR/run_kiosk.sh"
chmod +x "$DIR/setup_rpi5.sh"
chmod +x "$DIR/EcoProject.desktop"

mkdir -p "$DESKTOP_DIR"
cp "$DIR/EcoProject.desktop" "$DESKTOP_DIR/"
chmod +x "$DESKTOP_DIR/EcoProject.desktop"

mkdir -p "$AUTOSTART_DIR"
cp "$DIR/EcoProject.desktop" "$AUTOSTART_DIR/"

echo "✅ EcoProject yorlig'i ish stoliga va tokka ulanganda yonishiga (Autostart) muvaffaqiyatli o'rnatildi!"
