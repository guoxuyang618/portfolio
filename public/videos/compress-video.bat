@echo off
chcp 65001 >nul
title 视频压缩工具 - 视觉无损

echo ============================================
echo    视频压缩工具 (视觉无损 / 近无损)
echo    适用于 Web 视频背景
echo ============================================
echo.

REM ====== FFmpeg 路径配置 ======
REM 自动查找 ffmpeg，优先用 PATH 中的，找不到则用 winget 安装路径
where ffmpeg >nul 2>nul
if %errorlevel%==0 (
    set "FFMPEG=ffmpeg"
) else (
    REM winget 安装的默认路径
    set "FFMPEG_DIR="
    for /d %%d in ("%LOCALAPPDATA%\Microsoft\WinGet\Packages\Gyan.FFmpeg*") do set "FFMPEG_DIR=%%d"
    if defined FFMPEG_DIR (
        for /d %%d in ("!FFMPEG_DIR!\ffmpeg-*") do set "FFMPEG_BIN=%%d\bin"
    )
    if defined FFMPEG_BIN (
        set "FFMPEG=!FFMPEG_BIN!\ffmpeg.exe"
    ) else (
        echo [错误] 未找到 FFmpeg！请先安装：
        echo        winget install Gyan.FFmpeg
        echo.
        pause
        exit /b 1
    )
)

REM 因为要用延迟变量展开，重新启用
setlocal enabledelayedexpansion

REM ====== 重新查找 FFmpeg（延迟展开模式） ======
set "FFMPEG="
where ffmpeg >nul 2>nul
if !errorlevel!==0 (
    set "FFMPEG=ffmpeg"
    goto :ffmpeg_found
)

REM winget 安装的默认路径
for /d %%d in ("%LOCALAPPDATA%\Microsoft\WinGet\Packages\Gyan.FFmpeg*") do (
    for /d %%e in ("%%d\ffmpeg-*") do (
        if exist "%%e\bin\ffmpeg.exe" (
            set "FFMPEG=%%e\bin\ffmpeg.exe"
            goto :ffmpeg_found
        )
    )
)

if not defined FFMPEG (
    echo [错误] 未找到 FFmpeg！请先安装：
    echo        winget install Gyan.FFmpeg
    echo        安装后重启电脑或重新打开命令行窗口
    echo.
    pause
    exit /b 1
)

:ffmpeg_found
echo [信息] FFmpeg 路径: !FFMPEG!
echo.

REM ====== 获取输入文件 ======
set "INPUT_FILE=%~1"

if "!INPUT_FILE!"=="" (
    echo [错误] 请将视频文件拖拽到此批处理文件上，或使用命令行：
    echo        compress-video.bat 你的视频.mp4
    echo.
    pause
    exit /b 1
)

if not exist "!INPUT_FILE!" (
    echo [错误] 找不到文件: !INPUT_FILE!
    echo.
    pause
    exit /b 1
)

REM 获取文件名（不含扩展名）和所在目录
for %%i in ("!INPUT_FILE!") do (
    set "BASENAME=%%~ni"
    set "FILEDIR=%%~dpi"
)

REM 切换到输入文件所在目录（输出文件也保存在那里）
cd /d "!FILEDIR!"

echo 源文件: !INPUT_FILE!
echo 输出目录: !FILEDIR!
echo.
echo 请选择压缩方案:
echo.
echo   [1] 视觉无损 MP4  (H.264, CRF 18) - 质量最高，文件较大
echo   [2] 高质量 MP4    (H.264, CRF 23) - 推荐！质量与体积平衡
echo   [3] Web优化 MP4   (H.264, CRF 26, 1080p) - Web背景推荐，体积小
echo   [4] 视觉无损 WebM (VP9, CRF 15)  - 最佳Web格式，质量极高
echo   [5] Web优化 WebM  (VP9, CRF 30, 1080p) - WebM推荐，体积最小
echo   [6] 双格式生成    (MP4 CRF23 + WebM CRF30) - 一键双格式
echo   [7] Hero专用      (1080p + 双格式 + 15秒截取) - 网页背景视频
echo.
set /p CHOICE="请输入选项 [1-7]: "

echo.
echo ============================================
echo [处理中] 请耐心等待，视频越大耗时越长...
echo ============================================
echo.

if "!CHOICE!"=="1" (
    echo [开始] 视觉无损 MP4 压缩...
    "!FFMPEG!" -i "!INPUT_FILE!" -c:v libx264 -profile:v high -preset slow -crf 18 -an -movflags +faststart -pix_fmt yuv420p "!BASENAME!-lossless.mp4" -y
    if !errorlevel!==0 (
        echo.
        echo [完成] 输出: !FILEDIR!!BASENAME!-lossless.mp4
    ) else (
        echo [失败] 压缩过程出错，请检查视频文件是否损坏
    )
)

if "!CHOICE!"=="2" (
    echo [开始] 高质量 MP4 压缩...
    "!FFMPEG!" -i "!INPUT_FILE!" -c:v libx264 -profile:v high -preset slow -crf 23 -an -movflags +faststart -pix_fmt yuv420p "!BASENAME!-hq.mp4" -y
    if !errorlevel!==0 (
        echo.
        echo [完成] 输出: !FILEDIR!!BASENAME!-hq.mp4
    ) else (
        echo [失败] 压缩过程出错
    )
)

if "!CHOICE!"=="3" (
    echo [开始] Web 优化 MP4 压缩 (缩放至1080p^)...
    "!FFMPEG!" -i "!INPUT_FILE!" -c:v libx264 -profile:v high -preset slow -crf 26 -an -movflags +faststart -pix_fmt yuv420p -vf scale=1920:-2 "!BASENAME!-web.mp4" -y
    if !errorlevel!==0 (
        echo.
        echo [完成] 输出: !FILEDIR!!BASENAME!-web.mp4
    ) else (
        echo [失败] 压缩过程出错
    )
)

if "!CHOICE!"=="4" (
    echo [开始] 视觉无损 WebM 压缩 (VP9编码较慢，请耐心等待^)...
    "!FFMPEG!" -i "!INPUT_FILE!" -c:v libvpx-vp9 -crf 15 -b:v 0 -an -pix_fmt yuv420p "!BASENAME!-lossless.webm" -y
    if !errorlevel!==0 (
        echo.
        echo [完成] 输出: !FILEDIR!!BASENAME!-lossless.webm
    ) else (
        echo [失败] 压缩过程出错
    )
)

if "!CHOICE!"=="5" (
    echo [开始] Web 优化 WebM 压缩...
    "!FFMPEG!" -i "!INPUT_FILE!" -c:v libvpx-vp9 -crf 30 -b:v 0 -an -pix_fmt yuv420p -vf scale=1920:-2 "!BASENAME!-web.webm" -y
    if !errorlevel!==0 (
        echo.
        echo [完成] 输出: !FILEDIR!!BASENAME!-web.webm
    ) else (
        echo [失败] 压缩过程出错
    )
)

if "!CHOICE!"=="6" (
    echo [开始] 双格式生成...
    echo.
    echo [1/2] 生成 MP4 (H.264 High, CRF 23^)...
    "!FFMPEG!" -i "!INPUT_FILE!" -c:v libx264 -profile:v high -preset slow -crf 23 -an -movflags +faststart -pix_fmt yuv420p "!BASENAME!-hq.mp4" -y
    echo.
    echo [2/2] 生成 WebM (VP9, CRF 30^)...
    "!FFMPEG!" -i "!INPUT_FILE!" -c:v libvpx-vp9 -crf 30 -b:v 0 -an -pix_fmt yuv420p "!BASENAME!-web.webm" -y
    echo.
    echo [完成] 输出:
    echo   - !FILEDIR!!BASENAME!-hq.mp4
    echo   - !FILEDIR!!BASENAME!-web.webm
)

if "!CHOICE!"=="7" (
    echo [开始] Hero 背景视频专用处理...
    echo.
    echo [1/4] 截取前15秒...
    "!FFMPEG!" -i "!INPUT_FILE!" -t 15 -c copy "!BASENAME!-15s-temp.mp4" -y
    echo.
    echo [2/4] 缩放至1920x1080 + MP4压缩...
    "!FFMPEG!" -i "!BASENAME!-15s-temp.mp4" -c:v libx264 -profile:v high -preset slow -crf 23 -an -movflags +faststart -pix_fmt yuv420p -vf scale=1920:1080 "hero-bg-compressed.mp4" -y
    echo.
    echo [3/4] 生成 WebM 格式...
    "!FFMPEG!" -i "!BASENAME!-15s-temp.mp4" -c:v libvpx-vp9 -crf 30 -b:v 0 -an -pix_fmt yuv420p -vf scale=1920:1080 "hero-bg-compressed.webm" -y
    echo.
    echo [4/4] 清理临时文件...
    del "!BASENAME!-15s-temp.mp4" 2>nul
    echo.
    echo ============================================
    echo [完成] Hero 背景视频已生成:
    echo   - !FILEDIR!hero-bg-compressed.mp4
    echo   - !FILEDIR!hero-bg-compressed.webm
    echo ============================================
)

echo.
echo ============================================
echo 文件大小对比:
echo ============================================
for %%f in ("!INPUT_FILE!") do echo   原始文件:  %%~zf 字节  (%%~nxf)

if exist "!BASENAME!-lossless.mp4" for %%f in ("!BASENAME!-lossless.mp4") do echo   无损MP4:   %%~zf 字节
if exist "!BASENAME!-hq.mp4" for %%f in ("!BASENAME!-hq.mp4") do echo   高质MP4:   %%~zf 字节
if exist "!BASENAME!-web.mp4" for %%f in ("!BASENAME!-web.mp4") do echo   WebMP4:    %%~zf 字节
if exist "!BASENAME!-lossless.webm" for %%f in ("!BASENAME!-lossless.webm") do echo   无损WebM:  %%~zf 字节
if exist "!BASENAME!-web.webm" for %%f in ("!BASENAME!-web.webm") do echo   WebWebM:   %%~zf 字节
if exist "hero-bg-compressed.mp4" for %%f in ("hero-bg-compressed.mp4") do echo   hero MP4:  %%~zf 字节
if exist "hero-bg-compressed.webm" for %%f in ("hero-bg-compressed.webm") do echo   hero WebM: %%~zf 字节

echo.
echo ============================================
echo 按任意键关闭窗口...
pause >nul
