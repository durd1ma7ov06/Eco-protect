import hmac
import hashlib
import json
import time
import base64
import io
from typing import Dict, Any, Tuple
from config import settings

class TokenSecurity:
    """
    RVM Keshbek QR kodlari uchun kriptografik xavfsizlik drayveri.
    HMAC-SHA256 orqali imzolangan, vaqtga bog'langan va bir martalik tokenlar.
    """

    @staticmethod
    def generate_token_payload(session_id: str, bottles: int, cans: int, total_amount: int) -> Dict[str, Any]:
        """Xavfsiz imzolangan payload yaratish"""
        now = int(time.time())
        expires_at = now + settings.QR_EXPIRATION_SECONDS

        # Imzo uchun xom matn
        raw_data = f"{session_id}:{settings.MACHINE_ID}:{bottles}:{cans}:{total_amount}:{now}:{expires_at}"
        
        signature = hmac.new(
            settings.SECRET_KEY.encode('utf-8'),
            raw_data.encode('utf-8'),
            hashlib.sha256
        ).hexdigest()

        payload = {
            "v": 1,                                # versiya
            "sid": session_id,                     # sessiya ID
            "mid": settings.MACHINE_ID,            # stansiya ID
            "b": bottles,                          # baklashkalar soni
            "c": cans,                             # bankalar soni
            "amt": total_amount,                   # hisoblangan so'm
            "ts": now,                             # yaratilgan vaqt
            "exp": expires_at,                     # tugash vaqti
            "sig": signature                       # HMAC raqamli imzo
        }
        return payload

    @staticmethod
    def verify_token(payload: Dict[str, Any]) -> Tuple[bool, str]:
        """Tokenning haqiqiyligini va muddatini tekshirish"""
        try:
            now = int(time.time())
            if now > payload.get("exp", 0):
                return False, "QR kod muddati tugagan (Expired)"

            session_id = payload.get("sid")
            mid = payload.get("mid")
            bottles = payload.get("b")
            cans = payload.get("c")
            amt = payload.get("amt")
            ts = payload.get("ts")
            exp = payload.get("exp")
            claimed_sig = payload.get("sig")

            raw_data = f"{session_id}:{mid}:{bottles}:{cans}:{amt}:{ts}:{exp}"
            expected_sig = hmac.new(
                settings.SECRET_KEY.encode('utf-8'),
                raw_data.encode('utf-8'),
                hashlib.sha256
            ).hexdigest()

            if hmac.compare_digest(expected_sig, claimed_sig):
                return True, "Token haqiqiy va tasdiqlandi"
            else:
                return False, "Soxta QR kod (Imzo mos kelmadi)!"
        except Exception as e:
            return False, f"Tekshirishda xatolik: {str(e)}"

    @staticmethod
    def payload_to_qr_string(payload: Dict[str, Any]) -> str:
        """QR kod skaner qilganda o'qiladigan ixcham format"""
        # Ilovaga qulay bo'lishi uchun JSON formatida string
        return json.dumps(payload, separators=(',', ':'))

    @staticmethod
    def generate_qr_base64_image(data_str: str) -> str:
        """QR kod tasvirini brauzerda ko'rsatish uchun Base64 Data URL formatiga aylantirish"""
        try:
            import qrcode
            qr = qrcode.QRCode(
                version=1,
                error_correction=qrcode.constants.ERROR_CORRECT_M,
                box_size=8,
                border=2,
            )
            qr.add_data(data_str)
            qr.make(fit=True)
            img = qr.make_image(fill_color="#10B981", back_color="#1E293B") # Yashil zamonaviy rang
            
            buffered = io.BytesIO()
            img.save(buffered, format="PNG")
            img_b64 = base64.b64encode(buffered.getvalue()).decode("utf-8")
            return f"data:image/png;base64,{img_b64}"
        except ImportError:
            # Agar qrcode kutubxonasi bo'lmasa, frontendda JS qrcode kutubxonasi chizadi
            return ""
