#!/bin/bash
# ==============================================================================
# EcoProject - RPi 5 Kiosk Rejimida Ishga Tushirish (Wayland & X11 Moslashuvchan)
# ==============================================================================

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "$DIR"

# Virtual muhit mavjudligini tekshirish
if [ ! -d "venv" ]; then
  echo "⚠️ Virtual muhit topilmadi. Avval ./setup_rpi5.sh ni ishga tushiring!"
  exit 1
fi

source venv/bin/activate

# 1. Serverni orqa fonda ishga tushirish
echo "🚀 EcoProject RVM Server ishga tushirilmoqda..."
python3 -m uvicorn server:app --host 0.0.0.0 --port 8000 &
SERVER_PID=$!

# Server to'liq yuklanishi uchun 4 soniya kutish
sleep 4

# 2. Sensorli ekranda kursor ko'rinmasligi uchun yashirish
if command -v unclutter &> /dev/null; then
  unclutter -idle 0.5 -root &
fi

# 3. Brauzerni aniqlash (chromium yoki chromium-browser)
BROWSER="chromium"
if command -v chromium-browser &> /dev/null; then
  BROWSER="chromium-browser"
elif ! command -v chromium &> /dev/null; then
  echo "⚠️ Chromium brauzeri topilmadi. O'rnatilmoqda..."
  sudo apt install -y chromium || sudo apt install -y chromium-browser
fi

# 4. Chromiumni to'liq Kiosk rejimida ochish
echo "🖥️ EcoProject Kiosk ekranda ochilmoqda..."
$BROWSER \
  --kiosk \
  --noerrdialogs \
  --disable-infobars \
  --disable-session-crashed-bubble \
  --check-for-update-interval=31536000 \
  --autoplay-policy=no-user-gesture-required \
  --ozone-platform-hint=auto \
  http://127.0.0.1:8000

# Agar Chromium yopilsa, orqa fondagi serverni to'xtatish
kill $SERVER_PID 2>/dev/null || true
