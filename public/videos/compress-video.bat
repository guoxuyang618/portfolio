@echo off
chcp 65001 >nul
title 视频压缩工具 - 视觉无损

echo ============================================
echo    视频压缩工具 (视觉无损 / 近无损)
echo    适用于 Web 视频背景
echo ============================================
echo.

REM ====== 配置区 ======
REM 修改下面的变量来指定你的源视频文件名
set "INPUT_FILE=%~1"

if "%INPUT_FILE%"=="" (
    echo [错误] 请将视频文件拖拽到此批处理文件上，或使用命令行：
    echo        compress-video.bat 你的视频.mp4
    echo.
    pause
    exit /b 1
)

if not exist "%INPUT_FILE%" (
    echo [错误] 找不到文件: %INPUT_FILE%
    pause
    exit /b 1
)

REM 获取文件名（不含扩展名）
for %%i in ("%INPUT_FILE%") do set "BASENAME=%%~ni"

echo 源文件: %INPUT_FILE%
echo.
echo 请选择压缩方案:
echo.
echo   [1] 视觉无损 MP4 (H.264, CRF 18) - 质量最高，文件较大
echo   [2] 高质量 MP4   (H.264, CRF 23) - 推荐！质量与体积平衡
echo   [3] Web 优化 MP4  (H.264, CRF 26) - Web 背景视频推荐，体积小
echo   [4] 视觉无损 WebM (VP9, CRF 15)  - 最佳Web格式，质量极高
echo   [5] Web 优化 WebM  (VP9, CRF 30)  - WebM 推荐，体积最小
echo   [6] 全部生成 (MP4 CRF23 + WebM CRF30) - 双格式一键生成
echo   [7] Hero 背景视频专用 (1920x1080 + 双格式 + 10秒截取)
echo.
set /p CHOICE="请输入选项 [1-7]: "

echo.
echo ============================================

if "%CHOICE%"=="1" (
    echo [开始] 视觉无损 MP4 压缩...
    ffmpeg -i "%INPUT_FILE%" -c:v libx264 -preset slow -crf 18 -an -movflags +faststart -pix_fmt yuv420p "%BASENAME%-lossless.mp4" -y
    echo [完成] 输出: %BASENAME%-lossless.mp4
)

if "%CHOICE%"=="2" (
    echo [开始] 高质量 MP4 压缩...
    ffmpeg -i "%INPUT_FILE%" -c:v libx264 -preset slow -crf 23 -an -movflags +faststart -pix_fmt yuv420p "%BASENAME%-hq.mp4" -y
    echo [完成] 输出: %BASENAME%-hq.mp4
)

if "%CHOICE%"=="3" (
    echo [开始] Web 优化 MP4 压缩...
    ffmpeg -i "%INPUT_FILE%" -c:v libx264 -preset slow -crf 26 -an -movflags +faststart -pix_fmt yuv420p -vf "scale=1920:-2" "%BASENAME%-web.mp4" -y
    echo [完成] 输出: %BASENAME%-web.mp4
)

if "%CHOICE%"=="4" (
    echo [开始] 视觉无损 WebM 压缩 (耗时较长，请耐心等待)...
    ffmpeg -i "%INPUT_FILE%" -c:v libvpx-vp9 -crf 15 -b:v 0 -an -pix_fmt yuv420p "%BASENAME%-lossless.webm" -y
    echo [完成] 输出: %BASENAME%-lossless.webm
)

if "%CHOICE%"=="5" (
    echo [开始] Web 优化 WebM 压缩...
    ffmpeg -i "%INPUT_FILE%" -c:v libvpx-vp9 -crf 30 -b:v 0 -an -pix_fmt yuv420p -vf "scale=1920:-2" "%BASENAME%-web.webm" -y
    echo [完成] 输出: %BASENAME%-web.webm
)

if "%CHOICE%"=="6" (
    echo [开始] 双格式生成...
    echo.
    echo [1/2] 生成 MP4...
    ffmpeg -i "%INPUT_FILE%" -c:v libx264 -preset slow -crf 23 -an -movflags +faststart -pix_fmt yuv420p "%BASENAME%-hq.mp4" -y
    echo.
    echo [2/2] 生成 WebM...
    ffmpeg -i "%INPUT_FILE%" -c:v libvpx-vp9 -crf 30 -b:v 0 -an -pix_fmt yuv420p "%BASENAME%-web.webm" -y
    echo.
    echo [完成] 输出:
    echo   - %BASENAME%-hq.mp4
    echo   - %BASENAME%-web.webm
)

if "%CHOICE%"=="7" (
    echo [开始] Hero 背景视频专用处理...
    echo.
    echo [1/4] 截取前10秒...
    ffmpeg -i "%INPUT_FILE%" -t 10 -c copy "%BASENAME%-10s-temp.mp4" -y
    echo.
    echo [2/4] 缩放至1920x1080 + MP4压缩...
    ffmpeg -i "%BASENAME%-10s-temp.mp4" -c:v libx264 -preset slow -crf 23 -an -movflags +faststart -pix_fmt yuv420p -vf "scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2" "hero-bg.mp4" -y
    echo.
    echo [3/4] 生成 WebM 格式...
    ffmpeg -i "%BASENAME%-10s-temp.mp4" -c:v libvpx-vp9 -crf 30 -b:v 0 -an -pix_fmt yuv420p -vf "scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2" "hero-bg.webm" -y
    echo.
    echo [4/4] 清理临时文件...
    del "%BASENAME%-10s-temp.mp4" 2>nul
    echo.
    echo [完成] Hero 背景视频已生成:
    echo   - hero-bg.mp4  (H.264, 直接用于网页)
    echo   - hero-bg.webm (VP9, 更小体积)
    echo.
    echo 这两个文件已在当前 videos 目录中，无需移动！
)

echo.
echo ============================================

REM 显示文件大小对比
echo.
echo 文件大小对比:
for %%f in ("%INPUT_FILE%") do echo   源文件:  %%~zf 字节 (%%~nxf^)

if exist "%BASENAME%-lossless.mp4" for %%f in ("%BASENAME%-lossless.mp4") do echo   无损MP4: %%~zf 字节
if exist "%BASENAME%-hq.mp4" for %%f in ("%BASENAME%-hq.mp4") do echo   高质MP4: %%~zf 字节
if exist "%BASENAME%-web.mp4" for %%f in ("%BASENAME%-web.mp4") do echo   WebMP4:  %%~zf 字节
if exist "%BASENAME%-lossless.webm" for %%f in ("%BASENAME%-lossless.webm") do echo   无损WebM: %%~zf 字节
if exist "%BASENAME%-web.webm" for %%f in ("%BASENAME%-web.webm") do echo   WebWebM: %%~zf 字节
if exist "hero-bg.mp4" for %%f in ("hero-bg.mp4") do echo   hero MP4: %%~zf 字节
if exist "hero-bg.webm" for %%f in ("hero-bg.webm") do echo   hero WebM: %%~zf 字节

echo.
echo ============================================
pause
