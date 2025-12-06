@echo off
setlocal enabledelayedexpansion

REM 设置当前目录为脚本所在目录
cd /d "%~dp0"

REM 检查参数数量
if "%~1"=="" (
    echo 用法: %~nx0 ^<m3u8_url^> ^<output_filename.mp4^>
    echo 示例: %~nx0 "https://example.com/video.m3u8" "video.mp4"
    pause
    exit /b 1
)

if "%~2"=="" (
    echo 错误：需要提供输出文件名
    echo 用法: %~nx0 ^<m3u8_url^> ^<output_filename.mp4^>
    pause
    exit /b 1
)

REM 获取参数
set "URL=%~1"
set "OUTPUT_FILE=%~2"

REM 检查输出文件名是否为mp4格式
echo %OUTPUT_FILE% | findstr /i "\.mp4$" >nul
if errorlevel 1 (
    echo 错误：输出文件名必须以.mp4结尾
    echo 当前文件名: %OUTPUT_FILE%
    pause
    exit /b 1
)

REM 创建临时目录
set "TEMP_DIR=./test/tmp"
if not exist "%TEMP_DIR%" mkdir "%TEMP_DIR%"

REM 设置中间文件路径
set "M3U8_FILE=%TEMP_DIR%/index.m3u8"
set "TS_FILE=./test/one.ts"
set "TEMP_MP4=./test/one.mp4"

echo ========================================
echo 开始下载和处理视频
echo 源URL: %URL%
echo 输出文件: %OUTPUT_FILE%
echo ========================================

REM 函数：在一行显示进度
set "LINE_POS=0"
goto :main

:ShowProgress
set "PROGRESS_TEXT=%~1"
set /a LINE_POS+=1
set "PROGRESS_DOTS="
for /l %%i in (1,1,!LINE_POS!) do set "PROGRESS_DOTS=!PROGRESS_DOTS!."
<nul set /p "=!PROGRESS_TEXT!!PROGRESS_DOTS!"
exit /b

:main

REM 步骤1：下载m3u8视频流列表文件
call :ShowProgress "[1/4] 下载m3u8文件"
python ./test/download.py download "%URL%" >nul 2>&1
if errorlevel 1 (
    echo.
    echo 错误：m3u8文件下载失败
    pause
    exit /b 1
)
echo   完成

REM 步骤2：下载视频片段
call :ShowProgress "[2/4] 下载视频片段"
python ./test/download.py parse "%M3U8_FILE%" -r "%URL%" >nul 2>&1
if errorlevel 1 (
    echo.
    echo 错误：视频片段下载失败
    pause
    exit /b 1
)
echo   完成

REM 步骤3：合并片段文件
call :ShowProgress "[3/4] 合并视频片段"
python ./test/download.py combine "%M3U8_FILE%" -s "%TEMP_DIR%" -d "%TS_FILE%" >nul 2>&1
if errorlevel 1 (
    echo.
    echo 错误：视频合并失败
    pause
    exit /b 1
)
echo   完成

REM 步骤4：转换为mp4格式
call :ShowProgress "[4/4] 转换为mp4格式"
ffmpeg -i "%TS_FILE%" -c:v copy -c:a copy "%TEMP_MP4%" -hide_banner -loglevel error
if errorlevel 1 (
    echo.
    echo 错误：MP4转换失败
    pause
    exit /b 1
)
echo   完成

REM 重命名为用户指定的文件名
echo.
echo 重命名为最终文件名...
if exist "%TEMP_MP4%" (
    move /y "%TEMP_MP4%" "%OUTPUT_FILE%" >nul
    if errorlevel 1 (
        echo 错误：重命名文件失败
        pause
        exit /b 1
    )
    echo   完成
)

REM 自动清理临时文件
echo.
echo 清理临时文件...
if exist "%TS_FILE%" del "%TS_FILE%" >nul
if exist "%TEMP_DIR%" rmdir /s /q "%TEMP_DIR%" >nul
echo 临时文件已清理

echo.
echo ========================================
echo 处理完成！
echo 输出文件: %OUTPUT_FILE%
echo ========================================

pause
exit /b