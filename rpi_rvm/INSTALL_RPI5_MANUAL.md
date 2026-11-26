# 🌿 EcoProject: Raspberry Pi 5 + ESP32-C3 (10-Dyuymli Ekran) Boshqaruv Tizimi

Bu arxitektura professional avtomatlar sanoat standarti bo'yicha ishlab chiqilgan:
* **Raspberry Pi 5 (Miya qismi):** 10-dyuymli sensorli ekranda Kiosk interfeysi, USB Kamera va YOLOv8 sun'iy intellektini boshqaradi.
* **ESP32-C3 (Ijrochi mikrokontroller):** Raspberry Pi 5 dan USB Serial orqali buyruq oladi va 2 ta servoni (vanna mexanizmini) mikrosoniyali aniqlikda, siltanmasdan boshqaradi.

```
+-----------------------------------------------------------+
|                   Raspberry Pi 5                          |
|  - 10-Dyuymli Sensorli Ekran (Kiosk UI)                   |
|  - USB Kamera (YOLOv8 Snapshot Detektori)                 |
|  - FastAPI & WebSocket Server                             |
+-----------------------------+-----------------------------+
                              |
                     [USB Serial Kabel]
                     (115200 baud / UART)
                              |
                              v
+-----------------------------+-----------------------------+
|                      ESP32-C3                             |
|  - Firmware: esp32_firmware/esp32c3_rvm.ino               |
|  - 1-Servo (Chap vanna): GPIO 2                           |
|  - 2-Servo (O'ng vanna): GPIO 3                           |
+-----------------------------------------------------------+
```

---

## 🔌 1. Ulanish Sxemasi

### A) Raspberry Pi 5 va ESP32-C3:
* ESP32-C3 platasi oddiy **USB Type-C kabel** orqali Raspberry Pi 5 ning USB portiga ulanadi. (Hech qanday qo'shimcha sim kerak emas, quvvatni ham USB dan oladi).

### B) ESP32-C3 va 2 ta Servo Motor:
| Servo | Qizil sim (VCC) | Qora/Jigarrang sim (GND) | Sariq sim (Signal PWM) |
| :--- | :--- | :--- | :--- |
| **1-Servo (Chap vanna)** | **5V Manba** | **GND (ESP32 GND bilan umumiy)** | **ESP32-C3 GPIO 2** |
| **2-Servo (O'ng vanna)** | **5V Manba** | **GND (ESP32 GND bilan umumiy)** | **ESP32-C3 GPIO 3** |

---

## ⚡ 2. ESP32-C3 ga Dasturni Yuklash
1. Kompyuteringizda **Arduino IDE** dasturini oching.
2. `rpi_rvm/esp32_firmware/esp32c3_rvm.ino` faylini oching.
3. Platalar ro'yxatidan **"ESP32C3 Dev Module"** tanlang.
4. "ESP32Servo" kutubxonasini o'rnating (`Sketch -> Include Library -> Manage Libraries -> ESP32Servo`).
5. **Upload (Yuklash)** tugmasini bosing. Bo'ldi!

---

## 🚀 3. Raspberry Pi 5 da Ishga Tushirish

Fleshka orqali `rpi_rvm_release.zip` faylini RPi 5 ga o'tkazib, terminalda:
```bash
unzip rpi_rvm_release.zip -d ecoproject
cd ecoproject
chmod +x setup_rpi5.sh
./setup_rpi5.sh
```

Dastur 10-dyuymli ekranda to'liq ekranda ochiladi va ESP32-C3 orqali servolarni boshqarishga tayyor bo'ladi!
