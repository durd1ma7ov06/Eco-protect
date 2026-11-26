@echo off
chcp 65001 > nul
title Eco Drop RVM - Serverni to'xtatish
echo 🛑 8000-portdagi RVM server to'xtatilmoqda...
for /f "tokens=5" %%a in ('netstat -aon ^| findstr :8000') do (
    taskkill /F /PID %%a 2>nul
)
echo ✅ Server to'xtatildi!
timeout /t 2 >nul
