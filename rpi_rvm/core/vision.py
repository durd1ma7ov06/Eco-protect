import cv2
import time
import logging
import threading
from typing import Optional, Callable
from config import settings

logger = logging.getLogger("RVM_Vision")

class BottleDetector:
    """
    Raspberry Pi 4 va USB Kamera uchun professional Snapshot-based Computer Vision detektori.
    Har 1 sekundda 1 ta sifatli snapshot (kadr) olib, yuqori aniqlik (640px) bilan tahlil qiladi.
    """
    def __init__(
        self,
        on_item_detected: Optional[Callable[[str, float], None]] = None,
        on_item_rejected: Optional[Callable[[str, float], None]] = None
    ):
        self.on_item_detected = on_item_detected
        self.on_item_rejected = on_item_rejected
        self.is_running = False
        self.camera: Optional[cv2.VideoCapture] = None
        self.model = None
        self.capture_thread: Optional[threading.Thread] = None
        self.inference_thread: Optional[threading.Thread] = None
        
        self.latest_frame = None
        self.latest_frame_jpeg: Optional[bytes] = None
        self.last_detection_time: float = 0.0
        self.last_reject_time: float = 0.0
        self.is_processing_item: bool = False
        
        self.frame_lock = threading.Lock()
        self.state_lock = threading.Lock()

        self._init_model()

    def _init_model(self):
        """YOLOv8 modelini yuklash"""
        try:
            from ultralytics import YOLO
            logger.info(f"🧠 YOLO modeli yuklanmoqda: {settings.MODEL_PATH}...")
            self.model = YOLO(settings.MODEL_PATH)
            logger.info("✅ YOLOv8 modeli xotiraga yuklandi (Snapshot rejimi).")
        except ImportError:
            logger.warning("⚠️ 'ultralytics' topilmadi. Simulyatsiya rejimi ishlaydi.")
            self.model = None
        except Exception as e:
            logger.error(f"❌ Model yuklashda xatolik: {e}")
            self.model = None

    def start_camera(self) -> bool:
        """USB kamerani ochish"""
        try:
            self.camera = cv2.VideoCapture(settings.CAMERA_INDEX)
            self.camera.set(cv2.CAP_PROP_FRAME_WIDTH, settings.FRAME_WIDTH)
            self.camera.set(cv2.CAP_PROP_FRAME_HEIGHT, settings.FRAME_HEIGHT)
            self.camera.set(cv2.CAP_PROP_FPS, 30)

            if not self.camera.isOpened():
                logger.error(f"❌ USB kamera ({settings.CAMERA_INDEX}) ochilmadi!")
                return False

            logger.info(f"📹 USB kamera ochildi ({settings.FRAME_WIDTH}x{settings.FRAME_HEIGHT}).")
            return True
        except Exception as e:
            logger.error(f"Kamera ochish xatoligi: {e}")
            return False

    def start(self):
        """Kamera va 1-sekundlik Snapshot tahlil oqimlarini boshlash"""
        if self.is_running:
            return

        if not self.camera or not self.camera.isOpened():
            self.start_camera()

        self.is_running = True
        
        # 1-oqim: Kameradan kadr olish va veb-preview yaratish
        self.capture_thread = threading.Thread(target=self._capture_loop, daemon=True)
        self.capture_thread.start()

        # 2-oqim: Sekundiga 1 ta rasm olib YOLO tahlilidan o'tkazish
        self.inference_thread = threading.Thread(target=self._snapshot_inference_loop, daemon=True)
        self.inference_thread.start()

        logger.info(f"🚀 Vision ishga tushdi: Snapshot interval = {settings.SNAPSHOT_INTERVAL_SEC}s, Conf = {settings.DETECTION_CONFIDENCE * 100}%")

    def stop(self):
        """Deteksiyani to'xtatish"""
        self.is_running = False
        if self.camera and self.camera.isOpened():
            self.camera.release()
        logger.info("🛑 Vision tizimi to'xtatildi.")

    def set_processing_lock(self, locked: bool):
        """Hardware mexanizmi ishlayotganda yangi tahlilni to'xtatib turish"""
        with self.state_lock:
            self.is_processing_item = locked

    def _capture_loop(self):
        """Jonli kamera kadrlarini uzluksiz o'qish (Web UI / Preview uchun)"""
        while self.is_running:
            if not self.camera or not self.camera.isOpened():
                time.sleep(0.5)
                continue

            success, frame = self.camera.read()
            if not success or frame is None:
                time.sleep(0.04)
                continue

            with self.frame_lock:
                self.latest_frame = frame.copy()
                try:
                    _, jpeg = cv2.imencode('.jpg', frame, [int(cv2.IMWRITE_JPEG_QUALITY), 65])
                    self.latest_frame_jpeg = jpeg.tobytes()
                except Exception:
                    pass

            time.sleep(0.03)

    def _snapshot_inference_loop(self):
        """
        HAR 1 SEKUNDDA 1 TA RASM (SNAPSHOT) TAHLILI
        Yuqori aniqlik, 640px o'lcham va shovqin filtratsiyasi
        """
        while self.is_running:
            # 1 sekund kutish
            time.sleep(settings.SNAPSHOT_INTERVAL_SEC)

            with self.state_lock:
                if self.is_processing_item:
                    continue

            # Kadr mavjudligini tekshirish
            frame_to_process = None
            with self.frame_lock:
                if self.latest_frame is not None:
                    frame_to_process = self.latest_frame.copy()

            if frame_to_process is None or self.model is None:
                continue

            current_time = time.time()
            if current_time - self.last_detection_time < settings.DETECTION_COOLDOWN_SEC:
                continue

            # --- YUQORI ANIQLIKDA YOLO TAHLILI ---
            try:
                h, w, _ = frame_to_process.shape
                total_frame_area = w * h

                # Yuqori aniqlik uchun imgsz=640
                results = self.model.predict(
                    source=frame_to_process,
                    conf=settings.DETECTION_CONFIDENCE,
                    imgsz=settings.INFERENCE_IMAGE_SIZE,
                    verbose=False
                )

                best_label = None
                best_conf = 0.0
                rejected_label = None
                rejected_conf = 0.0

                for result in results:
                    boxes = result.boxes
                    for box in boxes:
                        cls_id = int(box.cls[0].item())
                        class_name = result.names.get(cls_id, "").lower()
                        conf = float(box.conf[0].item())

                        # Obyekt o'lchamini hisoblash (Maydon filtri)
                        xyxy = box.xyxy[0].cpu().numpy()
                        bw = xyxy[2] - xyxy[0]
                        bh = xyxy[3] - xyxy[1]
                        box_area = bw * bh
                        area_ratio = box_area / total_frame_area

                        # Aniqlik tekshiruvi:
                        if area_ratio >= settings.MIN_BOX_AREA_RATIO:
                            if ("bottle" in class_name or "can" in class_name or class_name in settings.TARGET_CLASSES):
                                best_label = "bottle" if "bottle" in class_name else "can"
                                best_conf = conf
                                logger.info(f"🔍 [SNAPSHOT] Yuqori aniqlikda aniqlandi: {best_label} (Ishonchlilik: {conf:.2f}, Maydon: {area_ratio*100:.1f}%)")
                                break
                            else:
                                if rejected_label is None and conf >= 0.40:
                                    rejected_label = class_name
                                    rejected_conf = conf
                    if best_label:
                        break

                if best_label and self.on_item_detected:
                    self.last_detection_time = time.time()
                    try:
                        self.on_item_detected(best_label, best_conf)
                    except Exception as err:
                        logger.error(f"Callback xatosi: {err}")
                elif rejected_label and self.on_item_rejected and (current_time - self.last_reject_time >= 2.5):
                    self.last_reject_time = current_time
                    logger.warning(f"🚫 [SNAPSHOT REJECTED] Noma'lum/Qabul qilinmaydigan buyum: {rejected_label} ({rejected_conf:.2f})")
                    try:
                        self.on_item_rejected(rejected_label, rejected_conf)
                    except Exception as err:
                        logger.error(f"Reject callback xatosi: {err}")

            except Exception as e:
                logger.error(f"Snapshot inference xatoligi: {e}")

    def get_latest_jpeg(self) -> Optional[bytes]:
        with self.frame_lock:
            return self.latest_frame_jpeg
