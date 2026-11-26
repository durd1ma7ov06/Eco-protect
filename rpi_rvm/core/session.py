import uuid
import time
import re
import logging
from enum import Enum
from typing import Optional, Dict, Any, Callable
from config import settings
from core.security import TokenSecurity

logger = logging.getLogger("RVM_Session")

class SessionState(str, Enum):
    IDLE = "IDLE"                         # Avtomat kutish rejimida
    ACCEPTING = "ACCEPTING"               # Baklashkalarni qabul qilmoqda
    COMPLETED = "COMPLETED"               # Yakunlandi (QR / Telefon / Rahmat ekrani)

class SessionMode(str, Enum):
    ECOLOGY = "ECOLOGY"                   # Ekologiyaga (Xayriya)
    CASHBACK = "CASHBACK"                 # O'zimga (Keshbek)

class RVMSessionManager:
    """
    RVM stansiyasining sessiya holatini boshqaruvchi State Machine.
    Endi ham QR Kod, ham Telefon raqam orqali keshbek olishni to'liq qo'llab-quvvatlaydi.
    """
    def __init__(self, on_state_changed: Optional[Callable[[Dict[str, Any]], None]] = None):
        self.on_state_changed = on_state_changed
        self.state: SessionState = SessionState.IDLE
        self.mode: Optional[SessionMode] = None
        self.session_id: Optional[str] = None
        
        # Hisoblagichlar
        self.bottle_count: int = 0
        self.can_count: int = 0
        self.total_amount: int = 0
        
        # QR Natijalari
        self.qr_payload: Optional[Dict[str, Any]] = None
        self.qr_data_string: Optional[str] = None
        self.qr_base64_image: Optional[str] = None

        # Telefon orqali olish natijalari
        self.claimed_phone: Optional[str] = None
        self.is_phone_claimed: bool = False
        
        # Vaqt
        self.start_time: float = 0.0
        self.completed_time: float = 0.0

    def start_session(self, mode: SessionMode) -> Dict[str, Any]:
        """Yangi qabul qilish sessiyasini boshlash"""
        self.session_id = f"SES-{uuid.uuid4().hex[:10].upper()}"
        self.mode = mode
        self.state = SessionState.ACCEPTING
        self.bottle_count = 0
        self.can_count = 0
        self.total_amount = 0
        self.qr_payload = None
        self.qr_data_string = None
        self.qr_base64_image = None
        self.claimed_phone = None
        self.is_phone_claimed = False
        self.start_time = time.time()
        
        logger.info(f"🟢 Yangi sessiya boshlandi: {self.session_id} | Rejim: {self.mode.value}")
        data = self.get_summary()
        self._notify(data)
        return data

    def register_item(self, item_type: str) -> Dict[str, Any]:
        """Baklashka yoki bankani qabul qilish"""
        if self.state != SessionState.ACCEPTING:
            return self.get_summary()

        if item_type == "bottle":
            self.bottle_count += 1
            self.total_amount += settings.PRICE_PER_BOTTLE
        elif item_type == "can":
            self.can_count += 1
            self.total_amount += settings.PRICE_PER_CAN
        else:
            self.bottle_count += 1
            self.total_amount += settings.PRICE_PER_BOTTLE

        logger.info(f"➕ Qabul qilindi: {item_type} | Jami: {self.bottle_count} baklashka, {self.can_count} banka. Summa: {self.total_amount} so'm")
        data = self.get_summary()
        self._notify(data)
        return data

    def finish_session(self) -> Dict[str, Any]:
        """Sessiyani yakunlash va QR generatsiya qilish"""
        if self.state != SessionState.ACCEPTING:
            return self.get_summary()

        self.state = SessionState.COMPLETED
        self.completed_time = time.time()

        if self.mode == SessionMode.CASHBACK and (self.bottle_count > 0 or self.can_count > 0):
            self.qr_payload = TokenSecurity.generate_token_payload(
                session_id=self.session_id,
                bottles=self.bottle_count,
                cans=self.can_count,
                total_amount=self.total_amount
            )
            self.qr_data_string = TokenSecurity.payload_to_qr_string(self.qr_payload)
            self.qr_base64_image = TokenSecurity.generate_qr_base64_image(self.qr_data_string)
        
        logger.info(f"🏁 Sessiya yakunlandi: {self.session_id}")
        data = self.get_summary()
        self._notify(data)
        return data

    def claim_by_phone(self, raw_phone: str) -> Dict[str, Any]:
        """Keshbekni telefon raqam orqali qabul qilish"""
        # Raqamdan faqat raqamlarni ajratib olish (+998...)
        digits = re.sub(r'\D', '', raw_phone)
        if len(digits) == 9:
            phone_formatted = f"+998{digits}"
        elif len(digits) == 12 and digits.startswith("998"):
            phone_formatted = f"+{digits}"
        else:
            phone_formatted = f"+{digits}"

        self.claimed_phone = phone_formatted
        self.is_phone_claimed = True
        logger.info(f"📱 Keshbek telefon raqamga biriktirildi: {self.claimed_phone} (Summa: {self.total_amount} so'm)")
        
        data = self.get_summary()
        self._notify(data)
        return data

    def reset_to_idle(self) -> Dict[str, Any]:
        """Avtomatni boshlang'ich kutish holatiga qaytarish"""
        self.state = SessionState.IDLE
        self.mode = None
        self.session_id = None
        self.bottle_count = 0
        self.can_count = 0
        self.total_amount = 0
        self.qr_payload = None
        self.qr_data_string = None
        self.qr_base64_image = None
        self.claimed_phone = None
        self.is_phone_claimed = False
        logger.info("🔄 Avtomat boshlang'ich IDLE holatiga qaytdi.")
        data = self.get_summary()
        self._notify(data)
        return data

    def get_summary(self) -> Dict[str, Any]:
        return {
            "state": self.state.value,
            "mode": self.mode.value if self.mode else None,
            "session_id": self.session_id,
            "bottles": self.bottle_count,
            "cans": self.can_count,
            "total_items": self.bottle_count + self.can_count,
            "total_amount": self.total_amount,
            "qr_data": self.qr_data_string,
            "qr_image": self.qr_base64_image,
            "qr_exp_seconds": settings.QR_EXPIRATION_SECONDS,
            "claimed_phone": self.claimed_phone,
            "is_phone_claimed": self.is_phone_claimed,
            "machine_id": settings.MACHINE_ID
        }

    def _notify(self, data: Dict[str, Any]):
        if self.on_state_changed:
            try:
                self.on_state_changed(data)
            except Exception as e:
                logger.error(f"State notification xatosi: {e}")
