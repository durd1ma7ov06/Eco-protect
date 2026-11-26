import time
import logging
import asyncio
from typing import Optional
from config import settings

logger = logging.getLogger("RVM_Hardware")

class BaseHardwareController:
    """Hardware boshqaruvining asosi"""
    async def accept_item_cycle(self) -> bool:
        """Baklashkani qabul qilish: ESP32 ga chap yoki o'ng komandasini yuborish"""
        raise NotImplementedError

    def set_led_mode(self, mode: str):
        """WS2812B Adresnaya Lenta rejimini o'rnatish: 'IDLE', 'ACCEPT', 'REJECT'"""
        pass

    def cleanup(self):
        pass


class MockHardwareController(BaseHardwareController):
    """
    Rivojlantirish / Windows muhitida test qilish uchun Mock drayver.
    ESP32 / ESP32-C3 bilan Serial aloqasini to'liq simulyatsiya qiladi.
    """
    def __init__(self):
        self.next_side = "LEFT"
        logger.info(f"🔧 Hardware: MockHardwareController (ESP32 Serial Simulyatsiyasi) ishga tushdi.")
        logger.info(f"⚡ Aloqa: Raspberry Pi 5 -> USB Serial (115200 baud) -> ESP32 -> 2 ta Servo + WS2812B Lenta")

    def set_led_mode(self, mode: str):
        logger.info(f"💡 [MOCK LED LENTA] Rejim: {mode.upper()} -> 'CMD:LED_{mode.upper()}\\n'")

    async def accept_item_cycle(self) -> bool:
        side = self.next_side
        if side == "LEFT":
            logger.info("📤 [RPi 5 -> ESP32] Serial buyruq yuborildi: 'CMD:DROP_LEFT\\n'")
            await asyncio.sleep(0.3)
            logger.info("⚙️ [ESP32 Apparat] 1-Servo (Chap GPIO 18) 90° burildi -> Vanna chap bunkerga tashladi -> 0° ga qaytdi.")
            await asyncio.sleep(0.8)
            logger.info("📥 [ESP32 -> RPi 5] Serial javob qabul qilindi: 'ACK:DROP_LEFT:DONE\\n'")
            self.next_side = "RIGHT"
        else:
            logger.info("📤 [RPi 5 -> ESP32] Serial buyruq yuborildi: 'CMD:DROP_RIGHT\\n'")
            await asyncio.sleep(0.3)
            logger.info("⚙️ [ESP32 Apparat] 2-Servo (O'ng GPIO 19) 90° burildi -> Vanna o'ng bunkerga tashladi -> 0° ga qaytdi.")
            await asyncio.sleep(0.8)
            logger.info("📥 [ESP32 -> RPi 5] Serial javob qabul qilindi: 'ACK:DROP_RIGHT:DONE\\n'")
            self.next_side = "LEFT"

        return True

    def cleanup(self):
        logger.info("🧹 [MOCK] Serial aloqa to'xtatildi.")


class ESP32SerialController(BaseHardwareController):
    """
    Raspberry Pi 5 -> ESP32 / ESP32-C3 Haqiqiy USB Serial Drayveri.
    Raspberry Pi 5 USB kabel orqali ESP32 ga ulanadi (115200 baud).
    """
    def __init__(self):
        self.next_side = "LEFT"
        self.serial_conn = None
        self._init_serial()

    def _init_serial(self):
        try:
            import serial
            import serial.tools.list_ports

            port_to_use = settings.SERIAL_PORT
            if port_to_use == "AUTO":
                # Avtomatik ESP32 portini aniqlash (CP2102, CH340, FTDI, USB CDC)
                ports = list(serial.tools.list_ports.comports())
                for p in ports:
                    desc = (p.description or "").lower()
                    hwid = (p.hwid or "").lower()
                    if "esp" in desc or "jtag" in desc or "ch340" in desc or "cp210" in desc or "usb" in desc or "uart" in desc:
                        port_to_use = p.device
                        break
                if port_to_use == "AUTO" and ports:
                    port_to_use = ports[0].device

            if port_to_use and port_to_use != "AUTO":
                self.serial_conn = serial.Serial(
                    port=port_to_use,
                    baudrate=settings.SERIAL_BAUDRATE,
                    timeout=2.0
                )
                time.sleep(2.0) # ESP32 reset bo'lib ulanishi uchun kutish
                logger.info(f"✅ ESP32 Serial ulandi: Port={port_to_use}, Baud={settings.SERIAL_BAUDRATE}")
            else:
                logger.warning("⚠️ Hech qanday Serial port topilmadi, Mock rejimiga o'tiladi.")
        except Exception as e:
            logger.error(f"❌ ESP32 Serial ulanishda xatolik: {e}")
            self.serial_conn = None

    def set_led_mode(self, mode: str):
        """WS2812B Adresnaya Lenta rejimini o'zgartirish ('IDLE', 'ACCEPT', 'REJECT')"""
        cmd = f"CMD:LED_{mode.upper()}\n"
        if self.serial_conn and self.serial_conn.is_open:
            try:
                self.serial_conn.write(cmd.encode('utf-8'))
                self.serial_conn.flush()
                logger.info(f"💡 [RPi 5 -> ESP32 Lenta]: {cmd.strip()}")
            except Exception as e:
                logger.error(f"Lenta buyrug'i xatosi: {e}")
        else:
            logger.info(f"💡 [MOCK LENTA] Offline rejim: {cmd.strip()}")

    async def accept_item_cycle(self) -> bool:
        side = self.next_side
        cmd = f"CMD:DROP_{side}\n"

        if not self.serial_conn or not self.serial_conn.is_open:
            logger.warning(f"[SERIAL OFFLINE] Mock simulyatsiya: {cmd.strip()}")
            self.next_side = "RIGHT" if side == "LEFT" else "LEFT"
            await asyncio.sleep(1.0)
            return True

        try:
            # 1. ESP32 ga buyruq yuborish
            self.serial_conn.write(cmd.encode('utf-8'))
            self.serial_conn.flush()
            logger.info(f"📤 [RPi 5 -> ESP32]: {cmd.strip()}")

            # 2. ESP32 dan tasdiq javobini kutish
            loop = asyncio.get_running_loop()
            response = await loop.run_in_executor(None, self.serial_conn.readline)
            resp_str = response.decode('utf-8', errors='ignore').strip()
            logger.info(f"📥 [ESP32 -> RPi 5]: {resp_str}")

            # Keyingi tashlash uchun tomonni almashtirish
            self.next_side = "RIGHT" if side == "LEFT" else "LEFT"
            return True
        except Exception as e:
            logger.error(f"Serial aloqada xatolik: {e}")
            return False

    def cleanup(self):
        try:
            if self.serial_conn and self.serial_conn.is_open:
                self.serial_conn.close()
            logger.info("ESP32 Serial port yopildi.")
        except Exception as e:
            logger.error(f"Serial cleanup xatoligi: {e}")


# Orqaga moslik uchun alias
ESP32C3SerialController = ESP32SerialController


def get_hardware_controller() -> BaseHardwareController:
    if settings.ENABLE_REAL_SERIAL:
        try:
            ctrl = ESP32SerialController()
            if ctrl.serial_conn:
                return ctrl
        except Exception as e:
            logger.warning(f"ESP32 ulanmadi ({e}), Mock rejimiga o'tildi.")
    return MockHardwareController()
