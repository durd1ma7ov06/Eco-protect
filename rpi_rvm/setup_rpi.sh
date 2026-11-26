#!/bin/bash
# ==============================================================
# Eco RVM - Raspberry Pi 4 Avtomatik Sozlash Skripti
# ==============================================================

set -e

echo "🚀 [1/5] Tizim yangilanmoqda va kerakli paketlar o'rnatilmoqda..."
sudo apt update && sudo apt upgrade -y
sudo apt install -y python3-pip python3-venv libgl1-mesa-glx libglib2.0-0 unclutter pigpio python3-pigpio chromium-browser

echo "⚡ [2/5] pigpiod (Servo aniq ishlashi uchun) xizmati faollashtirilmoqda..."
sudo systemctl enable pigpiod
sudo systemctl start pigpiod

echo "🐍 [3/5] Python Virtual Muhit (venv) yaratilmoqda..."
python3 -m venv venv
source venv/bin/activate

echo "📦 [4/5] Python kutubxonalari o'rnatilmoqda..."
pip install --upgrade pip
pip install -r requirements.txt

# YOLOv8 nano modelini oldindan yuklab qo'yish
echo "🧠 [5/5] YOLOv8n modelini tayyorlash..."
python3 -c "from ultralytics import YOLO; YOLO('yolov8n.pt')"

echo "✅ O'rnatish muvaffaqiyatli yakunlandi!"
echo "Ishga tushirish uchun: ./run_kiosk.sh"
