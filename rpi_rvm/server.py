import asyncio
import json
import logging
from typing import List
from contextlib import asynccontextmanager

from fastapi import FastAPI, WebSocket, WebSocketDisconnect, HTTPException
from fastapi.responses import HTMLResponse, StreamingResponse
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

from config import settings
from core.hardware import get_hardware_controller
from core.vision import BottleDetector
from core.session import RVMSessionManager, SessionMode, SessionState

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(name)s: %(message)s")
logger = logging.getLogger("RVM_Server")

hardware = get_hardware_controller()

class ConnectionManager:
    """Kiosk UI bilan real-vaqtda bog'lanish uchun WebSocket boshqaruvchisi"""
    def __init__(self):
        self.active_connections: List[WebSocket] = []

    async def connect(self, websocket: WebSocket):
        await websocket.accept()
        self.active_connections.append(websocket)
        logger.info(f"🖥️ Kiosk UI ulandi (Jami: {len(self.active_connections)})")

    def disconnect(self, websocket: WebSocket):
        if websocket in self.active_connections:
            self.active_connections.remove(websocket)
            logger.info("🖥️ Kiosk UI uzildi.")

    async def broadcast(self, message: dict):
        if not self.active_connections:
            return
        payload_str = json.dumps(message)
        for connection in list(self.active_connections):
            try:
                await connection.send_text(payload_str)
            except Exception:
                self.disconnect(connection)

ws_manager = ConnectionManager()
event_loop: asyncio.AbstractEventLoop = None

def broadcast_state(data: dict):
    global event_loop
    if event_loop and event_loop.is_running():
        asyncio.run_coroutine_threadsafe(
            ws_manager.broadcast({"event": "STATE_UPDATE", "data": data}),
            event_loop
        )

session_manager = RVMSessionManager(on_state_changed=broadcast_state)

def handle_detection(label: str, confidence: float):
    """Snapshot tahlilida baklashka aniqlanganda chaqiriladi"""
    global event_loop
    if session_manager.state != SessionState.ACCEPTING:
        return

    logger.info(f"🤖 [SNAPSHOT DETECTED] Qabul qilinmoqda: {label} (Ishonchlilik: {confidence:.2f})")
    detector.set_processing_lock(True)

    async def process_intake():
        try:
            await ws_manager.broadcast({"event": "ITEM_DETECTED", "label": label})
            success = await hardware.accept_item_cycle()
            if success:
                session_manager.register_item(label)
                await ws_manager.broadcast({"event": "ITEM_ACCEPTED", "label": label})
        except Exception as e:
            logger.error(f"Intake jarayonida xatolik: {e}")
        finally:
            await asyncio.sleep(0.5)
            detector.set_processing_lock(False)

    if event_loop and event_loop.is_running():
        asyncio.run_coroutine_threadsafe(process_intake(), event_loop)

def handle_rejection(label: str, confidence: float):
    """Kamera qabul tuynugida begona yoki tanilmagan narsa ko'rganda chaqiriladi"""
    global event_loop
    if session_manager.state != SessionState.ACCEPTING:
        return

    logger.warning(f"🚫 [SNAPSHOT REJECTED] Qabul qilinmaydigan buyum aniqlandi: {label} (Ishonchlilik: {confidence:.2f})")
    hardware.set_led_mode("REJECT")

    async def notify_reject():
        try:
            await ws_manager.broadcast({"event": "ITEM_REJECTED", "label": label})
        except Exception as e:
            logger.error(f"Reject broadcast xatosi: {e}")

    if event_loop and event_loop.is_running():
        asyncio.run_coroutine_threadsafe(notify_reject(), event_loop)

detector = BottleDetector(on_item_detected=handle_detection, on_item_rejected=handle_rejection)

@asynccontextmanager
async def lifespan(app: FastAPI):
    global event_loop
    event_loop = asyncio.get_running_loop()
    logger.info("🏁 FastAPI RVM Server ishga tushdi.")
    detector.start()
    yield
    logger.info("🛑 RVM Server to'xtatilmoqda...")
    detector.stop()
    hardware.cleanup()

app = FastAPI(title=settings.APP_NAME, lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.mount("/static", StaticFiles(directory="static"), name="static")

# REST Modellari
class ModeSelectRequest(BaseModel):
    mode: str  # "ECOLOGY" yoki "CASHBACK"

class ManualDepositRequest(BaseModel):
    item_type: str = "bottle"

class PhoneClaimRequest(BaseModel):
    phone: str

@app.get("/")
def get_kiosk_page():
    with open("static/index.html", "r", encoding="utf-8") as f:
        return HTMLResponse(f.read())

@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    await ws_manager.connect(websocket)
    await websocket.send_text(json.dumps({
        "event": "STATE_UPDATE",
        "data": session_manager.get_summary()
    }))
    try:
        while True:
            data = await websocket.receive_text()
            msg = json.loads(data)
            action = msg.get("action")
            if action == "START_SESSION":
                mode_str = msg.get("mode", "CASHBACK")
                mode = SessionMode.ECOLOGY if mode_str == "ECOLOGY" else SessionMode.CASHBACK
                session_manager.start_session(mode)
                hardware.set_led_mode("ACCEPT")
            elif action == "FINISH_SESSION":
                session_manager.finish_session()
                hardware.set_led_mode("IDLE")
            elif action == "CLAIM_PHONE":
                phone = msg.get("phone", "")
                session_manager.claim_by_phone(phone)
                await ws_manager.broadcast({"event": "PHONE_CLAIMED", "phone": phone})
            elif action == "RESET":
                session_manager.reset_to_idle()
                hardware.set_led_mode("IDLE")
    except WebSocketDisconnect:
        ws_manager.disconnect(websocket)
    except Exception as e:
        logger.error(f"WebSocket xatolik: {e}")
        ws_manager.disconnect(websocket)

@app.post("/api/session/start")
def start_session(req: ModeSelectRequest):
    mode = SessionMode.ECOLOGY if req.mode.upper() == "ECOLOGY" else SessionMode.CASHBACK
    hardware.set_led_mode("ACCEPT")
    return session_manager.start_session(mode)

@app.post("/api/session/finish")
def finish_session():
    hardware.set_led_mode("IDLE")
    return session_manager.finish_session()

@app.post("/api/session/claim-phone")
async def claim_by_phone_api(req: PhoneClaimRequest):
    if session_manager.state != SessionState.COMPLETED:
        raise HTTPException(status_code=400, detail="Avval sessiyani yakunlang")
    res = session_manager.claim_by_phone(req.phone)
    await ws_manager.broadcast({"event": "PHONE_CLAIMED", "phone": res["claimed_phone"], "amount": res["total_amount"]})
    return res

@app.post("/api/session/reset")
def reset_session():
    hardware.set_led_mode("IDLE")
    return session_manager.reset_to_idle()

@app.get("/api/session/status")
def get_status():
    return session_manager.get_summary()

@app.post("/api/test/simulate-item")
async def simulate_item(req: ManualDepositRequest):
    if session_manager.state != SessionState.ACCEPTING:
        raise HTTPException(status_code=400, detail="Sessiya ACCEPTING holatida emas")
    handle_detection(req.item_type, 0.95)
    return {"status": "ok", "message": f"{req.item_type} simulyatsiya qilindi"}

@app.get("/video_feed")
def video_feed():
    def iter_frames():
        while True:
            frame_bytes = detector.get_latest_jpeg()
            if frame_bytes:
                yield (b'--frame\r\n'
                       b'Content-Type: image/jpeg\r\n\r\n' + frame_bytes + b'\r\n')
            else:
                import time
                time.sleep(0.1)

    return StreamingResponse(
        iter_frames(),
        media_type="multipart/x-mixed-replace; boundary=frame"
    )
