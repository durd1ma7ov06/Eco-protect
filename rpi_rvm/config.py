from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_prefix="RVM_", extra="ignore")

    # App
    APP_NAME: str = "EcoProject Smart RVM"
    MACHINE_ID: str = "ECOPROJECT-URDU-001"
    SECRET_KEY: str = "super_secret_rvm_hmac_key_2026_change_in_prod"
    HOST: str = "0.0.0.0"
    PORT: int = 8000
    IS_DEBUG: bool = True

    # Camera & Vision (RPi 5 + USB Kamera)
    CAMERA_INDEX: int = 0
    FRAME_WIDTH: int = 640
    FRAME_HEIGHT: int = 480
    SNAPSHOT_INTERVAL_SEC: float = 0.5
    INFERENCE_IMAGE_SIZE: int = 480
    DETECTION_CONFIDENCE: float = 0.68
    MIN_BOX_AREA_RATIO: float = 0.035
    MODEL_PATH: str = "yolov8n.pt"
    TARGET_CLASSES: list[str] = ["bottle", "can", "cup"]
    DETECTION_COOLDOWN_SEC: float = 2.0

    # Hardware: Raspberry Pi -> ESP32-C3 (USB Serial / UART orqali)
    # RPi 5 to'g'ridan-to'g'ri servoga emas, ESP32-C3 ga komanda beradi
    ENABLE_REAL_SERIAL: bool = False     # Haqiqiy ESP32 ulanganda True, testda False
    SERIAL_PORT: str = "AUTO"            # "AUTO" yoki "/dev/ttyACM0", "/dev/ttyUSB0", "COM3"
    SERIAL_BAUDRATE: int = 115200       # ESP32-C3 uzatish tezligi
    
    # Narxlar va Keshbek (so'mda)
    PRICE_PER_BOTTLE: int = 100
    PRICE_PER_CAN: int = 150
    QR_EXPIRATION_SECONDS: int = 90

settings = Settings()
