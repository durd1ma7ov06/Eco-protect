/*
 * ==============================================================================
 * EcoProject Smart RVM - ESP32-C3 Dual Servo Controller Firmware
 * ==============================================================================
 * Ushbu dastur ESP32-C3 mikrokontrolleriga yuklanadi (Arduino IDE orqali).
 * Raspberry Pi 5 USB kabel orqali unga buyruq yuboradi:
 *   - "CMD:DROP_LEFT"  -> 1-Servo (Chap) 90° buriladi, 1.2s kutadi, 0° ga qaytadi.
 *   - "CMD:DROP_RIGHT" -> 2-Servo (O'ng) 90° buriladi, 1.2s kutadi, 0° ga qaytadi.
 * ==============================================================================
 */

#include <ESP32Servo.h>

// PINLAR TAQSIMOTI (ESP32-C3)
#define SERVO_LEFT_PIN   2   // GPIO 2: 1-Servo (Chap vanna)
#define SERVO_RIGHT_PIN  3   // GPIO 3: 2-Servo (O'ng vanna)
#define STATUS_LED_PIN   8   // GPIO 8: Holat indikator diodi

// BURCHAKLAR
#define ANGLE_REST       0   // Boshlang'ich neytral holat (0 gradus)
#define ANGLE_TILT      90   // Vanna tashlash burchagi (90 gradus)
#define HOLD_TIME_MS  1200   // Vanna ochiq turish vaqti (millisekundda)

Servo servoLeft;
Servo servoRight;

void setup() {
  // Serial aloqani 115200 baud tezlikda boshlash
  Serial.begin(115200);
  pinMode(STATUS_LED_PIN, OUTPUT);
  digitalWrite(STATUS_LED_PIN, LOW);

  // Servolar uchun PWM sozlamalari (50Hz standart SG90 / MG995 / MG996R)
  ESP32PWM::allocateTimer(0);
  ESP32PWM::allocateTimer(1);
  servoLeft.setPeriodHertz(50);
  servoRight.setPeriodHertz(50);

  // Boshlang'ich 0 gradusga keltirish
  servoLeft.attach(SERVO_LEFT_PIN, 500, 2400);
  servoRight.attach(SERVO_RIGHT_PIN, 500, 2400);
  servoLeft.write(ANGLE_REST);
  servoRight.write(ANGLE_REST);
  delay(500);

  // Dam oldirish (PWM signalni bo'shatish - qizib ketmasligi uchun)
  servoLeft.detach();
  servoRight.detach();

  digitalWrite(STATUS_LED_PIN, HIGH);
  Serial.println("STATUS:READY:ESP32C3_RVM");
}

void loop() {
  if (Serial.available() > 0) {
    String command = Serial.readStringUntil('\n');
    command.trim();

    if (command == "CMD:DROP_LEFT") {
      digitalWrite(STATUS_LED_PIN, LOW); // Indikator yonadi
      Serial.println("ACK:DROP_LEFT:START");

      // 1-Servo Chapga 90 gradus buriladi
      servoLeft.attach(SERVO_LEFT_PIN, 500, 2400);
      servoLeft.write(ANGLE_TILT);
      delay(HOLD_TIME_MS);

      // Boshlang'ich holatga qaytadi
      servoLeft.write(ANGLE_REST);
      delay(400);
      servoLeft.detach(); // PWM o'chirish

      digitalWrite(STATUS_LED_PIN, HIGH);
      Serial.println("ACK:DROP_LEFT:DONE");
    }
    else if (command == "CMD:DROP_RIGHT") {
      digitalWrite(STATUS_LED_PIN, LOW);
      Serial.println("ACK:DROP_RIGHT:START");

      // 2-Servo O'ngga 90 gradus buriladi
      servoRight.attach(SERVO_RIGHT_PIN, 500, 2400);
      servoRight.write(ANGLE_TILT);
      delay(HOLD_TIME_MS);

      // Boshlang'ich holatga qaytadi
      servoRight.write(ANGLE_REST);
      delay(400);
      servoRight.detach(); // PWM o'chirish

      digitalWrite(STATUS_LED_PIN, HIGH);
      Serial.println("ACK:DROP_RIGHT:DONE");
    }
    else if (command == "CMD:PING") {
      Serial.println("PONG:ESP32C3");
    }
    else if (command == "CMD:RESET") {
      servoLeft.attach(SERVO_LEFT_PIN, 500, 2400);
      servoRight.attach(SERVO_RIGHT_PIN, 500, 2400);
      servoLeft.write(ANGLE_REST);
      servoRight.write(ANGLE_REST);
      delay(300);
      servoLeft.detach();
      servoRight.detach();
      Serial.println("ACK:RESET:DONE");
    }
  }
}
