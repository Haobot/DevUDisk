# DevUDisk RAMDisk 静默创建实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 修改 `StartDevEnv.bat`，使其在创建 RAMDisk 前清理遗留 RAMDisk、创建成功后关闭自动弹出的资源管理器窗口，并以静默方式完成启动。

**Architecture:** 复用已有的 `PortableEnv\_cleanup_ramdisks.ps1` 在创建前卸载遗留 AIM RAMDisk；将盘符选择逻辑提取为子例程以便清理后重新评估；在卷就绪后通过 `Shell.Application` COM 对象关闭指向该盘符的资源管理器窗口。

**Tech Stack:** Windows Batch, PowerShell, Arsenal Image Mounter (`aim_ll.exe`)

---

## 文件变更清单

| 文件 | 操作 | 说明 |
|------|------|------|
| `StartDevEnv.bat` | 修改 | 新增清理调用、重新选择盘符、关闭资源管理器窗口 |
| `PortableEnv\_cleanup_ramdisks.ps1` | 不修改 | 复用已有脚本 |

---

### Task 1: 将盘符选择逻辑提取为可复用子例程

**Files:**
- Modify: `StartDevEnv.bat:36-66`

**背景：** 当前盘符选择内联在主流程中，清理遗留 RAMDisk 后需要再次执行选择，因此需要将其提取为子例程。

- [ ] **Step 1: 在原位调用子例程并定义 `:pick_ramdisk_letter`**

替换 `StartDevEnv.bat` 第 36-66 行（从 `set "RAMDISK_LETTER=R:"` 到 `echo [INFO] 选定的 RAMDisk 盘符：!RAMDISK_LETTER!`）为以下代码：

```bat
:: 5.0 选择可用 RAMDisk 盘符：默认 R:，若已被占用则按优先级回退到 Z: Y: Q: P: O:
::     如需强制指定盘符，将下行改为 set "RAMDISK_LETTER=E:" 即可。注意：必须避开 U 盘自身盘符与现有任何盘。
set "RAMDISK_LETTER=R:"
set "RAMDISK_FALLBACK_LETTERS=Z: Y: Q: P: O:"
echo [INFO] 正在检查 RAMDisk 盘符可用性 ...
call :pick_ramdisk_letter
echo [INFO] 选定的 RAMDisk 盘符：!RAMDISK_LETTER!
```

- [ ] **Step 2: 在文件末尾（`endlocal` 之前）添加 `:pick_ramdisk_letter` 子例程**

```bat
:: ============================================================
:: 子例程：选择可用 RAMDisk 盘符
:: 输入：%RAMDISK_LETTER%（首选盘符）, %RAMDISK_FALLBACK_LETTERS%（回退列表）
:: 输出：设置 RAMDISK_LETTER 为可用盘符；若均不可用则置空
:: ============================================================
:pick_ramdisk_letter
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
exit /b 0
```

- [ ] **Step 3: 验证原始 `:try_pick_letter` 子例程位置不变**

确认 `:try_pick_letter` 仍位于文件末尾、`endlocal` 之前。

- [ ] **Step 4: 提交**

```bash
git add StartDevEnv.bat
git commit -m "refactor: extract RAMDisk letter selection into reusable subroutine"
```

---

### Task 2: 在创建 RAMDisk 前清理遗留 RAMDisk

**Files:**
- Modify: `StartDevEnv.bat:72-81`

**背景：** 若上次启动未正常退出或 `StopDevEnv.bat` 未执行，已有 RAMDisk 会占用盘符，导致 `StartDevEnv.bat` 回退到其他盘符并创建第二个 RAMDisk。

- [ ] **Step 1: 在 `aim_ll` 创建 RAMDisk 之前插入清理调用**

找到 `StartDevEnv.bat` 中如下片段（约第 72 行开始）：

```bat
:: 5.1 优先使用 aim_ll 直接创建 RAMDisk（最可靠，不依赖 Windows 服务生命周期）
if exist "%AIMLL%" (
    if %IS_ADMIN% equ 1 (
        echo [INFO] 检测到 aim_ll，正在直接创建 RAMDisk %RAMDISK_LETTER% ...
```

在其后、`diskpart` 调用之前插入：

```bat
        REM 创建前先清理可能遗留的 AIM RAMDisk，避免重复建立
        if exist "%U_DISK%\PortableEnv\_cleanup_ramdisks.ps1" (
            echo [INFO] 正在清理可能遗留的 RAMDisk ...
            powershell -NoProfile -ExecutionPolicy Bypass -File "%U_DISK%\PortableEnv\_cleanup_ramdisks.ps1" -AimLlPath "%AIMLL%"
        )
        REM 清理后重新选择盘符，确保默认盘符被释放后能优先使用
        call :pick_ramdisk_letter
        echo [INFO] 清理后选定的 RAMDisk 盘符：!RAMDISK_LETTER!
        if not defined RAMDISK_LETTER goto :ramdisk_done
```

- [ ] **Step 2: 确认插入位置正确**

插入后的结构应为：

```bat
    if %IS_ADMIN% equ 1 (
        echo [INFO] 检测到 aim_ll，正在直接创建 RAMDisk %RAMDISK_LETTER% ...
        REM 创建前先清理可能遗留的 AIM RAMDisk，避免重复建立
        if exist "%U_DISK%\PortableEnv\_cleanup_ramdisks.ps1" (
            echo [INFO] 正在清理可能遗留的 RAMDisk ...
            powershell -NoProfile -ExecutionPolicy Bypass -File "%U_DISK%\PortableEnv\_cleanup_ramdisks.ps1" -AimLlPath "%AIMLL%"
        )
        REM 清理后重新选择盘符，确保默认盘符被释放后能优先使用
        call :pick_ramdisk_letter
        echo [INFO] 清理后选定的 RAMDisk 盘符：!RAMDISK_LETTER!
        if not defined RAMDISK_LETTER goto :ramdisk_done
        REM 临时禁用 Windows 自动分配新卷盘符 ...
```

- [ ] **Step 3: 提交**

```bash
git add StartDevEnv.bat
git commit -m "feat: cleanup leftover RAMDisk before creating a new one"
```

---

### Task 3: RAMDisk 创建成功后关闭自动弹出的资源管理器窗口

**Files:**
- Modify: `StartDevEnv.bat:89-107`

**背景：** Windows 在新卷挂载后可能自动打开资源管理器窗口，需要静默关闭指向当前 RAMDisk 的窗口。

- [ ] **Step 1: 在卷就绪后插入窗口关闭命令**

找到 `:wait_volume` 标签内如下片段：

```bat
            if !errorlevel! equ 0 (
                echo [INFO] RAMDisk 创建成功。
                set "ARDUINO_BUILD_BASE=%RAMDISK_LETTER%\arduino_build"
                set "USE_RAMDISK=1"
```

在 `echo [INFO] RAMDisk 创建成功。` 之后、`set "ARDUINO_BUILD_BASE=..."` 之前插入：

```bat
                REM 关闭因新卷挂载而自动打开的资源管理器窗口，保持静默
                powershell -NoProfile -Command "& {$shell=New-Object -ComObject Shell.Application; $path='%RAMDISK_LETTER%'; $shell.Windows() | Where-Object { ($_.Document -and $_.Document.Folder -and ($_.Document.Folder.Self.Path -eq $path)) -or ($_.LocationURL -like ('file:///' + $path + '*')) } | ForEach-Object { $_.Quit() }}" >nul 2>&1
```

- [ ] **Step 2: 确认插入位置正确**

插入后应类似：

```bat
            if !errorlevel! equ 0 (
                echo [INFO] RAMDisk 创建成功。
                REM 关闭因新卷挂载而自动打开的资源管理器窗口，保持静默
                powershell -NoProfile -Command "& {$shell=New-Object -ComObject Shell.Application; $path='%RAMDISK_LETTER%'; $shell.Windows() | Where-Object { ($_.Document -and $_.Document.Folder -and ($_.Document.Folder.Self.Path -eq $path)) -or ($_.LocationURL -like ('file:///' + $path + '*')) } | ForEach-Object { $_.Quit() }}" >nul 2>&1
                set "ARDUINO_BUILD_BASE=%RAMDISK_LETTER%\arduino_build"
                set "USE_RAMDISK=1"
```

- [ ] **Step 3: 提交**

```bash
git add StartDevEnv.bat
git commit -m "feat: close auto-opened explorer window after RAMDisk creation"
```

---

### Task 4: 语法检查与验证

**Files:**
- Read: `StartDevEnv.bat`

- [ ] **Step 1: Batch 语法预检**

在 Git Bash 中运行：

```bash
cmd /c "StartDevEnv.bat" < /dev/null
```

由于脚本需要管理员权限和 `aim_ll.exe`，非管理员/非目标机器运行会提前退出，但应确认没有 Batch 语法错误（如 `\` 被错误解析、`if` 块内使用了 `::` 注释等）。

预期输出（非管理员环境）：脚本应打印 `[WARN] 检测到 aim_ll 但未以管理员身份运行，跳过 RAMDisk。` 或类似信息，然后继续启动 VS Code:（如果存在）。不应出现 `"此时不应有 ..."` 等 Batch 解析错误。

- [ ] **Step 2: 手动验证静默创建**

在目标 U 盘环境中以管理员身份运行 `StartDevEnv.bat`，确认：

1. 终端输出中出现 `[INFO] 正在清理可能遗留的 RAMDisk ...`
2. RAMDisk 创建完成后，资源管理器没有自动打开新磁盘窗口。
3. VS Code: 正常启动，`ARDUINO_BUILD_BASE` 指向 RAMDisk 路径（如 `R:\arduino_build`）。

- [ ] **Step 3: 手动验证避免重复建立**

1. 保持当前 RAMDisk 不卸载，再次以管理员身份运行 `StartDevEnv.bat`。
2. 确认脚本先清理遗留 RAMDisk，然后在默认盘符（通常是 `R:`）重新创建，不会回退到 `Z:` 等备用盘符。
3. 检查 `aim_ll -l` 或资源管理器，确认只存在一个 RAMDisk。

- [ ] **Step 4: 提交**

```bash
git add Doc_Dev/DevUDisk_Design_SilentRamdisk_v1.0.md Doc_Dev/DevUDisk_Plan_SilentRamdisk_v1.0.md
git commit -m "docs: add silent RAMDisk creation design and implementation plan"
```

---

## Self-Review

**1. Spec coverage:**
- 静默关闭资源管理器窗口 → Task 3
- 避免重复建立 RAMDisk → Task 2
- 清理后重新评估盘符 → Task 1 + Task 2
- Batch 规范（`REM` 注释、`%~d0`、UTF-8 without BOM）→ 贯穿所有任务

**2. Placeholder scan:**
- 无 TBD/TODO
- 所有代码片段为实际可插入内容
- 所有命令包含预期输出

**3. Type consistency:**
- `RAMDISK_LETTER` 变量使用一致
- `_cleanup_ramdisks.ps1` 参数名 `-AimLlPath` 与脚本一致
- `Shell.Application` 关闭窗口逻辑与设计文档一致
