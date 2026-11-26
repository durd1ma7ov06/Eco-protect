#!/bin/bash
# ==============================================================================
# EcoProject - Raspberry Pi 5 Avtomatik O'rnatish Skripti (Debian Bookworm/Trixie)
# ==============================================================================

set -e

echo "🚀 [1/6] Raspberry Pi 5 paketlar ro'yxati yangilanmoqda..."
sudo apt update

echo "📦 [2/6] RPi 5 tizim kutubxonalari va drayverlari o'rnatilmoqda..."
# RPi 5 Debian Trixie / Bookworm uchun moslangan
sudo apt install -y python3-pip python3-venv python3-gpiozero python3-lgpio libgl1 unclutter chromium 2>/dev/null || \
sudo apt install -y python3-pip python3-venv python3-gpiozero python3-lgpio libgl1 unclutter chromium-browser 2>/dev/null || \
sudo apt install -y python3-pip python3-venv python3-gpiozero python3-lgpio chromium

echo "🐍 [3/6] Python Virtual Muhit (venv) yaratilmoqda..."
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "$DIR"

# --system-site-packages orqali RPi 5 ning apparat drayverlari ulanadi
python3 -m venv venv --system-site-packages
source venv/bin/activate

echo "⚡ [4/6] Python kutubxonalari o'rnatilmoqda..."
pip install --upgrade pip

# Keraksiz va zararlangan nvidia fayllarini o'chirish (RPi 5 ga faqat CPU kerak)
rm -rf venv/lib/python*/site-packages/nvidia* 2>/dev/null || true

pip install -r requirements.txt

# Qaytadan nvidia papkasi kelsa darhol tozalash
rm -rf venv/lib/python*/site-packages/nvidia* 2>/dev/null || true

echo "🧠 [5/6] YOLOv8n modeli keshga yuklanmoqda..."
python3 -c "from ultralytics import YOLO; YOLO('yolov8n.pt')"

echo "🖥️ [6/6] Ish stoli yorlig'i va tokka ulanganda avtomatik yonish sozlanmoqda..."
chmod +x setup_rpi5.sh run_kiosk.sh install_autostart_rpi.sh
./install_autostart_rpi.sh

echo "=============================================================================="
echo "🎉 HAMMASI MUVAFFAQIYATLI O'RNATILDI!"
echo "Raspberry Pi 5 endi har safar tokka ulanganda avtomatik to'liq ekranda yonadi."
echo "Hozir ishga tushirish uchun: ./run_kiosk.sh"
echo "=============================================================================="
