@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul
title 视频压缩工具 - 保留音频版

echo ============================================
echo    视频压缩工具（支持保留/去除音频）
echo    适用于 Web 视频 / 通用视频压缩
echo ============================================
echo.

REM ====== FFmpeg 路径配置 ======
set "FFMPEG="

REM 1. 先检查 PATH 中是否有 ffmpeg
where ffmpeg >nul 2>nul
if !errorlevel!==0 (
    set "FFMPEG=ffmpeg"
    goto :ffmpeg_found
)

REM 2. 已知的 winget 安装路径（硬编码，最可靠）
set "KNOWN_PATH=%LOCALAPPDATA%\Microsoft\WinGet\Packages\Gyan.FFmpeg_Microsoft.Winget.Source_8wekyb3d8bbwe\ffmpeg-8.0.1-full_build\bin\ffmpeg.exe"
if exist "!KNOWN_PATH!" (
    set "FFMPEG=!KNOWN_PATH!"
    goto :ffmpeg_found
)

REM 3. 使用 where /R 递归搜索 winget 包目录
for /f "delims=" %%f in ('where /R "%LOCALAPPDATA%\Microsoft\WinGet\Packages" ffmpeg.exe 2^>nul') do (
    set "FFMPEG=%%f"
    goto :ffmpeg_found
)

REM 4. 检查剪映自带的 ffmpeg（备选）
for /f "delims=" %%f in ('where /R "%LOCALAPPDATA%\JianyingPro" ffmpeg.exe 2^>nul') do (
    set "FFMPEG=%%f"
    goto :ffmpeg_found
)

REM 5. 常见安装路径
if exist "C:\ffmpeg\bin\ffmpeg.exe" (
    set "FFMPEG=C:\ffmpeg\bin\ffmpeg.exe"
    goto :ffmpeg_found
)

REM 6. 都找不到，报错退出
echo [错误] 未找到 FFmpeg！请先安装：
echo        winget install Gyan.FFmpeg
echo        安装后重启电脑或重新打开命令行窗口
echo.
pause
exit /b 1

:ffmpeg_found
echo [信息] FFmpeg 路径: !FFMPEG!
echo.

REM ====== 获取输入文件 ======
set "INPUT_FILE=%~1"

if "!INPUT_FILE!"=="" (
    echo [提示] 请将视频文件拖拽到此批处理文件上，或使用命令行：
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

REM ====== 音频选择 ======
echo 是否保留音频（声音）？
echo.
echo   [Y] 保留声音（通用视频推荐）
echo   [N] 去掉声音（网页背景视频推荐）
echo.
set /p AUDIO_CHOICE="请输入 [Y/N]（默认Y）: "
echo.

set "AUDIO_OPTS="
set "AUDIO_LABEL=保留音频"
if /i "!AUDIO_CHOICE!"=="N" (
    set "AUDIO_OPTS=-an"
    set "AUDIO_LABEL=无音频"
) else (
    REM 保留音频：AAC编码，128k码率，质量与体积平衡
    set "AUDIO_OPTS=-c:a aac -b:a 128k"
    set "AUDIO_LABEL=保留音频"
)

echo [音频模式] !AUDIO_LABEL!
echo.

REM ====== 时间段截取（可选） ======
echo ============================================
echo 是否截取指定时间段？
echo ============================================
echo.
echo   时间格式支持: HH:MM:SS / MM:SS / 秒数
echo   示例: 00:00:10 表示第10秒, 01:30 表示1分30秒, 90 表示90秒
echo.
echo   [直接回车] 不截取，保持完整视频
echo.

set "TRIM_SS="
set "TRIM_TO="
set "TRIM_OPTS="
set "TRIM_LABEL=完整视频"

set "TRIM_START="
set /p TRIM_START="请输入开始时间（直接回车跳过）: "

if not "!TRIM_START!"=="" (
    set "TRIM_END="
    set /p TRIM_END="请输入结束时间（直接回车表示到视频末尾）: "

    set "TRIM_SS=-ss !TRIM_START!"
    if not "!TRIM_END!"=="" (
        set "TRIM_TO=-to !TRIM_END!"
        set "TRIM_LABEL=截取 !TRIM_START! → !TRIM_END!"
    ) else (
        set "TRIM_TO="
        set "TRIM_LABEL=从 !TRIM_START! 到末尾"
    )
    set "TRIM_OPTS=!TRIM_SS! !TRIM_TO!"
)

echo.
echo [截取模式] !TRIM_LABEL!
echo.
echo 请选择压缩方案:
echo.
echo   [1] 视觉无损 MP4  (H.264, CRF 18) - 质量最高，文件较大
echo   [2] 高质量 MP4    (H.264, CRF 23) - 推荐！质量与体积平衡
echo   [3] Web优化 MP4   (H.264, CRF 26, 1080p) - 体积小
echo   [4] 视觉无损 WebM (VP9, CRF 15)  - 最佳Web格式，质量极高
echo   [5] Web优化 WebM  (VP9, CRF 30, 1080p) - 体积最小
echo   [6] 双格式生成    (MP4 CRF23 + WebM CRF30) - 一键双格式
echo   [7] Hero专用      (1080p + 双格式 + 15秒截取) - 网页背景视频
echo.
echo   ※ 所有输出均为纯净画面，不添加任何文字/水印
echo.
set /p CHOICE="请输入选项 [1-7]: "

echo.
echo ============================================
echo [处理中] 请耐心等待，视频越大耗时越长...
echo [音频模式] !AUDIO_LABEL!
echo [截取模式] !TRIM_LABEL!
echo ============================================
echo.

if "!CHOICE!"=="1" (
    echo [开始] 视觉无损 MP4 压缩 (!AUDIO_LABEL!, !TRIM_LABEL!^)...
    "!FFMPEG!" !TRIM_SS! -i "!INPUT_FILE!" !TRIM_TO! -c:v libx264 -profile:v high -preset slow -crf 18 !AUDIO_OPTS! -sn -dn -map_metadata -1 -movflags +faststart -pix_fmt yuv420p "!BASENAME!-lossless.mp4" -y
    if !errorlevel!==0 (
        echo.
        echo [完成] 输出: !FILEDIR!!BASENAME!-lossless.mp4
    ) else (
        echo [失败] 压缩过程出错，请检查视频文件是否损坏
    )
)

if "!CHOICE!"=="2" (
    echo [开始] 高质量 MP4 压缩 (!AUDIO_LABEL!, !TRIM_LABEL!^)...
    "!FFMPEG!" !TRIM_SS! -i "!INPUT_FILE!" !TRIM_TO! -c:v libx264 -profile:v high -preset slow -crf 23 !AUDIO_OPTS! -sn -dn -map_metadata -1 -movflags +faststart -pix_fmt yuv420p "!BASENAME!-hq.mp4" -y
    if !errorlevel!==0 (
        echo.
        echo [完成] 输出: !FILEDIR!!BASENAME!-hq.mp4
    ) else (
        echo [失败] 压缩过程出错
    )
)

if "!CHOICE!"=="3" (
    echo [开始] Web 优化 MP4 压缩 (缩放至1080p, !AUDIO_LABEL!, !TRIM_LABEL!^)...
    "!FFMPEG!" !TRIM_SS! -i "!INPUT_FILE!" !TRIM_TO! -c:v libx264 -profile:v high -preset slow -crf 26 !AUDIO_OPTS! -sn -dn -map_metadata -1 -movflags +faststart -pix_fmt yuv420p -vf scale=1920:-2 "!BASENAME!-web.mp4" -y
    if !errorlevel!==0 (
        echo.
        echo [完成] 输出: !FILEDIR!!BASENAME!-web.mp4
    ) else (
        echo [失败] 压缩过程出错
    )
)

if "!CHOICE!"=="4" (
    echo [开始] 视觉无损 WebM 压缩 (VP9编码较慢，请耐心等待, !AUDIO_LABEL!, !TRIM_LABEL!^)...
    if /i "!AUDIO_CHOICE!"=="N" (
        "!FFMPEG!" !TRIM_SS! -i "!INPUT_FILE!" !TRIM_TO! -c:v libvpx-vp9 -crf 15 -b:v 0 -an -sn -dn -map_metadata -1 -pix_fmt yuv420p "!BASENAME!-lossless.webm" -y
    ) else (
        "!FFMPEG!" !TRIM_SS! -i "!INPUT_FILE!" !TRIM_TO! -c:v libvpx-vp9 -crf 15 -b:v 0 -c:a libopus -b:a 128k -sn -dn -map_metadata -1 -pix_fmt yuv420p "!BASENAME!-lossless.webm" -y
    )
    if !errorlevel!==0 (
        echo.
        echo [完成] 输出: !FILEDIR!!BASENAME!-lossless.webm
    ) else (
        echo [失败] 压缩过程出错
    )
)

if "!CHOICE!"=="5" (
    echo [开始] Web 优化 WebM 压缩 (!AUDIO_LABEL!, !TRIM_LABEL!^)...
    if /i "!AUDIO_CHOICE!"=="N" (
        "!FFMPEG!" !TRIM_SS! -i "!INPUT_FILE!" !TRIM_TO! -c:v libvpx-vp9 -crf 30 -b:v 0 -an -sn -dn -map_metadata -1 -pix_fmt yuv420p -vf scale=1920:-2 "!BASENAME!-web.webm" -y
    ) else (
        "!FFMPEG!" !TRIM_SS! -i "!INPUT_FILE!" !TRIM_TO! -c:v libvpx-vp9 -crf 30 -b:v 0 -c:a libopus -b:a 128k -sn -dn -map_metadata -1 -pix_fmt yuv420p -vf scale=1920:-2 "!BASENAME!-web.webm" -y
    )
    if !errorlevel!==0 (
        echo.
        echo [完成] 输出: !FILEDIR!!BASENAME!-web.webm
    ) else (
        echo [失败] 压缩过程出错
    )
)

if "!CHOICE!"=="6" (
    echo [开始] 双格式生成 (!AUDIO_LABEL!, !TRIM_LABEL!^)...
    echo.
    echo [1/2] 生成 MP4 (H.264 High, CRF 23^)...
    "!FFMPEG!" !TRIM_SS! -i "!INPUT_FILE!" !TRIM_TO! -c:v libx264 -profile:v high -preset slow -crf 23 !AUDIO_OPTS! -sn -dn -map_metadata -1 -movflags +faststart -pix_fmt yuv420p "!BASENAME!-hq.mp4" -y
    echo.
    echo [2/2] 生成 WebM (VP9, CRF 30^)...
    if /i "!AUDIO_CHOICE!"=="N" (
        "!FFMPEG!" !TRIM_SS! -i "!INPUT_FILE!" !TRIM_TO! -c:v libvpx-vp9 -crf 30 -b:v 0 -an -sn -dn -map_metadata -1 -pix_fmt yuv420p "!BASENAME!-web.webm" -y
    ) else (
        "!FFMPEG!" !TRIM_SS! -i "!INPUT_FILE!" !TRIM_TO! -c:v libvpx-vp9 -crf 30 -b:v 0 -c:a libopus -b:a 128k -sn -dn -map_metadata -1 -pix_fmt yuv420p "!BASENAME!-web.webm" -y
    )
    echo.
    echo [完成] 输出:
    echo   - !FILEDIR!!BASENAME!-hq.mp4
    echo   - !FILEDIR!!BASENAME!-web.webm
)

if "!CHOICE!"=="7" (
    echo [开始] Hero 背景视频专用处理 (!AUDIO_LABEL!, !TRIM_LABEL!^)...
    echo.
    echo [1/2] 缩放至1920x1080 + MP4压缩...
    "!FFMPEG!" !TRIM_SS! -i "!INPUT_FILE!" !TRIM_TO! -c:v libx264 -profile:v high -preset slow -crf 23 !AUDIO_OPTS! -sn -dn -map_metadata -1 -movflags +faststart -pix_fmt yuv420p -vf scale=1920:1080 "hero-bg-compressed.mp4" -y
    echo.
    echo [2/2] 生成 WebM 格式...
    if /i "!AUDIO_CHOICE!"=="N" (
        "!FFMPEG!" !TRIM_SS! -i "!INPUT_FILE!" !TRIM_TO! -c:v libvpx-vp9 -crf 30 -b:v 0 -an -sn -dn -map_metadata -1 -pix_fmt yuv420p -vf scale=1920:1080 "hero-bg-compressed.webm" -y
    ) else (
        "!FFMPEG!" !TRIM_SS! -i "!INPUT_FILE!" !TRIM_TO! -c:v libvpx-vp9 -crf 30 -b:v 0 -c:a libopus -b:a 128k -sn -dn -map_metadata -1 -pix_fmt yuv420p -vf scale=1920:1080 "hero-bg-compressed.webm" -y
    )
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
