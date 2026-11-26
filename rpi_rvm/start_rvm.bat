@echo off
chcp 65001 > nul
title Eco Drop Smart RVM Station
cd /d "%~dp0"

echo ============================================================
echo   🌿 ECO DROP SMART RVM STANSIYASI ISHGA TUSHMOQDA...
echo ============================================================
echo   Manzil: http://127.0.0.1:8000
echo   To'xtatish uchun: Ushbu oynani yoping yoki Ctrl+C bosing.
echo ============================================================

:: 2 soniyadan so'ng brauzerni avtomatik ochish
start "" http://127.0.0.1:8000

:: FastAPI serverni ishga tushirish
python -m uvicorn server:app --host 127.0.0.1 --port 8000
pause
