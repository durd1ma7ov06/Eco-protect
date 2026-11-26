# 🌱 EcoProject - Smart Reverse Vending Machine (RVM)

**EcoProject** — bu zamonaviy avtomatlashtirilgan aqlli qayta ishlash stansiyasi (Reverse Vending Machine). Aholi tomonidan topshirilgan plastik baklashkalar va alyuminiy bankalarni kompyuter ko'rish (Computer Vision) orqali avtomatik taniydi, saralaydi, ikkita bunkerga yo'naltiradi va foydalanuvchiga bir zumda telefon raqami yoki QR-kod orqali keshbek taqdim etadi.

---

## 🏗️ Tizim Arxitekturasi

Loyihaning to'liq ekotizimi 3 ta asosiy bo'g'indan iborat:

```
[ Raspberry Pi 5 (Server & Kiosk UI) ]
   ├── USB Kamera (YOLOv8 AI Vision - Sekundiga 2 kadr)
   ├── 10-dyumlik Sensor Kiosk Ekrani (FastAPI, WebSocket, TailwindCSS)
   │
   ├── USB Serial (115200 baud)
   ▼
[ Standart ESP32 Mikrokontroller ]
   ├── GPIO 18 -> 1-Servo (Chap vanna / Bunkeri)
   ├── GPIO 19 -> 2-Servo (O'ng vanna / Bunkeri)
   └── GPIO 4  -> WS2812B 30 talik Adresnaya RGB Lenta (Yashil/Qizil indikatsiya)
   │
[ Flutter Mobil Ilovasi (Android) ]
   ├── UrDU Real Slippy Map (OpenStreetMap)
   ├── QR Scanner (Keshbek yig'ish)
   └── Hamyon va tranzaksiyalar tarixi
```

---

## 🚀 Asosiy Imkoniyatlari

1. **Kompyuter Ko'rish (YOLOv8 Snapshot Vision):**
   - RPi 5 CPU/GPU sini ortiqcha yuklamasdan har 0.5 soniyada 1 ta yuqori sifatli kadr tahlil qiladi.
   - Plastik baklashka va alyuminiy bankalarni aniq taniydi. Begona narsalar (qo'l, quti, qog'oz) qo'yilganda xatolik berib qabul qilmaydi.
2. **WS2812B 30-LED Adresnaya Lenta:**
   - **Kutishda:** O'chiq turadi.
   - **Qabul boshlanganda:** Yashil nafas oluvchi pulsatsiya bilan yonadi.
   - **Begona narsada:** 3 marta qizil miltillab ogohlantiradi.
   - **Idish tushganda:** Yashil yaltirab tasdiqlaydi.
3. **Navbatma-navbat 2 Bunkerni To'ldirish (Dual-Servo):**
   - 1-idish chap tomonga (GPIO 18), 2-idish o'ng tomonga (GPIO 19) tashlanadi.
4. **10-Dyumlik Kiosk Ekrani:**
   - Katta shriftlar, chap tarafda sensor NumPad klaviaturasi, o'ng tarafda keshbek va QR kod.
5. **Kriptografik Xavfsizlik:**
   - HMAC-SHA256 raqamli imzolangan, bir martalik va amal qilish muddati 90 soniya bo'lgan keshbek tokenlari.

---

## 📂 Loyiha Tuzilishi

- `rpi_rvm/` — Raspberry Pi 5 uchun FastAPI serveri, YOLOv8 detektori, apparat drayveri va Kiosk UI.
- `esp fayli/` — Standart ESP32 uchun Arduino C++ mikrodasturlari (`esp32_rvm.ino`) va batafsil ulash sxemalari.
- `eco_mobile_app/` — Flutter mobil ilovasi (Xarita, QR skaner, Keshbek balansi).

---

## 📄 Litsenziya
EcoProject Open Source — Tabiatni birgalikda asraymiz! 🌍
