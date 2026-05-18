@echo off
chcp 65001 >nul
setlocal

REM ===== Portfolio Website Dev Server Launcher =====
REM 1. cd 到正确的项目目录（修复旧路径）
cd /d "c:\Users\matthewguo\CodeBuddy\portfolio-website"
if errorlevel 1 (
  echo [ERROR] 项目目录不存在，请检查路径
  pause
  exit /b 1
)

REM 2. 启动前先杀掉 4321 端口上的旧进程，防止端口越积越多
echo [INFO] 检查 4321 端口占用情况...
for /f "tokens=5" %%a in ('netstat -ano ^| findstr "LISTENING" ^| findstr ":4321"') do (
  echo [INFO] 发现旧进程 PID=%%a，正在清理...
  taskkill /F /PID %%a >nul 2>&1
)

REM 3. 顺手清理所有遗留的 astro dev / npm run dev node 进程
powershell -NoProfile -Command "Get-CimInstance Win32_Process -Filter \"Name='node.exe'\" | Where-Object { $_.CommandLine -like '*astro*dev*' -or $_.CommandLine -like '*npm*run*dev*' } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }" >nul 2>&1

echo [INFO] 端口清理完成，启动 Astro dev server...
echo [INFO] 访问地址: http://localhost:4321/
echo.

REM 4. 启动 dev server
call npm run dev

endlocal
