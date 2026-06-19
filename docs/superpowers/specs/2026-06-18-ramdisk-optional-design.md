# DevUDisk 构建缓存路径可选配置设计

> 日期：2026-06-18  
> 状态：待实施  
> 关联需求：把 RAMDisk 改为可选配置，默认使用本地 SSD，SSD 不可用时自动以 U 盘兜底。

---

## 1. 背景与问题

当前 `StartDevEnv.bat` 启动时**总是**尝试创建 RAMDisk（`R:` 或回退盘符），只有在没有管理员权限或缺少 `aim_ll` 等工具时才回退到 `%TEMP%\DevUDisk_build`。这带来几个问题：

1. **大多数学生电脑已配备 SSD**，RAMDisk 的 I/O 优势不再显著，反而增加管理员依赖和启动复杂度。
2. **`StopDevEnv.bat` 会卸载 RAMDisk**，导致构建缓存完全丢失，跨会话无法享受增量编译收益。
3. **缺少 ccache 配置**，无法进一步利用跨会话的编译缓存。

因此需要将 RAMDisk 改为可选，默认使用本地 SSD 缓存，SSD 不可用时自动 fallback 到 U 盘，以提升系统可用性和持久性。

---

## 2. 目标

1. **默认行为**：不使用 RAMDisk，构建目录指向本地 SSD（`%TEMP%\DevUDisk_build`）。
2. **自动兜底**：当 SSD 空间不足（< 2 GB）或不可写时，自动切换到 U 盘路径（`%U_DISK%\DevUDisk_cache\build`）。
3. **RAMDisk 可选**：仅当显式配置启用时才创建 RAMDisk。
4. **持久化 ccache**：为 ccache 配置持久目录，与构建目录使用相同的存储策略（SSD → U 盘）。
5. **安全退出**：`StopDevEnv.bat` 只清理实际使用的构建目录，不删除 U 盘源码，卸载 RAMDisk 时保留配置。

---

## 3. 设计概述

引入一个轻量级配置文件 `PortableEnv\DevUDisk.ini`，由 `StartDevEnv.bat` 读取。启动时按以下优先级决定构建路径：

```text
1. 若配置/env 显式启用 RAMDisk → 创建 RAMDisk，使用 RAMDisk\arduino_build
2. 否则检查本地 SSD（%TEMP% 所在盘）
   - 空间 >= 2 GB 且可写 → %TEMP%\DevUDisk_build
   - 空间不足或不可写 → %U_DISK%\DevUDisk_cache\build
```

ccache 目录同步按相同策略选择：

```text
SSD:  %TEMP%\DevUDisk_ccache
U盘:  %U_DISK%\DevUDisk_cache\ccache
RAMDisk:  RAMDisk\arduino_ccache  （不推荐，RAMDisk 销毁即失）
```

配置文件中可同时指定显式路径，覆盖自动选择。

---

## 4. 详细设计

### 4.1 配置文件 `PortableEnv\DevUDisk.ini`

首次启动若文件不存在，`StartDevEnv.bat` 自动创建一个默认版本，内容如下：

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

配置文件采用标准 INI 格式，使用 `for /f` 读取，不引入外部依赖。

### 4.2 环境变量覆盖

为便于脚本和 CI 使用，支持以下环境变量：

| 变量 | 说明 |
|------|------|
| `DEVUDISK_USE_RAMDISK` | `1`/`true` 强制启用 RAMDisk；`0`/`false` 强制禁用。优先于配置文件。 |
| `DEVUDISK_BUILD_PATH` | 强制指定构建目录，覆盖所有自动逻辑。 |
| `DEVUDISK_CCACHE_DIR` | 强制指定 ccache 目录，覆盖所有自动逻辑。 |

### 4.3 `StartDevEnv.bat` 修改

新增逻辑（保持现有 RAMDisk 创建代码，但改为条件执行）：

1. **读取配置**：
   - 若 `PortableEnv\DevUDisk.ini` 存在，解析 `use_ramdisk`。
   - 若不存在，使用默认值 `use_ramdisk=false` 并创建默认配置文件。

2. **环境变量覆盖**：
   - 检查 `DEVUDISK_USE_RAMDISK`，若设置则覆盖配置文件值。

3. **路径选择**：
   - 若启用 RAMDisk：执行现有 RAMDisk 创建逻辑，设置 `ARDUINO_BUILD_BASE=%RAMDISK_LETTER%\arduino_build`、`CCACHE_DIR=%RAMDISK_LETTER%\arduino_ccache`。
   - 若未启用 RAMDisk：
     - 检查 `%TEMP%` 所在盘可用空间。
     - 若 `>= 2 GB` 且可写：设置 `ARDUINO_BUILD_BASE=%TEMP%\DevUDisk_build`、`CCACHE_DIR=%TEMP%\DevUDisk_ccache`。
     - 否则：设置 `ARDUINO_BUILD_BASE=%U_DISK%\DevUDisk_cache\build`、`CCACHE_DIR=%U_DISK%\DevUDisk_cache\ccache`，并提示用户。

4. **创建目录**：确保最终选择的目录存在。

5. **PATH 隔离与启动 VS Code**：保持不变。

### 4.4 `StopDevEnv.bat` 修改

1. 读取 `StartDevEnv.bat` 写入的存储策略记录（`%TEMP%\DevUDisk_storage_type.txt`），值为 `ramdisk` / `ssd` / `udisk`。
2. **RAMDisk**：若策略为 `ramdisk`，执行卸载逻辑。
3. **SSD/U 盘**：
   - 不删除整个构建目录，保留增量缓存和 ccache。
   - 仅删除本次会话产生的临时文件（如 `DevUDisk_ramdisk_letter.txt`、`DevUDisk_storage_type.txt`）。
   - 可选：提供 `cleanup_build` 配置项，若用户希望每次退出清理，则执行清理。
4. 弹出 U 盘。

### 4.5 `_build_with_progress.ps1` 修改

1. 接收新的可选参数 `-CcacheDir`。
2. 若传入且 ccache 可执行文件存在，向 `arduino-cli compile` 追加 `--build-property compiler.ccache.cmd=ccache` 并设置环境变量 `CCACHE_DIR`。
3. 若不传入，仅保留现有 `--build-path` 行为。

> 说明：ESP32 Arduino 核心 3.3.10 未内置 ccache 支持，因此需要通过 `platform.local.txt` 或 `--build-property` 注入。本设计采用 `--build-property` 方式，不修改核心包文件。

### 4.6 `tasks.json` 修改

普通示例工程与 `MUS4_FW` 的 `tasks.json` 无需大改，只需确保：

- `-BuildPath` 继续使用 `${env:ARDUINO_BUILD_BASE}`。
- 新增 `-CcacheDir ${env:CCACHE_DIR}` 参数（可选）。

模板 `Projects\_template_.vscode\tasks.json` 同步更新。

### 4.7 ccache 启用细节

由于 `arduino-cli` 对 ESP32 核心的 ccache 支持有限，采用以下方式：

1. 在 `StartDevEnv.bat` 中设置 `CCACHE_DIR` 环境变量。
2. 若系统或 U 盘中存在 `ccache.exe`（可随 U 盘内置 `PortableEnv\ccache\ccache.exe`），在 `PATH` 中加入该目录。
3. `_build_with_progress.ps1` 检测到 `ccache` 可用时，向编译命令追加：
   ```
   --build-property compiler.c.cmd=ccache {compiler.prefix}gcc
   --build-property compiler.cpp.cmd=ccache {compiler.prefix}g++
   ```
   实际实现需验证 ESP32 平台的 property 名称。

> 若 ESP32 平台 property 不支持直接注入 ccache，则退而求其次：仅持久化 `CCACHE_DIR`，由用户自行在 WSL/本机环境使用 ccache；Windows 原生编译暂不开 ccache。

---

## 5. 错误处理

| 场景 | 处理 |
|------|------|
| 配置文件格式错误 | 忽略错误项，使用默认值，并输出警告。 |
| `%TEMP%` 不可写 | 自动 fallback 到 U 盘。 |
| U 盘空间也不足 | 仍使用 U 盘路径，输出严重警告，编译可能失败由 arduino-cli 报错。 |
| RAMDisk 创建失败 | 若显式启用 RAMDisk 但创建失败，输出错误并暂停；不自动 fallback（尊重用户显式选择）。 |
| ccache 不可用 | 仅关闭 ccache，构建仍正常进行。 |

---

## 6. 测试计划

1. **默认 SSD 路径**：不启用 RAMDisk，确认 `ARDUINO_BUILD_BASE=%TEMP%\DevUDisk_build`。
2. **SSD 空间不足 fallback**：临时调大 `min_free_gb`，确认 fallback 到 U 盘。
3. **显式 RAMDisk**：`use_ramdisk=true`，确认创建 RAMDisk。
4. **环境变量覆盖**：`DEVUDISK_USE_RAMDISK=1` 覆盖配置文件 `false`。
5. **跨会话增量**：修改代码后重新编译，确认耗时显著降低。
6. **安全退出**：确认 `StopDevEnv.bat` 不删除 SSD/U 盘缓存目录。

---

## 7. 文档更新

1. 更新 `AGENTS.md`：
   - 修改技术栈表格中“编译加速”描述。
   - 更新脚本执行流程。
   - 更新测试策略。
2. 更新 `Doc/DevUDisk_User_QuickStart_v1.0.md`：
   - 说明默认使用 SSD，RAMDisk 为可选。
   - 说明如何启用 RAMDisk 或自定义路径。
3. 更新 `Doc_Dev/DevUDisk_Design_SilentRamdisk_v1.0.md`：
   - 说明 RAMDisk 现在是可选配置，不再默认启用。

---

## 8. 实现范围

涉及文件：

- `StartDevEnv.bat`（主要修改）
- `StopDevEnv.bat`（清理逻辑调整）
- `PortableEnv\_build_with_progress.ps1`（ccache 参数支持）
- `Projects\_template_.vscode\tasks.json`（模板更新）
- `Projects\Blink\.vscode\tasks.json`
- `Projects\WiFiScan\.vscode\tasks.json`
- `Projects\MUS4_FW\.vscode\tasks.json`
- `AGENTS.md`
- `Doc/DevUDisk_User_QuickStart_v1.0.md`
- `Doc_Dev/DevUDisk_Design_SilentRamdisk_v1.0.md`

---

## 9. 未决事项

1. ESP32 Arduino 核心 3.3.10 的 ccache 注入方式需实际验证；若不可行，先实现 SSD/U 盘缓存路径，ccache 作为二期增强。
2. 是否将 `ccache.exe` 内置到 U 盘（增加 ~10 MB）还是依赖本机/WSL？建议先不内置，通过 PATH 检测可用性。
