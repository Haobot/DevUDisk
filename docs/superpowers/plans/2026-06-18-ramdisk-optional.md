# DevUDisk RAMDisk 可选与 SSD/U 盘缓存兜底 实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将 DevUDisk 的构建缓存从默认 RAMDisk 改为默认本地 SSD，SSD 不可用时自动 fallback 到 U 盘，RAMDisk 改为通过配置文件显式启用。

**架构：** 在 `StartDevEnv.bat` 中新增配置读取与路径选择逻辑，按“显式 RAMDisk → SSD → U 盘”优先级决定 `ARDUINO_BUILD_BASE` 和 `CCACHE_DIR`；`StopDevEnv.bat` 根据记录的策略仅清理 RAMDisk，保留 SSD/U 盘缓存；构建脚本通过环境变量消费这些路径，不硬编码盘符。

**技术栈：** Windows Batch、PowerShell 5.1、VS Code tasks.json、Arduino-CLI。

---

## 文件结构

| 文件 | 职责 |
|------|------|
| `PortableEnv\DevUDisk.ini` | 用户/管理员可编辑的配置文件，控制 RAMDisk 开关、阈值、强制路径。 |
| `StartDevEnv.bat` | 读取配置、检查 SSD 空间/可写性、选择构建路径、创建 RAMDisk（如启用）、设置 `CCACHE_DIR`、启动 VS Code。 |
| `StopDevEnv.bat` | 根据存储策略卸载 RAMDisk 或保留 SSD/U 盘缓存，清理记录文件，弹出 U 盘。 |
| `PortableEnv\_build_with_progress.ps1` | 接收并导出 `CCACHE_DIR` 环境变量，为后续 ccache 注入做准备。 |
| `Projects\{Blink,WiFiScan,MUS4_FW}\.vscode\tasks.json` | 传递 `BuildPath` 与 `CcacheDir` 参数。 |
| `Projects\_template_.vscode\tasks.json` | 同步更新为模板。 |
| `AGENTS.md` / `Doc/DevUDisk_User_QuickStart_v1.0.md` / `Doc_Dev/DevUDisk_Design_SilentRamdisk_v1.0.md` | 更新文档描述。 |

---

## Task 1: 创建默认配置文件 `PortableEnv\DevUDisk.ini`

**Files:**
- Create: `PortableEnv\DevUDisk.ini`

- [ ] **Step 1: 编写默认配置**

```ini
[build]
; 是否启用 RAMDisk。true=启用，false=禁用（默认）。
use_ramdisk=false

; 可选：强制指定构建目录。留空则按自动策略选择。
; build_path=

; 可选：强制指定 ccache 目录。留空则按自动策略选择。
; ccache_dir=

[thresholds]
; SSD 最小可用空间（GB），低于此值 fallback 到 U 盘。
min_free_gb=2
```

- [ ] **Step 2: Commit**

```bash
git add PortableEnv/DevUDisk.ini
git commit -m "feat: add DevUDisk.ini default config for RAMDisk/SSD/U-disk cache policy"
```

---

## Task 2: 在 `StartDevEnv.bat` 中实现配置读取与路径选择

**Files:**
- Modify: `StartDevEnv.bat`

- [ ] **Step 1: 在设置 U 盘盘符后、RAMDisk 创建前，插入配置读取子例程**

在 `set "U_DISK=%~d0"` 之后、`:: 4. 判断当前是否拥有管理员权限` 之前，插入：

```batch
:: 3.5 读取 DevUDisk 配置
set "DEVUDISK_INI=%~dp0PortableEnv\DevUDisk.ini"
set "CFG_USE_RAMDISK=false"
set "CFG_BUILD_PATH="
set "CFG_CCACHE_DIR="
set "CFG_MIN_FREE_GB=2"
call :read_config

:: 环境变量覆盖配置文件
if defined DEVUDISK_USE_RAMDISK (
    set "CFG_USE_RAMDISK=%DEVUDISK_USE_RAMDISK%"
)
if defined DEVUDISK_BUILD_PATH (
    set "CFG_BUILD_PATH=%DEVUDISK_BUILD_PATH%"
)
if defined DEVUDISK_CCACHE_DIR (
    set "CFG_CCACHE_DIR=%DEVUDISK_CCACHE_DIR%"
)

:: 规范化布尔值
if /i "%CFG_USE_RAMDISK%"=="1" set "CFG_USE_RAMDISK=true"
if /i "%CFG_USE_RAMDISK%"=="0" set "CFG_USE_RAMDISK=false"
if /i "%CFG_USE_RAMDISK%"=="yes" set "CFG_USE_RAMDISK=true"
if /i "%CFG_USE_RAMDISK%"=="no" set "CFG_USE_RAMDISK=false"
```

- [ ] **Step 2: 修改 RAMDisk 创建入口，改为条件执行**

将原来的 `:: 5. 选择构建目录...` 段落整体替换为：

```batch
:: 5. 选择构建目录与缓存目录
set "ARDUINO_BUILD_BASE="
set "CCACHE_DIR="
set "STORAGE_TYPE=ssd"

:: 5.0 若用户强制指定路径，直接使用
if defined CFG_BUILD_PATH (
    set "ARDUINO_BUILD_BASE=%CFG_BUILD_PATH%"
    echo [INFO] 使用强制指定构建目录：%CFG_BUILD_PATH%
)
if defined CFG_CCACHE_DIR (
    set "CCACHE_DIR=%CFG_CCACHE_DIR%"
    echo [INFO] 使用强制指定 ccache 目录：%CFG_CCACHE_DIR%"
)

:: 5.1 显式启用 RAMDisk
if /i "%CFG_USE_RAMDISK%"=="true" (
    echo [INFO] 配置要求启用 RAMDisk ...
    call :create_ramdisk
    if !USE_RAMDISK! equ 1 (
        if not defined ARDUINO_BUILD_BASE set "ARDUINO_BUILD_BASE=%RAMDISK_LETTER%\arduino_build"
        if not defined CCACHE_DIR set "CCACHE_DIR=%RAMDISK_LETTER%\arduino_ccache"
        set "STORAGE_TYPE=ramdisk"
    ) else (
        echo [ERROR] 显式启用 RAMDisk 失败。
        pause
        exit /b 1
    )
)

:: 5.2 未指定路径且未启用 RAMDisk，则自动选择 SSD 或 U 盘
if not defined ARDUINO_BUILD_BASE (
    call :pick_local_or_udisk
)

:: 5.3 确保目录存在
if not exist "%ARDUINO_BUILD_BASE%" mkdir "%ARDUINO_BUILD_BASE%"
if not exist "%CCACHE_DIR%" mkdir "%CCACHE_DIR%"

:: 5.4 记录存储策略，供 StopDevEnv.bat 读取
echo %STORAGE_TYPE%> "%TEMP%\DevUDisk_storage_type.txt"
echo [INFO] 构建根目录：%ARDUINO_BUILD_BASE%
echo [INFO] ccache 目录：%CCACHE_DIR%
echo [INFO] 存储策略：%STORAGE_TYPE%
```

- [ ] **Step 3: 新增配置读取子例程 `:read_config`**

在文件末尾 `endlocal` 之前添加：

```batch
:: ============================================================
:: 子例程：读取 PortableEnv\DevUDisk.ini
:: 输出：CFG_USE_RAMDISK, CFG_BUILD_PATH, CFG_CCACHE_DIR, CFG_MIN_FREE_GB
:: ============================================================
:read_config
if not exist "%DEVUDISK_INI%" (
    echo [INFO] 未找到配置文件 %DEVUDISK_INI%，使用默认设置。
    exit /b 0
)
for /f "usebackq tokens=1,* delims==" %%A in ("%DEVUDISK_INI%") do (
    set "_key=%%A"
    set "_val=%%B"
    call :trim _key
    call :trim _val
    if /i "!_key!"=="use_ramdisk" set "CFG_USE_RAMDISK=!_val!"
    if /i "!_key!"=="build_path" set "CFG_BUILD_PATH=!_val!"
    if /i "!_key!"=="ccache_dir" set "CFG_CCACHE_DIR=!_val!"
    if /i "!_key!"=="min_free_gb" set "CFG_MIN_FREE_GB=!_val!"
)
exit /b 0

:trim
set "s=!%1!"
for /f "tokens=*" %%a in ("!s!") do set "s=%%a"
set "%1=!s!"
exit /b 0
```

- [ ] **Step 4: 新增路径选择子例程 `:pick_local_or_udisk`**

```batch
:: ============================================================
:: 子例程：在 SSD (%TEMP%) 与 U 盘之间自动选择构建路径
:: 输出：设置 ARDUINO_BUILD_BASE, CCACHE_DIR, STORAGE_TYPE
:: ============================================================
:pick_local_or_udisk
:: 检查 %TEMP% 所在盘
for /f "usebackq tokens=2 delims==" %%D in (`wmic logicaldisk where "DeviceID='%TEMP:~0,2%'" get FreeSpace /value 2^>nul ^| find "="`) do (
    set "TEMP_FREE_BYTES=%%D"
)
:: 去掉末尾回车符
set "TEMP_FREE_BYTES=%TEMP_FREE_BYTES: =%"
set /a "TEMP_FREE_GB=%TEMP_FREE_BYTES:~0,-9%"
if "%TEMP_FREE_GB%"=="" set /a "TEMP_FREE_GB=0"

:: 检查可写性
copy /y nul "%TEMP%\DevUDisk_write_test.tmp" >nul 2>&1
set "TEMP_WRITABLE=0"
if %errorlevel% equ 0 (
    set "TEMP_WRITABLE=1"
    del /q "%TEMP%\DevUDisk_write_test.tmp" 2>nul
)

set /a "MIN_FREE_GB=%CFG_MIN_FREE_GB%"
if "%MIN_FREE_GB%"=="" set /a "MIN_FREE_GB=2"

if %TEMP_WRITABLE% equ 1 if %TEMP_FREE_GB% geq %MIN_FREE_GB% (
    set "ARDUINO_BUILD_BASE=%TEMP%\DevUDisk_build"
    set "CCACHE_DIR=%TEMP%\DevUDisk_ccache"
    set "STORAGE_TYPE=ssd"
    echo [INFO] SSD 可用空间约 %TEMP_FREE_GB% GB，使用本地 SSD 构建缓存。
) else (
    set "ARDUINO_BUILD_BASE=%U_DISK%\DevUDisk_cache\build"
    set "CCACHE_DIR=%U_DISK%\DevUDisk_cache\ccache"
    set "STORAGE_TYPE=udisk"
    echo [WARN] SSD 空间不足或不可写（剩余约 %TEMP_FREE_GB% GB），已 fallback 到 U 盘缓存。
)
exit /b 0
```

- [ ] **Step 5: 将原有 RAMDisk 创建代码封装为 `:create_ramdisk` 子例程**

把原 `:: 5.1 优先使用 aim_ll` 到 `:ramdisk_done` 之间的代码整体移入 `:create_ramdisk` 子例程，并在末尾 `goto :eof` 返回。注意：子例程内部原有的 `:wait_volume`、`:wait_ramdisk`、`:pick_ramdisk_letter`、`:try_pick_letter` 标签保持可用。

简化后的框架：

```batch
:create_ramdisk
set "USE_RAMDISK=0"
:: ...（保留原 RAMDisk 创建逻辑，包括 aim_ll / RamService / ImDisk 三条分支）
:: 原逻辑中设置 ARDUINO_BUILD_BASE=%RAMDISK_LETTER%\arduino_build 的地方保留，
:: 但外部 :pick_local_or_udisk 的 if not defined ARDUINO_BUILD_BASE 会覆盖它。
:: 为避免冲突，在 :create_ramdisk 内部仅设置 USE_RAMDISK=1，不设置 ARDUINO_BUILD_BASE。
goto :eof
```

> 注意：原 RAMDisk 创建代码中 `set "ARDUINO_BUILD_BASE=%RAMDISK_LETTER%\arduino_build"` 的赋值需要删除或注释，改由外部统一设置。

- [ ] **Step 6: Commit**

```bash
git add StartDevEnv.bat
git commit -m "feat: make RAMDisk optional, default to SSD with U-disk fallback"
```

---

## Task 3: 修改 `StopDevEnv.bat` 的清理逻辑

**Files:**
- Modify: `StopDevEnv.bat`

- [ ] **Step 1: 读取存储策略并调整清理逻辑**

在 `:ramdisk_done` 之前插入：

```batch
:: 读取存储策略
set "STORAGE_TYPE=ssd"
if exist "%TEMP%\DevUDisk_storage_type.txt" (
    for /f "usebackq delims=" %%T in ("%TEMP%\DevUDisk_storage_type.txt") do set "STORAGE_TYPE=%%T"
)
```

在 `:ramdisk_done` 段落的 `:: 5. 清理本地临时构建目录` 处替换为：

```batch
:ramdisk_done
:: 5. 根据存储策略清理
if /i "%STORAGE_TYPE%"=="ramdisk" (
    echo [INFO] RAMDisk 已卸载，构建缓存随 RAMDisk 释放。
) else (
    echo [INFO] 存储策略为 %STORAGE_TYPE%，保留持久化构建缓存以提高下次启动速度。
    :: 仅清理记录文件，不删除 SSD/U 盘缓存目录
)

:: 5.1 清理本次会话的临时记录文件
if exist "%TEMP%\DevUDisk_ramdisk_letter.txt" del /Q "%TEMP%\DevUDisk_ramdisk_letter.txt" >nul 2>&1
if exist "%TEMP%\DevUDisk_storage_type.txt" del /Q "%TEMP%\DevUDisk_storage_type.txt" >nul 2>&1
```

删除原 `:: 5. 清理本地临时构建目录` 中的 `rmdir /S /Q "%TEMP%\DevUDisk_build"`。

- [ ] **Step 2: Commit**

```bash
git add StopDevEnv.bat
git commit -m "feat: preserve SSD/U-disk build cache on exit, only cleanup RAMDisk"
```

---

## Task 4: 修改 `PortableEnv\_build_with_progress.ps1` 支持 `CCACHE_DIR`

**Files:**
- Modify: `PortableEnv\_build_with_progress.ps1`

- [ ] **Step 1: 新增可选参数并导出环境变量**

在参数块末尾添加：

```powershell
[Parameter(Mandatory = $false)]
[string]$CcacheDir = ""
```

在 `# 确保构建路径存在` 之后插入：

```powershell
# 确保 ccache 目录存在并导出环境变量
if ($CcacheDir -and ($CcacheDir -ne '""')) {
    if (-not (Test-Path -Path $CcacheDir)) {
        New-Item -ItemType Directory -Path $CcacheDir -Force | Out-Null
    }
    [Environment]::SetEnvironmentVariable('CCACHE_DIR', $CcacheDir, 'Process')
    Write-Host "[INFO] ccache 目录: $CcacheDir"
}
```

- [ ] **Step 2: Commit**

```bash
git add PortableEnv/_build_with_progress.ps1
git commit -m "feat: support CCACHE_DIR in build progress wrapper"
```

---

## Task 5: 更新所有 `tasks.json` 传递 `CcacheDir`

**Files:**
- Modify: `Projects\_template_.vscode\tasks.json`
- Modify: `Projects\Blink\.vscode\tasks.json`
- Modify: `Projects\WiFiScan\.vscode\tasks.json`
- Modify: `Projects\MUS4_FW\.vscode\tasks.json`

- [ ] **Step 1: 更新模板 `Projects\_template_.vscode\tasks.json`**

在 `"-SketchDir", "${workspaceFolder}"` 之后添加：

```json
,
"-CcacheDir", "${env:CCACHE_DIR}"
```

- [ ] **Step 2: 同步更新 Blink/WiFiScan/MUS4_FW 的 tasks.json**

对每个文件执行相同修改。

- [ ] **Step 3: Commit**

```bash
git add Projects/_template_.vscode/tasks.json Projects/Blink/.vscode/tasks.json Projects/WiFiScan/.vscode/tasks.json Projects/MUS4_FW/.vscode/tasks.json
git commit -m "feat: pass CCACHE_DIR to build wrapper in all tasks"
```

---

## Task 6: 更新 `AGENTS.md`

**Files:**
- Modify: `AGENTS.md`

- [ ] **Step 1: 更新技术栈表格**

将“编译加速”行：

```markdown
| 编译加速 | RAMDisk（Arsenal Image Mounter + aim_ll.exe，可选） | 优先动态可用盘符；无 aim_ll 时回退到 RamService/ImDisk，最后回退到 `%TEMP%/DevUDisk_build` |
```

改为：

```markdown
| 编译加速 | 本地 SSD 缓存（默认）+ U 盘兜底 + 可选 RAMDisk | 默认 `%TEMP%\DevUDisk_build`；SSD 空间不足或不可写时 fallback 到 `%U_DISK%\DevUDisk_cache\build`；RAMDisk 通过 `PortableEnv\DevUDisk.ini` 显式启用 |
```

- [ ] **Step 2: 更新 `StartDevEnv.bat` 执行流程**

在“调用 `_env_init.bat` 校验环境”和“设置 Arduino CLI 环境变量”之间插入：

```markdown
2.5. 读取 `PortableEnv\DevUDisk.ini` 配置与环境变量覆盖，决定存储策略（SSD / U 盘 / RAMDisk）。
```

- [ ] **Step 3: 更新测试策略**

在测试表中新增：

```markdown
| SSD 默认路径 | 未启用 RAMDisk 时 `ARDUINO_BUILD_BASE` 指向 `%TEMP%\DevUDisk_build` | ⏳ |
| SSD 不足 fallback | 调大 `min_free_gb` 后自动切换到 `%U_DISK%\DevUDisk_cache\build` | ⏳ |
| RAMDisk 显式启用 | `use_ramdisk=true` 时正常创建 RAMDisk | ⏳ |
| 跨会话缓存保留 | 退出后 SSD/U 盘缓存目录不被删除 | ⏳ |
```

- [ ] **Step 4: Commit**

```bash
git add AGENTS.md
git commit -m "docs: update AGENTS.md for optional RAMDisk and SSD/U-disk cache policy"
```

---

## Task 7: 更新用户文档

**Files:**
- Modify: `Doc\DevUDisk_User_QuickStart_v1.0.md`
- Modify: `Doc_Dev\DevUDisk_Design_SilentRamdisk_v1.0.md`

- [ ] **Step 1: 在快速开始文档中说明新默认行为**

新增一节“构建缓存位置”：

```markdown
## 构建缓存位置

DevUDisk 默认使用本地 SSD（`%TEMP%\DevUDisk_build`）作为构建缓存，退出时不会删除，以便下次启动享受增量编译加速。

如果本地 SSD 空间不足（默认阈值 2 GB）或不可写，会自动 fallback 到 U 盘路径（`U:\DevUDisk_cache\build`）。

如需启用 RAMDisk，编辑 `PortableEnv\DevUDisk.ini`：

```ini
[build]
use_ramdisk=true
```
```

- [ ] **Step 2: 在 SilentRamdisk 设计文档中说明 RAMDisk 已变为可选**

在开头新增提示：

```markdown
> 注意：自本版本起，RAMDisk 不再是默认行为。默认使用本地 SSD 缓存，SSD 不可用时 fallback 到 U 盘。RAMDisk 仅作为可选加速方案，通过 `PortableEnv\DevUDisk.ini` 启用。
```

- [ ] **Step 3: Commit**

```bash
git add Doc/DevUDisk_User_QuickStart_v1.0.md Doc_Dev/DevUDisk_Design_SilentRamdisk_v1.0.md
git commit -m "docs: explain SSD-default cache and optional RAMDisk to users"
```

---

## Task 8: 测试

**Files:**
- 测试对象：`StartDevEnv.bat`、`StopDevEnv.bat`

- [ ] **Step 1: 语法检查 Batch 脚本**

```bash
cmd /c "StartDevEnv.bat /?" 2>&1 | head -20 || true
cmd /c "StopDevEnv.bat /?" 2>&1 | head -20 || true
```

> 注意：由于脚本依赖 U 盘盘符和交互式环境，完整运行需在真实 U 盘环境中测试。

- [ ] **Step 2: 在测试环境中运行 `StartDevEnv.bat`**

预期输出包含：

```
[INFO] 构建根目录：C:\Users\...\AppData\Local\Temp\DevUDisk_build
[INFO] ccache 目录：C:\Users\...\AppData\Local\Temp\DevUDisk_ccache
[INFO] 存储策略：ssd
```

- [ ] **Step 3: 测试 SSD 空间不足 fallback**

临时修改 `PortableEnv\DevUDisk.ini`：

```ini
[thresholds]
min_free_gb=99999
```

重新运行 `StartDevEnv.bat`，预期输出：

```
[WARN] SSD 空间不足或不可写（剩余约 X GB），已 fallback 到 U 盘缓存。
[INFO] 构建根目录：U:\DevUDisk_cache\build
[INFO] 存储策略：udisk
```

- [ ] **Step 4: 测试 RAMDisk 显式启用**

```ini
[build]
use_ramdisk=true
```

以管理员身份运行 `StartDevEnv.bat`，预期创建 RAMDisk 并输出：

```
[INFO] 存储策略：ramdisk
```

- [ ] **Step 5: 测试安全退出保留缓存**

运行 `StopDevEnv.bat` 后，验证：

```bash
ls -la "$TEMP/DevUDisk_build" 2>/dev/null && echo "SSD cache preserved"
ls -la "U:/DevUDisk_cache/build" 2>/dev/null && echo "U-disk cache preserved"
```

- [ ] **Step 6: Commit 测试结果备注**

```bash
git commit --allow-empty -m "test: manual verification of SSD default, U-disk fallback, and optional RAMDisk"
```

---

## Self-Review Checklist

- [x] **Spec coverage:** 所有需求（默认 SSD、U 盘 fallback、RAMDisk 可选、ccache 目录、StopDevEnv 保留缓存）均有对应任务。
- [x] **Placeholder scan:** 无 TBD/TODO，所有步骤包含具体代码或命令。
- [x] **Type consistency:** `CFG_USE_RAMDISK`、`STORAGE_TYPE`、`ARDUINO_BUILD_BASE`、`CCACHE_DIR` 名称在全计划中一致。
- [x] **边界情况:** 显式启用 RAMDisk 失败时直接报错暂停；SSD 不可写时 fallback；U 盘空间不足时仍使用并输出警告。
