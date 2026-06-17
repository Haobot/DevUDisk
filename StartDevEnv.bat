@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion
:: ============================================================
:: DevUDisk 开发环境启动脚本
:: 职责：计算 U 盘盘符、构造隔离 PATH、设置 Arduino 环境变量、
::       创建 RAMDisk（如可用）或回退到本地临时目录、启动 VS Code
:: ============================================================
title DevUDisk - Starting...
:: 1. 计算 U 盘盘符（脚本所在盘符）
set "U_DISK=%~d0"
echo [INFO] U 盘盘符：%U_DISK%
:: 2. 环境初始化校验
echo [INFO] 正在执行 Git Failsafe 自检...
call "%~dp0PortableEnv\_git_failsafe.bat"
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
net session >nul 2>&1
set "IS_ADMIN=0"
if %errorlevel% equ 0 set "IS_ADMIN=1"
:: 5. 选择构建目录：优先 aim_ll 直接创建 RAMDisk，其次 RamService 服务，再其次 ImDisk，最后本地临时目录
set "AIMLL=%U_DISK%\PortableEnv\ImDisk\aim_cli\x64\aim_ll.exe"
set "RAMSERVICE=%U_DISK%\PortableEnv\ImDisk\RamService.exe"
set "IMDISK=%U_DISK%\PortableEnv\ImDisk\imdisk.exe"

:: 5.0 选择可用 RAMDisk 盘符：默认 R:，若已被占用则按优先级回退到 Z: Y: Q: P: O:
::     如需强制指定盘符，将下行改为 set "RAMDISK_LETTER=E:" 即可。注意：必须避开 U 盘自身盘符与现有任何盘。
set "RAMDISK_LETTER=R:"
set "RAMDISK_FALLBACK_LETTERS=Z: Y: Q: P: O:"
echo [INFO] 正在检查 RAMDisk 盘符可用性 ...
set "PICKED_LETTER="
set "_CANDIDATE=%RAMDISK_LETTER%"
call :try_pick_letter
if not defined PICKED_LETTER (
    for %%L in (%RAMDISK_FALLBACK_LETTERS%) do (
        if not defined PICKED_LETTER (
            set "_CANDIDATE=%%L"
            call :try_pick_letter
        )
    )
)
if not defined PICKED_LETTER (
    echo [WARN] 首选 RAMDisk 盘符 %RAMDISK_LETTER% 与所有回退盘符均不可用，将跳过 RAMDisk 直接回退到本地临时目录。
    set "RAMDISK_LETTER="
) else if /i not "!PICKED_LETTER!"=="!RAMDISK_LETTER!" (
    echo [WARN] 首选 RAMDisk 盘符 !RAMDISK_LETTER! 已被占用，自动改用 !PICKED_LETTER!。
    set "RAMDISK_LETTER=!PICKED_LETTER!"
) else (
    echo [INFO] RAMDisk 盘符 !RAMDISK_LETTER! 可用。
)
set "PICKED_LETTER="
set "_CANDIDATE="
echo [INFO] 选定的 RAMDisk 盘符：!RAMDISK_LETTER!
:: 将选中的盘符写入临时文件，供 StopDevEnv.bat 读取并按相同盘符卸载
set "RAMDISK_LETTER_FILE=%TEMP%\DevUDisk_ramdisk_letter.txt"
if defined RAMDISK_LETTER (echo %RAMDISK_LETTER%> "%RAMDISK_LETTER_FILE%") else (del /Q "%RAMDISK_LETTER_FILE%" 2>nul)
set "USE_RAMDISK=0"
:: 如果未找到可用盘符，直接跳过 RAMDisk 创建，避免把空盘符传给底层工具
if not defined RAMDISK_LETTER goto :ramdisk_done

:: 5.1 优先使用 aim_ll 直接创建 RAMDisk（最可靠，不依赖 Windows 服务生命周期）
if exist "%AIMLL%" (
    if %IS_ADMIN% equ 1 (
        echo [INFO] 检测到 aim_ll，正在直接创建 RAMDisk %RAMDISK_LETTER% ...
        REM 临时禁用 Windows 自动分配新卷盘符，避免创建 RAMDisk 时被系统临时挂到 E:/F:/G: 等盘符并弹出“不可用”对话框
        (
            echo automount disable
            echo exit
        ) > "%TEMP%\DevUDisk_diskpart.txt"
        diskpart /s "%TEMP%\DevUDisk_diskpart.txt" >nul 2>&1
        "%AIMLL%" -a -t vm -s 2G -m %RAMDISK_LETTER% -p "/fs:ntfs /q /y"
        set "AIMLL_RESULT=!errorlevel!"
        (
            echo automount enable
            echo exit
        ) > "%TEMP%\DevUDisk_diskpart.txt"
        diskpart /s "%TEMP%\DevUDisk_diskpart.txt" >nul 2>&1
        del /Q "%TEMP%\DevUDisk_diskpart.txt" 2>nul
        if !AIMLL_RESULT! equ 0 (
            echo [INFO] aim_ll 已完成创建，等待卷就绪 ...
            set /a "vol_retry=0"
            :wait_volume
            vol %RAMDISK_LETTER% >nul 2>&1
            if !errorlevel! equ 0 (
                echo [INFO] RAMDisk 创建成功。
                set "ARDUINO_BUILD_BASE=%RAMDISK_LETTER%\arduino_build"
                set "USE_RAMDISK=1"
            ) else (
                set /a "vol_retry+=1"
                if !vol_retry! lss 10 (
                    ping -n 2 127.0.0.1 >nul
                    goto :wait_volume
                ) else (
                    echo [WARN] aim_ll 报告成功但 %RAMDISK_LETTER% 卷未就绪。
                )
            )
        ) else (
            echo [WARN] aim_ll 创建 RAMDisk 失败。可能原因：盘符 %RAMDISK_LETTER% 已被占用，或未安装 Arsenal Image Mounter 驱动。
        )
    ) else (
        echo [WARN] 检测到 aim_ll 但未以管理员身份运行，跳过 RAMDisk。
    )
    goto :ramdisk_done
)

:: 5.2 回退到 Arsenal RAMDisk 服务
if exist "%RAMSERVICE%" (
    if %IS_ADMIN% equ 1 (
        echo [INFO] 检测到 Arsenal RAMDisk 服务工具，正在配置 ...
        sc query ArsenalRamDisk >nul 2>&1
        if !errorlevel! equ 0 (
            echo [INFO] 发现已有 ArsenalRamDisk 服务，正在停止并更新配置 ...
            net stop ArsenalRamDisk >nul 2>&1
            sc config ArsenalRamDisk binPath= "%RAMSERVICE%" start= demand
            if !errorlevel! neq 0 (
                echo [WARN] 更新 ArsenalRamDisk 服务配置失败。
                goto :ramdisk_done
            )
        ) else (
            echo [INFO] 正在创建 ArsenalRamDisk 服务 ...
            sc create ArsenalRamDisk binPath= "%RAMSERVICE%" start= demand
            if !errorlevel! neq 0 (
                echo [WARN] 创建 ArsenalRamDisk 服务失败。
                goto :ramdisk_done
            )
        )
        REM 配置注册表：盘符为启动时动态选中的 RAMDISK_LETTER（去掉冒号），大小 2GB，不同步到磁盘
        echo [INFO] 正在配置 RAMDisk 参数（盘符 %RAMDISK_LETTER%，大小 2GB）...
        set "RAMDISK_LETTER_NOCOLON=%RAMDISK_LETTER::=%"
        reg add "HKLM\SYSTEM\CurrentControlSet\Services\ArsenalRamDisk" /v DiskSize /t REG_SZ /d "2147483648" /f >nul 2>&1
        reg add "HKLM\SYSTEM\CurrentControlSet\Services\ArsenalRamDisk" /v DriveLetter /t REG_SZ /d "!RAMDISK_LETTER_NOCOLON!" /f >nul 2>&1
        reg add "HKLM\SYSTEM\CurrentControlSet\Services\ArsenalRamDisk" /v LoadContent /t REG_SZ /d "" /f >nul 2>&1
        reg add "HKLM\SYSTEM\CurrentControlSet\Services\ArsenalRamDisk" /v SyncContent /t REG_DWORD /d 0 /f >nul 2>&1
        reg add "HKLM\SYSTEM\CurrentControlSet\Services\ArsenalRamDisk" /v DeleteOld /t REG_DWORD /d 0 /f >nul 2>&1
        reg add "HKLM\SYSTEM\CurrentControlSet\Services\ArsenalRamDisk" /v UseTempFolder /t REG_DWORD /d 0 /f >nul 2>&1
        net stop ArsenalRamDisk >nul 2>&1
        echo [INFO] 正在启动 ArsenalRamDisk 服务 ...
        net start ArsenalRamDisk
        if !errorlevel! equ 0 (
            echo [INFO] 等待 RAMDisk 就绪 ...
            set /a "retry=0"
            :wait_ramdisk
            if not exist "%RAMDISK_LETTER%\nul" (
                ping -n 2 127.0.0.1 >nul
                set /a "retry+=1"
                if !retry! lss 30 goto :wait_ramdisk
            )
            if exist "%RAMDISK_LETTER%\nul" (
                echo [INFO] RAMDisk 创建成功。
                set "ARDUINO_BUILD_BASE=%RAMDISK_LETTER%\arduino_build"
                set "USE_RAMDISK=1"
            ) else (
                echo [WARN] RAMDisk 未在预期时间内就绪。
            )
        ) else (
            echo [WARN] 启动 ArsenalRamDisk 服务失败。可能需要先安装 Arsenal Image Mounter 驱动。
        )
    ) else (
        echo [WARN] 检测到 RamService 但未以管理员身份运行，跳过 RAMDisk。
    )
    goto :ramdisk_done
)

:: 5.3 回退到 ImDisk（兼容旧环境）
if exist "%IMDISK%" (
    if %IS_ADMIN% equ 1 (
        echo [INFO] 正在创建 RAMDisk %RAMDISK_LETTER% ...
        "%IMDISK%" -a -s 2G -m %RAMDISK_LETTER% -p "/fs:ntfs /q /y"
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

:ramdisk_done
if %USE_RAMDISK% equ 0 (
    REM 回退到本地临时目录（通常位于主机 SSD，仍比 U 盘快）
    set "ARDUINO_BUILD_BASE=%TEMP%\DevUDisk_build"
    echo [INFO] 使用本地临时构建目录：!ARDUINO_BUILD_BASE!
)
:: 6. 确保构建目录存在
if not exist "%ARDUINO_BUILD_BASE%" mkdir "%ARDUINO_BUILD_BASE%"
echo [INFO] 构建根目录：%ARDUINO_BUILD_BASE%
:: 7. 配置 Git：优先 U 盘内置 Portable Git，其次回退到常见本机 Git 路径
set "GIT_BIN_DIR="
if exist "%U_DISK%\PortableEnv\Git\cmd\git.exe" (
    set "GIT_BIN_DIR=%U_DISK%\PortableEnv\Git\cmd"
    echo [INFO] 已启用 U 盘内置 Git。
) else if exist "C:\Program Files\Git\cmd\git.exe" (
    set "GIT_BIN_DIR=C:\Program Files\Git\cmd"
    echo [WARN] 未找到 U 盘内置 Git，已回退到本机 Git：!GIT_BIN_DIR!
    echo [WARN] 建议将 Portable Git 解压到 %U_DISK%\PortableEnv\Git\ 以获得完全便携体验。
) else if exist "C:\Program Files (x86)\Git\cmd\git.exe" (
    set "GIT_BIN_DIR=C:\Program Files (x86)\Git\cmd"
    echo [WARN] 未找到 U 盘内置 Git，已回退到本机 Git：!GIT_BIN_DIR!
    echo [WARN] 建议将 Portable Git 解压到 %U_DISK%\PortableEnv\Git\ 以获得完全便携体验。
) else (
    echo [WARN] 未找到 Git。VS Code: 终端中将无法使用 git 命令。
)
:: 8. 构造隔离 PATH（仅包含 U 盘内工具、Git 与最小系统路径），在启动 VS Code: 前生效
if defined GIT_BIN_DIR (
    set "PATH=%U_DISK%\PortableEnv\arduino-cli;!GIT_BIN_DIR!;C:\Windows\System32;C:\Windows\System32\WindowsPowerShell\v1.0"
) else (
    set "PATH=%U_DISK%\PortableEnv\arduino-cli;C:\Windows\System32;C:\Windows\System32\WindowsPowerShell\v1.0"
)
echo [INFO] PATH 已隔离：%PATH%
:: 9. 启动 VS Code: 并打开多工程工作区
start "" "%U_DISK%\PortableEnv\VSCode\Code.exe" "%U_DISK%\DevUDisk.code-workspace"
echo [INFO] 开发环境已启动。

:: ============================================================
:: 子例程：检查候选盘符是否可用，若可用则写入 PICKED_LETTER
:: 输入：%_CANDIDATE% (形如 R:)
:: 输出：设置 PICKED_LETTER（可用时）或保持为空
:: ============================================================
:try_pick_letter
if not defined _CANDIDATE exit /b 0
:: 跳过 U 盘自身盘符
if /i "%_CANDIDATE%"=="%U_DISK%" exit /b 0
:: 通过 WMI 查询已存在的逻辑磁盘来判断盘符是否被占用。
:: 这种方式不会真正访问目标卷，因此不会触发“E:\不可用”等空光驱/读卡器弹窗。
powershell -NoProfile -Command "$disk=Get-CimInstance Win32_LogicalDisk | Where-Object { $_.DeviceID -eq '%_CANDIDATE%' }; if ($disk) { exit 1 } else { exit 0 }" >nul 2>&1
if %errorlevel% equ 0 (
    REM 该盘符在系统中不存在，认为可用
    set "PICKED_LETTER=%_CANDIDATE%"
)
exit /b 0

endlocal
