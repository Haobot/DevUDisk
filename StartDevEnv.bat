@echo off
setlocal EnableDelayedExpansion

:: ============================================================
:: DevUDisk 开发环境启动脚本
:: 职责：计算 U 盘盘符、构造隔离 PATH、设置 Arduino 环境变量、
::       创建 RAMDisk（如可用）或回退到本地临时目录、启动 VS Code
:: ============================================================

title DevUDisk - Starting...

:: 1. 计算 U 盘盘符（脚本所在盘符）
set "U_DISK=%~d0"
set "U_DISK_ROOT=%U_DISK%\"
echo [INFO] U 盘盘符：%U_DISK%

:: 2. 环境初始化校验
call "%~dp0PortableEnv\_env_init.bat"
if %errorlevel% neq 0 (
    echo [ERROR] 环境初始化失败。
    pause
    exit /b 1
)

:: 3. 设置 Arduino CLI 环境变量，确保只读取 U 盘内数据
set "ARDUINO_DIRECTORIES_DATA=%U_DISK%\PortableEnv\arduino-cli"
set "ARDUINO_DIRECTORIES_USER=%U_DISK%\Projects"
set "ARDUINO_DIRECTORIES_DOWNLOADS=%U_DISK%\PortableEnv\arduino-cli\staging"
echo [INFO] Arduino 数据目录：%ARDUINO_DIRECTORIES_DATA%

:: 4. 判断当前是否拥有管理员权限
net session >/dev/null 2>&1
set "IS_ADMIN=0"
if %errorlevel% equ 0 set "IS_ADMIN=1"

:: 5. 选择构建目录：优先 RAMDisk，其次本地临时目录，最后 U 盘
set "IMDISK=%U_DISK%\PortableEnv\ImDisk\imdisk.exe"
set "RAMDISK_LETTER=R:"
set "USE_RAMDISK=0"

if exist "%IMDISK%" (
    if %IS_ADMIN% equ 1 (
        echo [INFO] 正在创建 RAMDisk %RAMDISK_LETTER% ...
        "%IMDISK%" -a -s 1G -m %RAMDISK_LETTER% -p "/fs:ntfs /q /y"
        if !errorlevel! equ 0 (
            echo [INFO] RAMDisk 创建成功。
            set "ARDUINO_BUILD_BASE=%RAMDISK_LETTER%\arduino_build"
            set "USE_RAMDISK=1"
        ) else (
            echo [WARN] RAMDisk 创建失败。
        )
    ) else (
        echo [WARN] 检测到 ImDisk 但未以管理员身份运行，跳过 RAMDisk。
    )
)

if %USE_RAMDISK% equ 0 (
    :: 回退到本地临时目录（通常位于主机 SSD，仍比 U 盘快）
    set "ARDUINO_BUILD_BASE=%TEMP%\DevUDisk_build"
    echo [INFO] 使用本地临时构建目录：!ARDUINO_BUILD_BASE!
)

:: 6. 确保构建目录存在
if not exist "%ARDUINO_BUILD_BASE%" mkdir "%ARDUINO_BUILD_BASE%"
echo [INFO] 构建根目录：%ARDUINO_BUILD_BASE%

:: 7. 构造隔离 PATH（仅包含 U 盘内工具与最小系统路径），在启动 VS Code 前生效
set "PATH=%U_DISK%\PortableEnv\arduino-cli;C:\Windows\System32;C:\Windows\System32\WindowsPowerShell\v1.0"
echo [INFO] PATH 已隔离：%PATH%

:: 8. 启动 VS Code 并打开 Projects 目录
start "" "%U_DISK%\PortableEnv\VSCode\Code.exe" "%U_DISK%\Projects"

echo [INFO] 开发环境已启动。
endlocal
