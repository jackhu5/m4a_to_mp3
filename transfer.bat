@echo off
setlocal enabledelayedexpansion
color F0
mode con cols=58 lines=30
title=m4a to mp3 v1.0 :By:hujiaqi
:: 设置为 UTF-8 编码，防止中文乱码（可选）
chcp 65001 >nul

:: 创建目标 mp3 文件夹（如果不存在的话）
if not exist "mp3" (
    mkdir "mp3"
)
:: 设置并发数
set THREADS=12
echo 线程数为 %THREADS%

:: 设置文件名列表和工作目录
set FILE_LIST=_filelist.txt
set LOG_FILE=convert_error.log

:: 清理旧文件
del "%FILE_LIST%" 2>nul
del split_*.bat 2>nul
del "%LOG_FILE%" 2>nul

:: 步骤 1：收集所有 .m4a 文件（短路径，防空格）
for %%f in (*.m4a) do echo "%%~sf" >> "%FILE_LIST%"

:: 统计总文件数
set /a COUNT=0
for /f %%i in ('type "%FILE_LIST%" ^| find /c /v ""') do set COUNT=%%i
echo 总文件数为 %COUNT%

if %COUNT%==0 (
    echo 没有找到 .m4a 文件，退出。
    pause
    exit /b
)

:: 计算每组的数量
set /a GROUP_SIZE=%COUNT%/%THREADS%
set /a REMAINDER=%COUNT%%%THREADS%

:: 步骤 2：切割文件列表
set /a INDEX=0
set /a GROUP=1

(for /f "usebackq delims=" %%L in ("%FILE_LIST%") do (
    set /a INDEX+=1
    set /a TARGET=%GROUP_SIZE%
    if !GROUP! LEQ %REMAINDER% set /a TARGET+=1
    if !INDEX! EQU 1 (
        >>split_!GROUP!.bat echo @echo off
        >>split_!GROUP!.bat echo echo dummy > split_!GROUP!.lock
    )
    echo ffmpeg -hide_banner -loglevel error -i %%L -y -acodec libmp3lame -ab 48k "%%~nL.mp3" 2>> "%LOG_FILE%" >> split_!GROUP!.bat

    if !INDEX! GEQ !TARGET! (
        >>split_!GROUP!.bat echo del split_!GROUP!.lock
        echo 完成第 !GROUP! 个子脚本构建，文件名: split_!GROUP!.bat
        set /a INDEX=0
        set /a GROUP+=1
    )
))

:: 确保最后一个子脚本也加上 del
if not !INDEX!==0 (
    >>split_!GROUP!.bat echo del split_!GROUP!.lock
    echo 完成第 !GROUP! 个子脚本构建，文件名: split_!GROUP!.bat

)

:: 步骤 3：并发运行子脚本
echo 启动 %THREADS% 个并行 ffmpeg 实例...
for /l %%i in (1,1,%THREADS%) do (
    if exist split_%%i.bat start "ffmpeg_%%i" /b cmd /c split_%%i.bat
)

:: 步骤 4：等待所有进程完成
echo Waiting for all ffmpeg instances to complete...
:wait_loop
timeout /t 2 >nul
set FOUND=0
for %%F in (split_*.lock) do (
    set FOUND=1
)
if !FOUND!==1 goto wait_loop

:: 移动所有转换后的 mp3 文件到 mp3 文件夹
echo.
echo 正在移动 .mp3 文件到 "mp3" 文件夹...
for %%F in (*.mp3) do (
    move /Y "%%~F" "mp3\">nul
)
::步骤五：清除临时文件
del split_*.bat 2>nul
del "%FILE_LIST%" 2>nul
echo 完成所有任务！
pause
