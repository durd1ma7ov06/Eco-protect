# 🔌 EcoProject: Standart ESP32 Pinlar, WS2812B Adresnaya Lenta va Servolar Qo'llanmasi

Ushbu qo'llanma **EcoProject Smart RVM** tizimida standart **ESP32 (ESP32-WROOM-32 / NodeMCU ESP32 / DevKit V1)** mikrokontrolleriga 2 ta servo va **WS2812B Adresnaya RGB Lenta**ni to'g'ri ulash uchun tayyorlandi.

---

## 📌 1. ESP32 Pinlar Taqsimoti (Pinout)

| Qism | ESP32 Pini | Sim rangi | Vazifasi va Tavsif |
| :--- | :--- | :--- | :--- |
| **1-Servo (Chap Vanna)** | **GPIO 18** (D18) | 🟡 To'q sariq / Sariq | PWM Signal (Chap tomonga 90° ochish) |
| **2-Servo (O'ng Vanna)** | **GPIO 19** (D19) | 🟡 To'q sariq / Sariq | PWM Signal (O'ng tomonga 90° ochish) |
| **WS2812B Adresnaya Lenta** | **GPIO 4** (D4) | 🟢 Yashil / Oq | DI (Data In / Signal simi) |
| **Platadagi Ko'k LED** | **GPIO 2** (D2) | — | Holat indikatori (Tayyor bo'lganda yonadi) |
| **GND (Umumiy Yer)** | **GND** | ⚫ Qora / Jigarrang | RPi 5, ESP32, Lenta va Servolar GND umumiy! |
| **Servolar va Lenta 5V** | **Tashqi 5V Manba** | 🔴 Qizil | 5V (kamida 2A yoki 3A) manbaga ulanishi shart |
| **Raspberry Pi 5 Aloqasi**| **USB Port** | — | USB Type-C yoki Micro-USB kabel orqali RPi 5 ga |

---

## 🌈 2. WS2812B Adresnaya Lenta Rejimlari

1. **⚫ Kutish holatida (IDLE):** Lenta butunlay o'chiq turadi (elektr tejaydi).
2. **🟢 Qabul boshlanganda (ACCEPTING):** Lenta yashil rangda yumshoq nafas olib ("breathing" pulsatsiya) yonib-o'chib turadi. Bu foydalanuvchiga idishni kiritish mumkinligini bildiradi.
3. **🔴 Begona/Noma'lum narsa qo'yilganda (REJECT):** Lenta 3 marta tez qizil miltillaydi va ekranda ogohlantirish chiqadi.
4. **✨ Idish qabul qilinganda (DROP):** Lenta yorqin yashil yaltirab tasdiqlaydi.

---

## 📐 3. Sxematik Ulash Ko'rinishi

```
       [ Raspberry Pi 5 ]
               │
               │ (Standart USB kabel)
               ▼
        [ ESP32 Platasi ]
   ├── GPIO 18 (D18) ────────> [ 1-Servo (Chap) Signal ]
   ├── GPIO 19 (D19) ────────> [ 2-Servo (O'ng) Signal ]
   ├── GPIO 4  (D4)  ────────> [ WS2812B Lenta DI (Data) ]
   ├── GND           ────────┬> [ Servolar va Lenta GND (Qora) ]
   │                         └> [ 5V Quvvat bloki GND ]
   │
[ Tashqi 5V Blok ] ───────────┬> [ Servolar Qizil (+5V) simi ]
                              └> [ WS2812B Lenta Qizil (+5V) simi ]
```

> [!IMPORTANT]
> **Quvvat bo'yicha muhim eslatma:**
> Servolar va WS2812B lenta birgalikda 1.5A–2.5A gacha tok talab qilishi mumkin.
> Shuning uchun ularning **Qizil (+5V)** simini alohida **5V 2A yoki 3A quvvat blokiga**, **Qora (GND)** simini esa **ESP32 ning GND pini bilan birlashtirib (umumiy GND)** ulang!

---

## 💻 4. Arduino IDE da Dasturni ESP32 ga Yuklash

1. **Arduino IDE** dasturini oching.
2. Menyudan: **Tools (Инструменты) -> Board (Плата) -> esp32 -> ESP32 Dev Module** ni tanlang.
3. **Tools -> Port** bo'limidan ESP32 ulangan COM portni tanlang.
4. Ikkita kerakli kutubxonani o'rnating (**Sketch -> Include Library -> Manage Libraries...**):
   - **`ESP32Servo`** (Muallif: *Kevin Harrington / John K. Bennett*)
   - **`Adafruit_NeoPixel`** (Muallif: *Adafruit*)
5. `esp fayli/esp32_rvm/esp32_rvm.ino` faylini oching va **Upload (Yuklash ➡️)** tugmasini bosing.
