@echo off
setlocal

:: ============================================================
:: DevUDisk 开发环境安全退出脚本
:: 职责：结束 VS Code 进程、卸载 RAMDisk（如存在）、清理临时构建目录、弹出 U 盘
:: ============================================================

title DevUDisk - Stopping...

:: 1. 计算 U 盘盘符
set "U_DISK=%~d0"
echo [INFO] U 盘盘符：%U_DISK%

:: 2. 结束 VS Code 进程
echo [INFO] 正在关闭 VS Code...
taskkill /F /IM Code.exe >/dev/null 2>&1
C:\Windows\System32\timeout.exe /t 2 >/dev/null

:: 3. 判断当前是否拥有管理员权限
net session >/dev/null 2>&1
set "IS_ADMIN=0"
if %errorlevel% equ 0 set "IS_ADMIN=1"

:: 4. 卸载 RAMDisk（如果存在）
set "IMDISK=%U_DISK%\PortableEnv\ImDisk\imdisk.exe"
set "RAMDISK_LETTER=R:"
if exist "%IMDISK%" (
    if %IS_ADMIN% equ 1 (
        echo [INFO] 正在卸载 RAMDisk %RAMDISK_LETTER% ...
        "%IMDISK%" -D -m %RAMDISK_LETTER%
        if %errorlevel% neq 0 (
            echo [WARN] RAMDisk 卸载可能失败，请手动检查。
        ) else (
            echo [INFO] RAMDisk 已卸载。
        )
    ) else (
        echo [WARN] 未以管理员身份运行，跳过 RAMDisk 卸载。
    )
)

:: 5. 清理本地临时构建目录
echo [INFO] 正在清理临时构建目录...
if exist "%TEMP%\DevUDisk_build" (
    rmdir /S /Q "%TEMP%\DevUDisk_build"
)

:: 6. 弹出 U 盘
echo [INFO] 正在弹出 U 盘 %U_DISK% ...
powershell -NoProfile -Command "$disk='%U_DISK%'.Replace(':',''); try { (New-Object -comObject Shell.Application).Namespace(17).ParseName($disk+':').InvokeVerb('Eject') } catch { Write-Host '[WARN] 弹出 U 盘失败，请手动安全删除。' }"

echo [INFO] 可以安全拔出 U 盘。
C:\Windows\System32\timeout.exe /t 3 >/dev/null
endlocal
