/*
 * ==============================================================================
 * EcoProject Smart RVM - Standart ESP32 Controller Firmware (Servolar + WS2812B)
 * ==============================================================================
 * Ushbu fayl bevosita "esp fayli" papkasidan Arduino IDE da ochish uchun.
 * ==============================================================================
 */

#include <ESP32Servo.h>
#include <Adafruit_NeoPixel.h>

// ================= PINLAR VA SOZLAMALAR =================
#define SERVO_LEFT_PIN     18   // Chap servo (D18)
#define SERVO_RIGHT_PIN    19   // O'ng servo (D19)
#define LED_STRIP_PIN       4   // WS2812B Adresnaya Lenta (D4)
#define NUM_LEDS           30   // Lentadagi diodlar soni (30 ta LED)
#define STATUS_LED_PIN      2   // Platadagi ko'k LED

#define ANGLE_REST          0   // Boshlang'ich holat (0°)
#define ANGLE_TILT         90   // Vanna ochilish burchagi (90°)
#define HOLD_TIME_MS     1200   // Vanna ochiq turish vaqti
#define RETURN_DELAY_MS   400   // Qaytish kutish vaqti

Servo servoLeft;
Servo servoRight;
Adafruit_NeoPixel strip(NUM_LEDS, LED_STRIP_PIN, NEO_GRB + NEO_KHZ800);

enum LedState {
  LED_MODE_OFF,
  LED_MODE_ACCEPTING,
  LED_MODE_REJECT,
  LED_MODE_SUCCESS
};

LedState currentLedState = LED_MODE_OFF;

unsigned long lastAnimUpdate = 0;
int pulseBrightness = 20;
int pulseDirection = 3;

unsigned long rejectStartTime = 0;
bool rejectLedOn = false;
int rejectBlinkCount = 0;

void setup() {
  Serial.begin(115200);
  pinMode(STATUS_LED_PIN, OUTPUT);
  digitalWrite(STATUS_LED_PIN, LOW);

  strip.begin();
  strip.setBrightness(180);
  strip.clear();
  strip.show();

  ESP32PWM::allocateTimer(0);
  ESP32PWM::allocateTimer(1);
  ESP32PWM::allocateTimer(2);
  ESP32PWM::allocateTimer(3);

  servoLeft.setPeriodHertz(50);
  servoRight.setPeriodHertz(50);

  servoLeft.attach(SERVO_LEFT_PIN, 500, 2400);
  servoRight.attach(SERVO_RIGHT_PIN, 500, 2400);
  servoLeft.write(ANGLE_REST);
  servoRight.write(ANGLE_REST);
  delay(500);
  servoLeft.detach();
  servoRight.detach();

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

void setAllPixels(uint32_t color) {
  for (int i = 0; i < NUM_LEDS; i++) {
    strip.setPixelColor(i, color);
  }
  strip.show();
}

void updateLedAnimation() {
  unsigned long now = millis();

  if (currentLedState == LED_MODE_OFF) {
    strip.clear();
    strip.show();
    return;
  }

  if (currentLedState == LED_MODE_ACCEPTING) {
    if (now - lastAnimUpdate >= 25) {
      lastAnimUpdate = now;
      pulseBrightness += pulseDirection;
      if (pulseBrightness >= 220) {
        pulseBrightness = 220;
        pulseDirection = -3;
      } else if (pulseBrightness <= 15) {
        pulseBrightness = 15;
        pulseDirection = 3;
      }
      setAllPixels(strip.Color(0, pulseBrightness, pulseBrightness / 6));
    }
    return;
  }

  if (currentLedState == LED_MODE_REJECT) {
    if (now - lastAnimUpdate >= 120) {
      lastAnimUpdate = now;
      rejectLedOn = !rejectLedOn;
      if (rejectLedOn) {
        setAllPixels(strip.Color(255, 0, 0));
      } else {
        strip.clear();
        strip.show();
      }
      rejectBlinkCount++;

      if (rejectBlinkCount >= 6) {
        currentLedState = LED_MODE_ACCEPTING;
        pulseBrightness = 60;
        pulseDirection = 4;
      }
    }
    return;
  }

  if (currentLedState == LED_MODE_SUCCESS) {
    setAllPixels(strip.Color(0, 255, 120));
  }
}

void loop() {
  updateLedAnimation();

  if (Serial.available() > 0) {
    String command = Serial.readStringUntil('\n');
    command.trim();

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
    else if (command == "CMD:DROP_LEFT") {
      digitalWrite(STATUS_LED_PIN, LOW);
      currentLedState = LED_MODE_SUCCESS;
      setAllPixels(strip.Color(0, 255, 120));
      Serial.println("ACK:DROP_LEFT:START");

      servoLeft.attach(SERVO_LEFT_PIN, 500, 2400);
      servoLeft.write(ANGLE_TILT);
      delay(HOLD_TIME_MS);

      servoLeft.write(ANGLE_REST);
      delay(RETURN_DELAY_MS);
      servoLeft.detach();

      currentLedState = LED_MODE_ACCEPTING;
      digitalWrite(STATUS_LED_PIN, HIGH);
      Serial.println("ACK:DROP_LEFT:DONE");
    }
    else if (command == "CMD:DROP_RIGHT") {
      digitalWrite(STATUS_LED_PIN, LOW);
      currentLedState = LED_MODE_SUCCESS;
      setAllPixels(strip.Color(0, 255, 120));
      Serial.println("ACK:DROP_RIGHT:START");

      servoRight.attach(SERVO_RIGHT_PIN, 500, 2400);
      servoRight.write(ANGLE_TILT);
      delay(HOLD_TIME_MS);

      servoRight.write(ANGLE_REST);
      delay(RETURN_DELAY_MS);
      servoRight.detach();

      currentLedState = LED_MODE_ACCEPTING;
      digitalWrite(STATUS_LED_PIN, HIGH);
      Serial.println("ACK:DROP_RIGHT:DONE");
    }
    else if (command == "CMD:PING") {
      Serial.println("PONG:ESP32_RVM");
    }
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
