# Raspberry Pi 4 da o'rnatish va doimiy ishlatish

Bu yo'riqnoma repozitoriydagi f5bdbe1 versiyasi tahliliga asoslangan.
Buyruqlar Raspberry Pi terminalida bajariladi. Windows PowerShell uchun emas.
Raspberry Pi qurilmasiga ulanilmagan: o'rnatish va apparat sinovlari hali bajarilmagan.

## 1. Hozirgi loyiha nimalardan iborat?

- `rpi_rvm`: USB kamera, YOLO modeli, FastAPI server, sensorli ekran interfeysi.
- `esp fayli/esp32_rvm/esp32_rvm.ino`: standart ESP32, ikkita servo va LED lenta mikrodasturi.
- `eco_mobile_app`: Flutter mobil ilovasi; hozirgi hamyon/to'lov qismi demo.

Ulanish: USB kamera -> Pi 4 -> USB serial -> ESP32 -> ikkita servo va LED lenta.
Hozirgi Python kodi servolarni Pi GPIO pinlaridan boshqarmaydi.
Standart ESP32 pinlari: chap servo GPIO18, o'ng servo GPIO19, WS2812B GPIO4.
ESP32-C3 uchun standart ESP32 pin sxemasini ko'chirmang; tegishli firmware va pinlarni tekshiring.
Servo va lentaga alohida, yuklamaga mos 5V manba ishlating; GND umumiy bo'lsin.

## 2. Ishga tushirishdan oldin aniqlangan kamchiliklar

1. `ENABLE_REAL_SERIAL=False`: sukut bo'yicha motorlar emas, simulyatsiya ishlaydi.
2. ESP32 topilmasa, haqiqiy rejim yoqilgan bo'lsa ham Mock rejimiga qaytadi.
3. Serial drayver javobni o'qiydi, lekin `ACK:DROP_LEFT:DONE` yoki
   `ACK:DROP_RIGHT:DONE` ekanini tekshirmasdan muvaffaqiyat deb qaytaradi.
   Firmware START va DONE javoblarini ham yuboradi; eski LED javoblari ham navbatda qolishi mumkin.
4. Kamera boshlanishda ochilmasa, uni qayta ochish mexanizmi yo'q.
   Kamera o'qilmay qolganida oldingi kadr xotirada qoladi va qayta tahlil qilinishi mumkin.
5. Bitta idish kamerada qolsa, cooldown tugagach yana sanalishi mumkin.
   Idish o'tganini tasdiqlovchi sensor yoki yangi idish kelganini tekshirish yo'q.
6. Tayyor `eco_rvm.service` va `.desktop` fayllari `/home/pi/ecoproject` ga bog'langan.
7. `run_kiosk.sh` brauzer yopilganda serverni ham o'chiradi; bu 24/7 uchun mos emas.
8. Sessiyalar, balans va ishlatilgan QR ro'yxati doimiy bazaga yozilmaydi.
   Telefon raqamni kiritish pul o'tkazmasini amalga oshirmaydi.
   Mobil ilovadagi yechib olish funksiyasi ham haqiqiy to'lov provayderini chaqirmaydi.
9. QR imzolash kaliti ochiq kod va mobil ilovaga yozilgan; turli telefonlardan
   takroriy talabni to'sadigan markaziy server yo'q.
10. Frontend Tailwind, ikonka, shrift va ayrim JS kutubxonalarini internetdan oladi.
    Internet bo'lmasa yangi yuklangan ekran to'liq ishlashi kafolatlanmaydi.
11. `/api/test/simulate-item` autentifikatsiyasiz ochiq; `IS_DEBUG=False` uni o'chirmaydi.

Quyidagi sozlama avtomatik yoqilish va server jarayoni to'xtaganda qayta ishga
tushishni ta'minlash uchun. U yuqoridagi dastur va apparat muammolarini tuzatmaydi.
Hozircha nazorat ostida prototip sinovi uchun foydalaning.

## 3. Tizim va paketlar

```bash
getconf LONG_BIT
uname -m
cat /etc/os-release
```

Birinchi natija `64`, arxitektura odatda `aarch64` bo'lishi kerak.
32-bit OS bo'lsa, bu YOLO/PyTorch o'rnatish yo'li uchun 64-bit Raspberry Pi OS
Desktop kerak. Tizimni almashtirishdan oldin SD kartadagi fayllarni saqlang.

```bash
sudo apt update
sudo apt install -y git python3-venv python3-pip libgl1 libglib2.0-0 curl
sudo apt install -y chromium
```

Agar aynan Chromium paketi topilmasa, tizimingizda `chromium-browser` paketini tekshiring.

## 4. Loyihani Pi ga olish

Windowsdagi mahalliy papkani ko'chirish shart emas; Pi terminalida:

```bash
cd "$HOME"
git clone https://github.com/azizbeksultonboyev24-ops/ecoproekt.git eco
cd "$HOME/eco/rpi_rvm"
python3 -m venv venv
venv/bin/python -m pip install --upgrade pip
venv/bin/python -m pip install -r requirements.txt
venv/bin/python -m pip check
venv/bin/python -c "import cv2, torch; from ultralytics import YOLO; print(torch.__version__); print(YOLO('yolov8n.pt').names)"
```

Agar `eco` allaqachon mavjud bo'lsa, yana clone qilmang; mavjud loyiha papkasiga kiring.
`requirements.txt` versiyalarni qat'iy belgilamagan. PyTorch wheel yoki Python
versiyasi xatosi chiqsa, o'rnatishni davom ettirishdan oldin xato va OS versiyasini tekshirish kerak.
Oldingi `setup_rpi.sh` va `setup_rpi5.sh` ni bu yo'riqnoma bilan aralashtirib ishlatmang.

Model repozitoriyda bor. COCO asosidagi oddiy YOLO modelida alohida alyuminiy
`can` klassi yo'q; kod `cup` klassini `can` qilib sanaydi. Bu alyuminiyni
ishonchli aniqlash emas. Plastik/shisha farqini ham bu model tasdiqlamaydi.

Pi 4 da tezlikni qurilmada o'lchang. Boshlang'ich sozlama sifatida keyingi
bo'limda 320px va bir soniyalik interval ishlatiladi; kichik obyektlarda aniqlik pasayishi mumkin.

## 5. Kamera, ESP32 va sozlamalar

Standart ESP32 uchun yuqoridagi `.ino` faylini Arduino IDE orqali yuklang.
Ulash sxemasi: `esp fayli/PINLAR_VA_ULASH_QOLLANMASI.md`.

```bash
ls -l /dev/video*
ls -l /dev/serial/by-id/
sudo usermod -aG dialout,video "$(id -un)"
```

Guruh ruxsatlari yangi login yoki rebootdan keyin kuchga kiradi.
Serial port uchun `/dev/serial/by-id/` ichidagi aynan ESP32 ga tegishli to'liq
yo'lni tanlang. Bu bo'lmasa haqiqiy `/dev/ttyUSB0` yoki `/dev/ttyACM0` portini aniqlang.

Quyidagi faylni yarating:

```bash
cd "$HOME/eco/rpi_rvm"
nano rvm.env
```

Ichiga yozing; SERIAL_PORT qiymatini o'zingizdagi haqiqiy yo'lga almashtiring:

```ini
RVM_ENABLE_REAL_SERIAL=true
RVM_SERIAL_PORT=/dev/serial/by-id/ESP32_QURILMANGIZNING_HAQIQIY_NOMI
RVM_CAMERA_INDEX=0
RVM_INFERENCE_IMAGE_SIZE=320
RVM_SNAPSHOT_INTERVAL_SEC=1.0
RVM_IS_DEBUG=false
```

Bu yerda oddiy `rvm.env` faylini Python o'zi o'qimaydi; keyingi `systemd`
EnvironmentFile sozlamasi uni yuklaydi. IS_DEBUG qiymati test API ni yopmaydi.
Haqiqiy moliyaviy foydalanishdan oldin markaziy QR tasdiqlash va kalit boshqaruvi kerak.
Kalitni faqat Pi da o'zgartirsangiz, hozirgi mobil ilova QR ni tasdiqlamay qo'yadi.

## 6. Serverni systemd bilan avtomatik yoqish

Quyidagi blokni oddiy foydalanuvchi terminalida bajaring (`sudo bash` ichida emas).
Bu buyruq `eco-rvm.service` nomli xizmat faylini yaratadi/almashtiradi.
Oldingi `run_kiosk.sh` ishlayotgan bo'lsa, uni avval o'sha terminalda Ctrl+C bilan to'xtating.

```bash
cd "$HOME/eco/rpi_rvm"
RVM_DIR="$(pwd -P)"
RVM_USER="$(id -un)"
sudo tee /etc/systemd/system/eco-rvm.service >/dev/null <<EOF
[Unit]
Description=Eco RVM server
After=network.target
StartLimitIntervalSec=0

[Service]
Type=simple
User=$RVM_USER
WorkingDirectory=$RVM_DIR
EnvironmentFile=$RVM_DIR/rvm.env
Environment=PYTHONUNBUFFERED=1
ExecStart=$RVM_DIR/venv/bin/python -m uvicorn server:app --host 127.0.0.1 --port 8000 --workers 1
Restart=on-failure
RestartSec=5
TimeoutStopSec=30

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload
sudo systemctl enable --now eco-rvm.service
sudo systemctl status eco-rvm.service --no-pager
curl --fail http://127.0.0.1:8000/api/session/status
```

Bitta worker shart: apparat va sessiya holati bitta jarayonda boshqariladi.
Mahalliy kiosk uchun server faqat Pi ichida ochiladi; tashqi tarmoqdan API ochilmaydi.
Model yuklanishi tugaguncha dastlabki curl ulana olmasligi mumkin; logni ko'ring va takrorlang.
API javobi kamera yoki servo sog'lom ekanining tasdig'i emas.

## 7. Ekranni avtomatik ochish

Server va brauzer alohida ishlaydi. Quyidagi yangi skript faqat brauzerni boshqaradi:

```bash
cd "$HOME/eco/rpi_rvm"
cat > kiosk_only.sh <<'EOF'
#!/bin/bash
set -u
exec 9>"${XDG_RUNTIME_DIR:-/tmp}/eco-rvm-kiosk-$(id -u).lock"
flock -n 9 || exit 0
if command -v chromium >/dev/null 2>&1; then
    browser=chromium
elif command -v chromium-browser >/dev/null 2>&1; then
    browser=chromium-browser
else
    echo 'Chromium topilmadi' >&2
    exit 1
fi
while true; do
    until curl --silent --fail --max-time 3 http://127.0.0.1:8000/api/session/status >/dev/null; do
        sleep 2
    done
    "$browser" --kiosk --no-first-run --noerrdialogs \
        --disable-session-crashed-bubble \
        --user-data-dir="$HOME/.config/eco-rvm-chromium" \
        http://127.0.0.1:8000
    sleep 3
done
EOF
chmod +x kiosk_only.sh
```

`sudo raspi-config` orqali Desktop boot va Desktop Auto Login ni yoqing.
Ekran o'chishini istamasangiz Screen Blanking ni o'chiring. Menyu nomlari OS
versiyasiga qarab farq qiladi. Brauzerni Pi ning grafik sessiyasida ishga tushirish kerak.

Grafik sessiya turini o'sha desktop terminalida tekshiring:

```bash
echo "$XDG_SESSION_TYPE"
echo "$XDG_CURRENT_DESKTOP"
```

Zamonaviy Raspberry Pi OS, **labwc/Wayland** bo'lsa:

```bash
mkdir -p "$HOME/.config/labwc"
nano "$HOME/.config/labwc/autostart"
```

Mavjud qatorlarni saqlab, quyidagi qatorni bir marta qo'shing:

```bash
bash "$HOME/eco/rpi_rvm/kiosk_only.sh" &
```

**X11/LXDE** bo'lsa, uning o'rniga foydalanuvchi autostart faylini yarating:

```bash
mkdir -p "$HOME/.config/autostart"
cat > "$HOME/.config/autostart/eco-rvm-kiosk.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Eco RVM Kiosk
Exec=/bin/bash $HOME/eco/rpi_rvm/kiosk_only.sh
Terminal=false
EOF
```

Wayfire yoki boshqa desktop bo'lsa, sessiyangizga mos autostart usulini aniqlang.
Eski EcoProject/EcoRVM autostart yozuvlari bo'lsa, ularni o'chirib qo'ying;
serverni eski launcher bilan ikkinchi marta ochmang. Yuqoridagi ikkita usuldan
sessiyangizga mos bittasini ishlating.

```bash
sudo reboot
```

## 8. Tekshirish va boshqarish

```bash
# Holat
sudo systemctl status eco-rvm.service --no-pager
# Jonli log (Ctrl+C faqat log ko'rishni tugatadi)
journalctl -u eco-rvm.service -f
# Oxirgi yuklanish loglari
journalctl -u eco-rvm.service -b --no-pager -n 100
# Qayta ishga tushirish (joriy sessiya yo'qoladi)
sudo systemctl restart eco-rvm.service
# To'xtatish
sudo systemctl stop eco-rvm.service
# Avtomatik yoqilishni bekor qilish
sudo systemctl disable --now eco-rvm.service
```

Rebootdan keyin ekran o'zi ochilishini va logda haqiqiy ESP32/kamera ulanganini
tekshiring. Bitta idish faqat bir marta sanalishini alohida sinang.
Bo'sh stendda kamera va ESP32 ni uzib-ulab, xatolarni qanday ko'rsatishini tekshiring.
Hozirgi kodda qayta ulanish kafolatlanmaydi; kerak bo'lsa xizmatni qayta boshlash talab qilinadi.
`systemd` jarayon qulaganda qayta boshlaydi; ichki oqim osilishi yoki kamera
ishlamay qolishi uchun hozircha health-check/watchdog yo'q.

## 9. Haqiqiy 24/7 avtomat uchun qolgan ishlar

- Mock rejimiga yashirin o'tishni haqiqiy rejimda taqiqlash.
- Serial javoblarni buyruq bilan moslashtirish, aynan DONE ni kutish, timeoutda hisoblamaslik.
- Kamerani qayta ulash, eski kadrni bekor qilish, apparat holatini ekranga chiqarish.
- Bir idishni takroriy sanamaslik va tushganini sensor bilan tasdiqlash.
- Sessiya va tranzaksiyalarni bazaga yozish; QR ni markaziy serverda bir marta tasdiqlash.
- Test API ni haqiqiy rejimda o'chirish; real to'lov backendini ulash.
- Frontend kutubxonalarini lokal saqlash.
- Yetarli quvvat, sovutish, elektr uzilishi uchun UPS va xavfsiz o'chirish.
- Qurilmada uzoq muddatli sinov; ishlagan paket versiyalarini mahkamlash.

## Rasmiy manbalar

- Raspberry Pi sozlamalari: https://www.raspberrypi.com/documentation/computers/configuration.html
- labwc kiosk autostart: https://www.raspberrypi.com/tutorials/how-to-use-a-raspberry-pi-in-kiosk-mode/
- systemd qayta boshlash: https://www.freedesktop.org/software/systemd/man/latest/systemd.service.html
- Standart YOLO/COCO klasslari: https://docs.ultralytics.com/datasets/detect/coco/
