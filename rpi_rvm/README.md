# 🌿 Smart RVM (Reverse Vending Machine) - Raspberry Pi 4 Boshqaruv Qismi

Ushbu modul **Raspberry Pi 4** uchun mo'ljallangan yaxlit dasturiy ta'minot bo'lib, quyidagi vazifalarni to'liq avtomatlashtiradi:
1. **USB Kamera & Computer Vision:** YOLOv8 nano modeli orqali plastik baklashka va alyuminiy bankalarni real-vaqtda taniydi.
2. **Servo Motor Boshqaruvi (GPIO):** Idish aniqlanganda eshikni/bunkerni ochadi va idish ichkariga tushgach yopadi.
3. **Kiosk Web Interfeysi:** Sensorli ekranda to'liq ekranli (Chromium Kiosk) zamonaviy interfeysni ko'rsatadi ("Ekologiyaga" va "O'zimga" rejimlari).
4. **Xavfsiz QR Kod Generatsiyasi:** Keshbek olish uchun bir martalik, HMAC-SHA256 bilan imzolangan QR kod generatsiya qiladi.

---

## 🔌 Ulanish Sxemasi (Hardware Pinout)

### 1. Servo Motor (SG90 / MG995 / MG996R)
| Servo Simi | RPi 4 Ulanadigan Joyi | Izoh |
| :--- | :--- | :--- |
| **Qizil (VCC)** | **Pin 2 yoki 4 (5V Power)** | Katta motorlar uchun alohida 5V manba tavsiya etiladi |
| **Jigarrang/Qora (GND)** | **Pin 6 yoki 9 (GND)** | Umumiy yer (Ground) |
| **Sariq/To'q sariq (Signal)** | **Pin 12 (GPIO 18 - PWM)** | PWM orqali burchakni aniq boshqarish |

### 2. USB Kamera
* Raspberry Pi 4 ning ko'k rangli **USB 3.0** portiga ulanadi (`/dev/video0`).

---

## 🚀 Raspberry Pi 4 da Ishga Tushirish

### 1-qadam: Avtomatik o'rnatish
```bash
chmod +x setup_rpi.sh run_kiosk.sh
./setup_rpi.sh
```

### 2-qadam: Kiosk rejimida yoqish
```bash
./run_kiosk.sh
```
Ushbu buyruq:
1. FastAPI serverini orqa fonda 8000-portda ishga tushiradi.
2. Kamera va modelni yuklaydi.
3. Chromium brauzerini avtomatik ravishda to'liq ekranda (ramkalarsiz, kursorlarsiz) ochadi.

---

## 💻 Kompyuterda (Windows/Mac) Sinab Ko'rish (Simulyatsiya)

Dastur shunday loyihalashtirilganki, siz uni hoziroq o'z shaxsiy kompyuteringizda (Raspberry Pisiz) sinab ko'rishingiz mumkin:

1. Kutubxonalarni o'rnating:
   ```bash
   pip install fastapi uvicorn pydantic-settings opencv-python qrcode
   ```
2. Serverni ishga tushiring:
   ```bash
   python -m uvicorn server:app --reload --port 8000
   ```
3. Brauzerda [http://localhost:8000](http://localhost:8000) manzilini oching.
4. Ekranda **"Boshlash"** -> **"O'zimga"** ni tanlang va pastdagi **"+ Baklashka"** tugmasi orqali baklashka tushishini simulyatsiya qiling.
5. **"Tugatish va QR olish"** tugmasini bosib, xavfsiz generatsiya bo'lgan QR kodni ko'rishingiz mumkin!

---

## 🔐 QR Kod Formati (Flutter Ilova uchun)
Mobil ilova skaner qilganda quyidagi JSON formatidagi imzolangan ma'lumotni oladi:
```json
{
  "v": 1,
  "sid": "SES-A9B1C2D3E4",
  "mid": "RVM-TASHKENT-001",
  "b": 3,
  "c": 1,
  "amt": 450,
  "ts": 1774390000,
  "exp": 1774390090,
  "sig": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
}
```
* `amt`: Hisoblangan so'm miqdori
* `sig`: Soxtalashtirishni oldini oluvchi HMAC raqamli imzo
* `exp`: Tugash vaqti (90 soniya)
