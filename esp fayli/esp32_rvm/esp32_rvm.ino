/*
 * ==============================================================================
 * EcoProject Smart RVM - Standart ESP32 Controller Firmware (Servolar + WS2812B)
 * ==============================================================================
 * Mikrokontroller: Standart ESP32 (ESP32-WROOM-32 / NodeMCU ESP32 / DevKit V1)
 * Kutubxonalar:
 *   1. ESP32Servo       (Servolarni PWM bilan boshqarish)
 *   2. Adafruit_NeoPixel (WS2812B / NeoPixel manzil lentasini boshqarish)
 * 
 * PINLAR TAQSIMOTI:
 *   - GPIO 18 (D18): 1-Servo (Chap vanna / Left Servo PWM)
 *   - GPIO 19 (D19): 2-Servo (O'ng vanna / Right Servo PWM)
 *   - GPIO 4  (D4) : WS2812B Adresnaya Lenta Signal (DI / Data In)
 *   - GPIO 2  (D2) : ESP32 platasidagi ko'k LED indikator
 *   - GND          : Umumiy yer (RPi, ESP32, Lenta va Servolar GND umumiy)
 *   - 5V           : Tashqi 5V 2A-3A manba (Lenta va servolarning qizil simi)
 * 
 * LENTA EFFEKTLARI:
 *   - "CMD:LED_IDLE"   -> O'chiq turadi (Kutish holatida)
 *   - "CMD:LED_ACCEPT" -> Yashil nafas oluvchi pulsatsiya (Idish kutilyapti)
 *   - "CMD:LED_REJECT" -> Qizil rangda 3 marta tez miltillab ogohlantirish (Begona narsa)
 *   - "CMD:DROP_LEFT"  -> Chap servo 90°, lenta yashil yaltiraydi, 0° ga qaytadi
 *   - "CMD:DROP_RIGHT" -> O'ng servo 90°, lenta yashil yaltiraydi, 0° ga qaytadi
 * ==============================================================================
 */

#include <ESP32Servo.h>
#include <Adafruit_NeoPixel.h>

// ================= PINLAR VA SOZLAMALAR =================
#define SERVO_LEFT_PIN     18   // Chap servo (D18)
#define SERVO_RIGHT_PIN    19   // O'ng servo (D19)
#define LED_STRIP_PIN       4   // WS2812B Adresnaya Lenta (D4)
#define NUM_LEDS           30   // Lentadagi svetodiodlar soni (30 ta LED)
#define STATUS_LED_PIN      2   // Platadagi ko'k LED

#define ANGLE_REST          0   // Boshlang'ich holat (0°)
#define ANGLE_TILT         90   // Vanna ochilish burchagi (90°)
#define HOLD_TIME_MS     1200   // Vanna ochiq turish vaqti (1.2 soniya)
#define RETURN_DELAY_MS   400   // Qaytishdan so'ng to'xtash vaqti

// Servo va Lenta obyektlari
Servo servoLeft;
Servo servoRight;
Adafruit_NeoPixel strip(NUM_LEDS, LED_STRIP_PIN, NEO_GRB + NEO_KHZ800);

// Lenta rejimlari
enum LedState {
  LED_MODE_OFF,         // O'chiq (IDLE)
  LED_MODE_ACCEPTING,   // Yashil pulsatsiya (Idish kutilyapti)
  LED_MODE_REJECT,      // Qizil ogohlantirish (Tanimaydigan narsa)
  LED_MODE_SUCCESS      // Yashil tasdiq yaltirashi (Idish qabul qilindi)
};

LedState currentLedState = LED_MODE_OFF;

// Animatsiya o'zgaruvchilari (Non-blocking)
unsigned long lastAnimUpdate = 0;
int pulseBrightness = 20;
int pulseDirection = 3;

// Qizil ogohlantirish taymerlari
unsigned long rejectStartTime = 0;
bool rejectLedOn = false;
int rejectBlinkCount = 0;

void setup() {
  Serial.begin(115200);

  pinMode(STATUS_LED_PIN, OUTPUT);
  digitalWrite(STATUS_LED_PIN, LOW);

  // Adresnaya lentani ishga tushirish
  strip.begin();
  strip.setBrightness(180); // Maksimal yorqinlik
  strip.clear();
  strip.show();

  // Standart ESP32 apparat PWM taymerlari
  ESP32PWM::allocateTimer(0);
  ESP32PWM::allocateTimer(1);
  ESP32PWM::allocateTimer(2);
  ESP32PWM::allocateTimer(3);

  servoLeft.setPeriodHertz(50);
  servoRight.setPeriodHertz(50);

  // Boshlang'ich 0 gradusga keltirib dam oldirish
  servoLeft.attach(SERVO_LEFT_PIN, 500, 2400);
  servoRight.attach(SERVO_RIGHT_PIN, 500, 2400);
  servoLeft.write(ANGLE_REST);
  servoRight.write(ANGLE_REST);
  delay(500);
  servoLeft.detach();
  servoRight.detach();

  // Boshlang'ich salomlashish animatsiyasi (Yashil aylanib o'chadi)
  for (int i = 0; i < NUM_LEDS; i++) {
    strip.setPixelColor(i, strip.Color(0, 150, 50));
    strip.show();
    delay(20);
  }
  delay(200);
  strip.clear();
  strip.show();

  digitalWrite(STATUS_LED_PIN, HIGH);
  Serial.println("STATUS:READY:ESP32_RVM_NEOPIXEL");
}

// Barcha diodlarni bitta rangga bo'yash
void setAllPixels(uint32_t color) {
  for (int i = 0; i < NUM_LEDS; i++) {
    strip.setPixelColor(i, color);
  }
  strip.show();
}

// Lentaning uzluksiz animatsiya dvigateli (Delay'larsiz ishlaydi)
void updateLedAnimation() {
  unsigned long now = millis();

  // 1. O'CHIQ HOLAT (IDLE)
  if (currentLedState == LED_MODE_OFF) {
    strip.clear();
    strip.show();
    return;
  }

  // 2. YASHIL NAFAS OLUVCHI PULSATSIYA (ACCEPTING)
  if (currentLedState == LED_MODE_ACCEPTING) {
    if (now - lastAnimUpdate >= 25) { // Har 25ms da yorqinlik o'zgaradi
      lastAnimUpdate = now;
      pulseBrightness += pulseDirection;
      if (pulseBrightness >= 220) {
        pulseBrightness = 220;
        pulseDirection = -3;
      } else if (pulseBrightness <= 15) {
        pulseBrightness = 15;
        pulseDirection = 3;
      }
      // Yumshoq zumrad yashil rang (R=0, G=pulseBrightness, B=pulseBrightness/5)
      setAllPixels(strip.Color(0, pulseBrightness, pulseBrightness / 6));
    }
    return;
  }

  // 3. QIZIL OGOHLANTIRISH MILTILLASHI (REJECT - 3 marta tez yonib-o'chadi)
  if (currentLedState == LED_MODE_REJECT) {
    if (now - lastAnimUpdate >= 120) { // Har 120ms da holat almashadi
      lastAnimUpdate = now;
      rejectLedOn = !rejectLedOn;
      if (rejectLedOn) {
        setAllPixels(strip.Color(255, 0, 0)); // Qizil yondi
      } else {
        strip.clear(); // O'chdi
        strip.show();
      }
      rejectBlinkCount++;

      // 6 ta fazadan so'ng (3 marta qizil yongach) yana yashil qabul rejimiga qaytadi
      if (rejectBlinkCount >= 6) {
        currentLedState = LED_MODE_ACCEPTING;
        pulseBrightness = 60;
        pulseDirection = 4;
      }
    }
    return;
  }

  // 4. MUVAFFAQIYATLI QABUL (SUCCESS)
  if (currentLedState == LED_MODE_SUCCESS) {
    setAllPixels(strip.Color(0, 255, 120)); // Yorqin och yashil
  }
}

void loop() {
  // Lenta animatsiyasini doimiy yangilab turish
  updateLedAnimation();

  // Serial buyruqlarni qabul qilish
  if (Serial.available() > 0) {
    String command = Serial.readStringUntil('\n');
    command.trim();

    // --- REJIM BUYRUQLARI ---
    if (command == "CMD:LED_ACCEPT") {
      currentLedState = LED_MODE_ACCEPTING;
      pulseBrightness = 30;
      pulseDirection = 4;
      Serial.println("ACK:LED_ACCEPT:OK");
    }
    else if (command == "CMD:LED_IDLE") {
      currentLedState = LED_MODE_OFF;
      strip.clear();
      strip.show();
      Serial.println("ACK:LED_IDLE:OK");
    }
    else if (command == "CMD:LED_REJECT") {
      currentLedState = LED_MODE_REJECT;
      rejectBlinkCount = 0;
      rejectLedOn = false;
      lastAnimUpdate = millis();
      Serial.println("ACK:LED_REJECT:OK");
    }

    // --- 1. CHAPGA TASHASH (BOTTLE) ---
    else if (command == "CMD:DROP_LEFT") {
      digitalWrite(STATUS_LED_PIN, LOW);
      currentLedState = LED_MODE_SUCCESS;
      setAllPixels(strip.Color(0, 255, 120)); // Yashil yaltiraydi
      Serial.println("ACK:DROP_LEFT:START");

      // Chap servo 90 gradus ochiladi
      servoLeft.attach(SERVO_LEFT_PIN, 500, 2400);
      servoLeft.write(ANGLE_TILT);
      delay(HOLD_TIME_MS);

      // 0 gradusga qaytib dam oladi
      servoLeft.write(ANGLE_REST);
      delay(RETURN_DELAY_MS);
      servoLeft.detach();

      // Qayta yashil kutish rejimiga o'tadi
      currentLedState = LED_MODE_ACCEPTING;
      digitalWrite(STATUS_LED_PIN, HIGH);
      Serial.println("ACK:DROP_LEFT:DONE");
    }

    // --- 2. O'NGGA TASHASH (CAN) ---
    else if (command == "CMD:DROP_RIGHT") {
      digitalWrite(STATUS_LED_PIN, LOW);
      currentLedState = LED_MODE_SUCCESS;
      setAllPixels(strip.Color(0, 255, 120)); // Yashil yaltiraydi
      Serial.println("ACK:DROP_RIGHT:START");

      // O'ng servo 90 gradus ochiladi
      servoRight.attach(SERVO_RIGHT_PIN, 500, 2400);
      servoRight.write(ANGLE_TILT);
      delay(HOLD_TIME_MS);

      // 0 gradusga qaytib dam oladi
      servoRight.write(ANGLE_REST);
      delay(RETURN_DELAY_MS);
      servoRight.detach();

      // Qayta yashil kutish rejimiga o'tadi
      currentLedState = LED_MODE_ACCEPTING;
      digitalWrite(STATUS_LED_PIN, HIGH);
      Serial.println("ACK:DROP_RIGHT:DONE");
    }

    // --- 3. ALOQANI TEKSHIRISH (PING) ---
    else if (command == "CMD:PING") {
      Serial.println("PONG:ESP32_RVM");
    }

    // --- 4. RESET ---
    else if (command == "CMD:RESET") {
      currentLedState = LED_MODE_OFF;
      strip.clear();
      strip.show();
      servoLeft.attach(SERVO_LEFT_PIN, 500, 2400);
      servoRight.attach(SERVO_RIGHT_PIN, 500, 2400);
      servoLeft.write(ANGLE_REST);
      servoRight.write(ANGLE_REST);
      delay(300);
      servoLeft.detach();
      servoRight.detach();
      digitalWrite(STATUS_LED_PIN, HIGH);
      Serial.println("ACK:RESET:DONE");
    }
  }
}
