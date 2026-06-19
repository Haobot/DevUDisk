<!-- From: D:/AGENTS.md -->
# DevUDisk 项目代理指南

> 本文档面向需要在该仓库中工作的 AI 编码代理。阅读前假设你对项目一无所知。

---

## 1. 项目概述

**DevUDisk** 是一个面向 ESP32 教学、竞赛与现场开发的“编程 U 盘”设计与制作方案仓库，目标是在 Windows 机房等受限环境下提供即插即用的便携 Arduino-ESP32 开发环境。

- **仓库地址：** `https://github.com/Haobot/DevUDisk.git`
- **当前分支：** `main`
- **当前状态：** 第一阶段（Arduino-ESP32 基础环境）已完成并交付。U 盘内已包含可独立运行的 Arduino-CLI、ESP32 Arduino 核心包、VS Code 便携版、示例工程、串口驱动和启动/退出脚本。ESP-IDF、AI 插件（Continue）、Portable Git 和量产镜像列为二期可选项。
- **核心目标：** 实现“插上即用、环境隔离、极速编译、AI 辅助、批量交付”的便携式 ESP32 开发环境。

### 1.1 已存在的文件

```text
D:/
├── .git/                                         # Git 仓库
├── .gitignore                                    # Git 忽略规则
├── AGENTS.md                                     # 本文件（项目代理指南）
├── LICENSE                                       # Apache License 2.0
├── README.md                                     # 项目双语说明（GitHub 入口）
├── Doc/                                          # 用户说明文档
│   └── DevUDisk_User_QuickStart_v1.0.md          # 5 分钟上手指南
├── Doc_Dev/                                      # 开发者/代理文档
│   ├── DevUDisk_DocumentRules_v1.1.md            # 文档管理规则
│   ├── DevUDisk_Design_SilentRamdisk_v1.0.md     # 静默 RAMDisk 设计说明
│   ├── DevUDisk_Plan_SilentRamdisk_v1.0.md       # 静默 RAMDisk 规划
│   └── DevUDisk_Plan_v1.0/                       # Plan v1.0 文档族
│       ├── DevUDisk_Plan_v1.0.md                 # 《编程 U 盘设计与制作方案 v1.0》（原版 ESP-IDF 规划）
│       ├── DevUDisk_Plan_ActionPlan_v1.0.md      # 当前开发行动规划
│       └── DevUDisk_Plan_DeliveryNotes_v1.0.md   # 第一阶段交付说明
├── PortableEnv/                                  # 便携工具链（被 .gitignore 排除）
│   ├── DevUDisk.ini                              # 构建缓存策略配置文件（RAMDisk/SSD/U 盘）
│   ├── _env_init.bat                             # 环境校验脚本
│   ├── _build_with_progress.ps1                  # 带进度点与用时的编译包装脚本
│   ├── _cleanup_ramdisks.ps1                     # 清理遗留 AIM RAMDisk 脚本
│   ├── _git_failsafe.bat                         # Git 仓库自检与备份恢复脚本
│   ├── arduino-cli/                              # Arduino-CLI 1.4.1 + ESP32 核心包
│   │   ├── arduino-cli.exe
│   │   └── packages/
│   │       ├── builtin/                          # arduino-cli 内置工具
│   │       └── esp32/                            # ESP32 Arduino 核心 v3.3.10-cn
│   ├── VSCode/                                   # VS Code 便携版（启用 data 目录）
│   │   ├── Code.exe
│   │   └── data/                                 # 便携配置、插件、用户数据
│   ├── ImDisk/                                   # RAMDisk 工具目录
│   │   ├── aim_cli/                              # Arsenal Image Mounter 命令行工具（含 x64/x86/arm/arm64 的 aim_ll.exe、aimapi.dll）
│   │   ├── aimapi.dll                            # 供 RamService 加载的 API 库
│   │   ├── RamService.exe                        # Arsenal RAM-disk 服务程序（备用）
│   │   └── RamdiskUI.exe                         # Arsenal RAM-disk GUI 配置工具（备用）
│   └── Drivers/                                  # 串口驱动
│       ├── CH343/CH341SER/                       # CH343/CH340 驱动
│       └── CP210x/                               # CP210x 驱动
├── Projects/                                     # 学生示例工程（被 .gitignore 排除）
│   ├── _template_.vscode/                        # tasks.json 模板
│   ├── Blink/
│   │   ├── Blink.ino
│   │   └── .vscode/tasks.json
│   ├── WiFiScan/
│   │   ├── WiFiScan.ino
│   │   └── .vscode/tasks.json
│   └── MUS4_FW/                                  # MUS4 遥控车辆/机器人固件（独立子项目，含自有 AGENTS.md）
│       ├── MUS4_FW.ino
│       ├── *.h / *.cpp
│       ├── arduino-cli.py
│       ├── arduino-cli-wsl.ps1
│       ├── config.yaml / sketch.yaml / wslbuild.yaml
│       ├── tests/
│       ├── tools/
│       └── AGENTS.md
├── StartDevEnv.bat                               # 开发环境启动入口
├── StopDevEnv.bat                                # 安全退出脚本
└── DevUDisk.code-workspace                       # 多工程 VS Code 工作区
```

> **注意：** `PortableEnv/` 与 `Projects/` 被 `.gitignore` 排除，版本控制仅追踪脚本与文档。实际交付的 U 盘必须包含完整的 `PortableEnv/` 目录。

---

## 2. 技术栈与运行时架构

当前实现采用以下技术栈：

| 层级 | 技术 / 工具 | 版本 / 说明 |
| :--- | :--- | :--- |
| 操作系统 | Windows 原生 | 机房兼容性优先，不使用 WSL |
| 文件系统 | NTFS（4K 簇） | 卷标 `ESP32_DEV`，簇大小 4096 字节 |
| 启动脚本 | Windows Batch (`.bat`) | `StartDevEnv.bat`、`StopDevEnv.bat`、`_env_init.bat`、`_git_failsafe.bat` |
| 编辑器 | VS Code 便携版 | 通过 `VSCode\data` 目录锁定配置 |
| 开发框架 | Arduino-ESP32 | `esp32:esp32@3.3.10-cn`，离线预装 |
| 命令入口 | Arduino-CLI | `1.4.1`（Commit: e39419312） |
| 编译加速 | 本地 SSD 缓存（默认）+ U 盘兜底 + 可选 RAMDisk | 默认 `%TEMP%\DevUDisk_build` 与 `%TEMP%\DevUDisk_ccache`；SSD 空间不足或不可写时 fallback 到 `%U_DISK%\DevUDisk_cache\build` 与 `%U_DISK%\DevUDisk_cache\ccache`；RAMDisk 通过 `PortableEnv\DevUDisk.ini` 显式启用 |
| 串口驱动 | CH343/CH340、CP210x | 位于 `PortableEnv\Drivers\` |

### 2.1 关键目录占用（实测）

| 目录 | 大小 | 说明 |
| :--- | :--- | :--- |
| `PortableEnv\arduino-cli\` | ~6.0 GB | Arduino-CLI + ESP32 核心包与工具链 |
| `PortableEnv\VSCode\` | ~837 MB | VS Code 便携版及运行时数据 |
| `PortableEnv\Drivers\` | ~1.8 MB | CH343/CH340 与 CP210x 驱动 |
| `Projects\` | ~18 KB | 示例工程源码（不含 MUS4_FW 本地库与构建产物） |

### 2.2 核心运行原则

1. **Zero Installation**：不依赖主机安装任何软件；普通用户模式即可编译，管理员权限仅用于创建/卸载 RAMDisk。
2. **Path Isolation**：`StartDevEnv.bat` 将 `PATH` 收缩为 `U:\PortableEnv\arduino-cli;U:\PortableEnv\Git\cmd（如存在）;C:\Windows\System32;C:\Windows\System32\WindowsPowerShell\v1.0`。优先使用 U 盘内置 Git，缺失时回退到本机 Git 固定路径，避免调用本机 Arduino/Python 等其他工具。
3. **Performance First**：源码保留在 U 盘；默认在本地 SSD 构建并保留跨会话缓存，SSD 不可用时 fallback 到 U 盘缓存，RAMDisk 作为可选加速方案，避免 U 盘 I/O 瓶颈。

### 2.3 脚本执行流程

**`StartDevEnv.bat`**：
1. 通过 `%~d0` 计算 U 盘盘符。
2. 读取 `PortableEnv\DevUDisk.ini` 配置，并由环境变量 `DEVUDISK_USE_RAMDISK`、`DEVUDISK_BUILD_PATH`、`DEVUDISK_CCACHE_DIR` 覆盖。
3. 调用 `PortableEnv\_git_failsafe.bat` 备份 Git 关键状态。
4. 调用 `PortableEnv\_env_init.bat` 校验环境。
5. 设置 Arduino 环境变量（`ARDUINO_DIRECTORIES_DATA`、`ARDUINO_DIRECTORIES_USER`、`ARDUINO_DIRECTORIES_DOWNLOADS`）。
6. 检测是否以管理员运行。
7. 若配置显式启用 RAMDisk，则动态选择可用盘符（默认 `R:`，回退 `Z:` `Y:` `Q:` `P:` `O:`），清理遗留 AIM RAMDisk 后创建 RAMDisk（大小 2GB，NTFS）。
8. 若未启用 RAMDisk，检查 `%TEMP%` 所在 SSD 的可用空间与可写性：空间 >= `min_free_gb`（默认 2 GB）且可写时使用 `%TEMP%\DevUDisk_build` 与 `%TEMP%\DevUDisk_ccache`；否则 fallback 到 `%U_DISK%\DevUDisk_cache\build` 与 `%U_DISK%\DevUDisk_cache\ccache`。
9. 确保构建目录与 ccache 目录存在，并将存储策略写入 `%TEMP%\DevUDisk_storage_type.txt`。
10. 配置 Git：优先 U 盘内置 `PortableEnv\Git\cmd\git.exe`，其次回退到常见本机 Git 路径。
11. 构造隔离 `PATH` 并启动 VS Code，打开 `DevUDisk.code-workspace` 多工程工作区。

**`StopDevEnv.bat`**：
1. 调用 `PortableEnv\_git_failsafe.bat` 备份 Git 关键状态。
2. 结束 VS Code 进程。
3. 读取 `%TEMP%\DevUDisk_storage_type.txt` 判断本次存储策略。
4. 若策略为 `ramdisk`：使用 `aim_ll -d -m <盘符>` 卸载 RAMDisk；随后再次调用 `_cleanup_ramdisks.ps1` 清理所有遗留 AIM RAMDisk；否则依次回退到停止 RamService 服务、ImDisk。
5. 若策略为 `ssd` 或 `udisk`：保留持久化构建缓存，仅清理本次会话记录文件。
6. 删除 `%TEMP%\DevUDisk_ramdisk_letter.txt` 与 `%TEMP%\DevUDisk_storage_type.txt`。
7. 调用 PowerShell 弹出 U 盘。

**`PortableEnv\_env_init.bat`**：
1. 校验 U 盘剩余空间 >= 5 GB。
2. 校验 `arduino-cli.exe` 是否存在。
3. 校验 ESP32 Arduino 核心包是否存在。
4. 校验 Git（可选）：若存在 U 盘内置 Git 则提示，否则给出放置指引。
5. 校验 VS Code 便携版是否存在（不存在仅警告）。
6. 打印 Arduino-CLI 版本。

**`PortableEnv\_git_failsafe.bat`**：
1. 检查 `.git` 目录完整性（config、HEAD、index）。
2. 自动备份关键元数据（config, HEAD, index, refs）到 `PortableEnv\git_recovery`。
3. 在检测到损坏或丢失时，自动从最近备份恢复；保留最近 5 个备份。

**`PortableEnv\_cleanup_ramdisks.ps1`**：
1. 扫描所有 Arsenal Image Mounter 设备。
2. 强制分离所有类型为 Virtual Memory / Image in memory 的遗留 RAMDisk。
3. 需要管理员权限（`#Requires -RunAsAdministrator`）。

---

## 3. 代码组织

### 3.1 入口脚本

- **`StartDevEnv.bat`**：计算 U 盘盘符、Git failsafe、调用 `_env_init.bat`、构造隔离 `PATH`、创建 RAMDisk（可选）、设置 Arduino 环境变量、启动 VS Code。
- **`StopDevEnv.bat`**：Git failsafe、结束 VS Code、卸载 RAMDisk（可选）、清理临时构建目录、弹出 U 盘。

### 3.2 环境初始化

- **`PortableEnv\_env_init.bat`**：校验 U 盘剩余空间、Arduino-CLI 可执行性、ESP32 核心包完整性、VS Code 便携版存在性。
- **`PortableEnv\_git_failsafe.bat`**：Git 仓库自检脚本。检查 `.git` 目录完整性，自动备份关键元数据（config, HEAD, index, refs）到 `PortableEnv\git_recovery`。在检测到损坏或丢失时，自动从最近备份恢复。
- **`PortableEnv\_cleanup_ramdisks.ps1`**：清理遗留 AIM RAMDisk，确保启动前无脏盘符占用。

### 3.3 工具目录

- **`PortableEnv\arduino-cli\`**：Arduino-CLI 与 ESP32 核心包。
- **`PortableEnv\VSCode\`**：VS Code 便携版，配置锁定在 `data` 目录。
- **`PortableEnv\Drivers\`**：串口驱动。
- **`PortableEnv\Git\`**（可选）：Portable Git for Windows，解压后 `cmd\git.exe` 可直接使用。
- **`PortableEnv\_build_with_progress.ps1`**：PowerShell 编译包装脚本，为 arduino-cli 提供进度点与总用时显示。
- **`PortableEnv\ImDisk\`**：RAMDisk 工具目录。
  - `aim_cli\x64\aim_ll.exe`：Arsenal Image Mounter 命令行工具，用于直接创建/删除 RAMDisk（推荐）。同时存在 x86、arm、arm64 版本。
  - `RamService.exe` / `RamdiskUI.exe`：Arsenal RAM-disk 服务与 GUI 工具（备用回退）。
  - `aimapi.dll`：已复制到 `ImDisk\` 根目录，供 RamService 加载。

### 3.4 用户空间

- **`Projects\`**：学生工程目录。
  - `Blink/`、`WiFiScan/`：官方示例风格的最小 Arduino 工程。
  - `MUS4_FW/`：独立的 MUS4 遥控车辆/机器人固件子项目，含自己的 `AGENTS.md`、`README.md`、`CLAUDE.md`、`CHANGELOG.md`、构建脚本与 Python 测试。**修改前请优先阅读 `Projects/MUS4_FW/AGENTS.md`。**
- **`Projects\_template_.vscode\tasks.json`**：新增工程时可复制到 `<NewProject>/.vscode/tasks.json` 的模板。
- **`DevUDisk.code-workspace`**：VS Code 多工程工作区，当前包含 `Blink`、`WiFiScan`、`MUS4_FW`。
- **`Doc\`**：面向最终用户的说明文档。
- **`Doc_Dev\`**：面向开发者/代理的设计与规划文档。

### 3.5 版本控制

`.gitignore` 排除了以下内容：
- `/PortableEnv/`：体积巨大的工具链和运行时文件。
- `/Projects/`：用户工程目录。
- `/System Volume Information/`、`/$RECYCLE.BIN/`：Windows 系统目录。
- `Thumbs.db`、`desktop.ini`、`*.tmp`、`*.log`：操作系统生成文件和临时文件。

> 仓库内没有根级 `pyproject.toml`、`package.json`、`Cargo.toml` 或 CI/CD 配置文件。`Projects/MUS4_FW/` 子项目内部存在第三方库自带的 `pyproject.toml` / `package.json`（如 `libraries/FastLED/`、`provisioning_system/playwright_tests/`），但均不属于 DevUDisk 主仓库构建流程。

---

## 4. 构建与测试命令

### 4.1 Arduino 工程构建流程

在 VS Code 内通过任务完成。普通示例工程（Blink / WiFiScan）目录下的 `.vscode\tasks.json` 定义了两个任务：

- **`Arduino: Build (RAMDisk)`**（默认构建任务，`Ctrl + Shift + B`）：
  调用 `PortableEnv\_build_with_progress.ps1` 包装脚本执行 arduino-cli 编译，输出进度点与总用时：
  ```bat
  powershell -NoProfile -ExecutionPolicy Bypass -File %U_DISK%\PortableEnv\_build_with_progress.ps1 -Cli %U_DISK%\PortableEnv\arduino-cli\arduino-cli.exe -Fqbn esp32:esp32:esp32 -Libs "" -BuildPath %ARDUINO_BUILD_BASE%\[ProjectName] -Output-dir [Project]\build -SketchDir [Project] -CcacheDir %CCACHE_DIR%
  ```
- **`Arduino: Upload`**：
  ```bat
  arduino-cli upload --fqbn esp32:esp32:esp32 --port COM3 --input-dir [Project]\build .
  ```
  > 上传前需根据实际串口号修改 `--port` 参数。

`Projects/MUS4_FW/.vscode/tasks.json` 使用不同的 FQBN 与本地库路径：
- FQBN：`esp32:esp32:esp32:PartitionScheme=min_spiffs`
- `-Libs`：`${workspaceFolder}\libraries`

### 4.2 手动命令行构建示例

在已运行 `StartDevEnv.bat` 的 VS Code 终端中，或手动设置以下环境变量后执行：

```bat
set U_DISK=U:
set ARDUINO_DIRECTORIES_DATA=%U_DISK%\PortableEnv\arduino-cli
set ARDUINO_DIRECTORIES_USER=%U_DISK%\Projects
set ARDUINO_DIRECTORIES_DOWNLOADS=%U_DISK%\PortableEnv\arduino-cli\staging
set ARDUINO_BUILD_BASE=%TEMP%\DevUDisk_build
set CCACHE_DIR=%TEMP%\DevUDisk_ccache

arduino-cli compile --fqbn esp32:esp32:esp32 --build-path %ARDUINO_BUILD_BASE%\Blink --output-dir %U_DISK%\Projects\Blink\build %U_DISK%\Projects\Blink
```

### 4.3 串口监视

```bat
arduino-cli monitor -p COM3 -b esp32:esp32:esp32
```

### 4.4 MUS4_FW 子项目构建

MUS4_FW 拥有独立的构建脚本与配置，详见 `Projects/MUS4_FW/AGENTS.md`。简要命令：

```powershell
# WSL 加速编译（推荐）
.\arduino-cli-wsl.ps1 -Compile -Sketch MUS4_FW.ino

# 原生 Python 封装
python arduino-cli.py -c --sketch MUS4_FW.ino
python arduino-cli.py -cu --sketch MUS4_FW.ino
```

### 4.5 已验证项目

| 工程 | 验证结果 |
| :--- | :--- |
| `Projects\Blink` | ✅ 离线编译通过，固件 285084 字节 |
| `Projects\WiFiScan` | ✅ 离线编译通过，固件 888548 字节 |
| `Projects\MUS4_FW` | 由子项目自身 AGENTS.md 维护验证状态 |

---

## 5. 代码风格与开发规范

### 5.1 Batch 脚本

- **编码**：Batch 脚本使用 **UTF-8 without BOM + CRLF 换行**，文件首行之后立即执行 `chcp 65001 >nul` 将控制台切换到 UTF-8，确保中文显示正常且不会被 BOM 破坏首行解析。
- **路径解析**：使用 `%~dp0` / `%~d0` 动态计算脚本所在目录与 U 盘盘符，禁止硬编码盘符。
- **PATH 构造**：采用“收缩式注入”，最小必要集合为：
  ```bat
  set PATH=U:\PortableEnv\arduino-cli;U:\PortableEnv\Git\cmd;C:\Windows\System32;C:\Windows\System32\WindowsPowerShell\v1.0
  ```
  当 U 盘未内置 Git 且检测到本机 Git 时，可临时加入本机 Git 固定路径作为回退，但需在启动日志中明确提示。
- **禁止行为**：不要使用 `where python`、`where git`、`dir /s` 等依赖系统搜索的命令。
- **管理员权限**：仅在创建/卸载 RAMDisk 时请求管理员权限；普通模式默认使用本地 SSD 缓存，SSD 不可用时 fallback 到 U 盘缓存。
- **错误处理**：使用 `if %errorlevel% neq 0` 检查关键步骤返回值，失败时给出明确提示并暂停。
- **RAMDisk 盘符**：禁止硬编码为固定 `R:`。启动脚本会动态选择可用盘符，并将最终盘符写入 `%TEMP%\DevUDisk_ramdisk_letter.txt` 供 `StopDevEnv.bat` 读取。

### 5.2 PowerShell 脚本

- **用途**：`PortableEnv\_build_with_progress.ps1` 作为 arduino-cli 的编译包装脚本，提供进度点与总用时显示；`_cleanup_ramdisks.ps1` 用于清理遗留 AIM RAMDisk。
- **编码**：保存为 **UTF-8 with BOM**，避免中文输出乱码。
- **执行策略**：由 `tasks.json` 调用时通过 `-ExecutionPolicy Bypass` 参数绕过本地执行策略限制。
- **进程管理**：`build_with_progress.ps1` 使用 `System.Diagnostics.Process` 通过 `cmd.exe` 调用 `arduino-cli` 并重定向输出到临时文件，主线程通过 `WaitForExit(2000)` 循环打印进度点，确保退出码可靠获取且输出不与进度点混在一起。
- **清理**：在 `finally` 块中删除临时输出文件并释放进程对象。

### 5.3 VS Code 配置

VS Code 便携配置位于 `PortableEnv\VSCode\data\user-data\User\settings.json`，当前关键配置包括：
- 禁用自动更新和扩展自动检查更新。
- 关闭遥测。
- 终端继承环境变量，默认使用 Command Prompt。
- 构建缓存路径指向 `${env:ARDUINO_BUILD_BASE}/vscode-intellisense`。

修改 VS Code 配置时应保持便携模式，避免依赖本机用户目录。

### 5.4 Arduino 工程

- 每个工程独立目录，目录名与 `.ino` 主文件名一致（如 `Blink\Blink.ino`）。
- 工程内 `.vscode\tasks.json` 使用环境变量 `${env:U_DISK}` 和 `${env:ARDUINO_BUILD_BASE}`，避免硬编码盘符。
- 默认开发板型号为 `esp32:esp32:esp32`（ESP32 DevKit）。
- MUS4_FW 使用 `esp32:esp32:esp32:PartitionScheme=min_spiffs` 并依赖本地 `libraries/` 目录。

### 5.5 文档

- 项目主要使用**中文**编写方案与说明。
- 文档分两类存放：
  - 开发者/代理文档放入 `Doc_Dev/`，命名格式 `DevUDisk_{继承关系}_{含义}_v{版本号}.md`。
  - 用户说明文档放入 `Doc/`，命名格式 `DevUDisk_User_{含义}_v{版本号}.md`。
- `Doc_Dev/` 内采用子目录分组：同一基础文档的派生文档放入 `Doc_Dev\DevUDisk_{基础}_{版本}\`。
- 具体规则参见 `Doc_Dev\DevUDisk_DocumentRules_v1.1.md`，后续必须严格执行。
- 版本号、生效日期、状态字段需与 `Doc_Dev\DevUDisk_Plan_v1.0\DevUDisk_Plan_v1.0.md` 保持一致的风格。

---

## 6. 测试策略

当前 DevUDisk 主仓库无自动化测试，已执行手动验证清单：

| 测试项 | 预期结果 | 状态 |
| :--- | :--- | :--- |
| 盘符自适应 | 脚本通过 `%~d0` 正确识别 U 盘盘符 | ✅ |
| 环境校验 | `_env_init.bat` 通过空间/工具/核心包检查 | ✅ |
| 路径隔离 | 启动后 `PATH` 仅包含 U 盘 arduino-cli 与最小系统路径 | ✅ |
| 离线编译 | Blink / WiFiScan 不依赖本机 Arduino 环境编译成功 | ✅ |
| RAMDisk 回退 | 无可用 aim_ll 时自动使用 `%TEMP%\DevUDisk_build` | ✅ |
| SSD 默认缓存 | 未启用 RAMDisk 时 `ARDUINO_BUILD_BASE` 指向 `%TEMP%\DevUDisk_build` | ⏳ |
| SSD 不足 fallback | SSD 空间 < `min_free_gb` 时自动切换到 `%U_DISK%\DevUDisk_cache\build` | ⏳ |
| 跨会话缓存保留 | 退出后 SSD/U 盘缓存目录不被删除 | ⏳ |
| VS Code 启动 | `StartDevEnv.bat` 成功启动 VS Code 并打开 Projects | ✅ |
| 安全退出 | `StopDevEnv.bat` 关闭 VS Code、清理临时目录 | ✅ |
| U 盘弹出 | 执行后可在资源管理器中安全删除 | ✅（脚本已调用 Eject） |
| RAMDisk 加速 | 安装 Arsenal Image Mounter 驱动后编译速度比 U 盘快 ≥ 30% | ✅ 已实测（与本地 SSD 接近） |
| Git 可用性 | VS Code 终端中 `git --version` 可执行 | ✅ |
| 编译进度反馈 | 编译过程中显示流动进度点，结束后显示总用时 | ✅ |
| RAMDisk 盘符回退 | `R:` 被占用时自动改用 `Z:` / `Y:` / `Q:` / `P:` / `O:` | ✅ |
| 遗留 RAMDisk 清理 | `_cleanup_ramdisks.ps1` 可强制分离残留 AIM RAMDisk | ✅ |
| Git Failsafe | `.git` 损坏时可从 `PortableEnv\git_recovery` 自动恢复 | ✅ |

建议后续补充：
1. Batch 脚本语法检查（可使用 `cmd /c` 或第三方 linter）。
2. 多盘符机器上的启动测试。
3. 已安装 Arduino IDE 的“脏机器”隔离测试。
4. Arsenal Image Mounter 驱动安装后的 aim_ll RAMDisk 速度对比测试。
5. 上传任务串口号自动检测（当前默认 `COM3`，需手动修改）。

> **MUS4_FW 子项目** 拥有自己的 Python 测试套件，使用 `pytest tests/` 运行。详见 `Projects/MUS4_FW/AGENTS.md` 第 3 节。

---

## 7. 部署与交付

### 7.1 母盘制作流程（已执行）

1. 确认 U 盘为 NTFS / 4K 簇 / 卷标 `ESP32_DEV`。
2. 复制 Arduino-CLI 与 ESP32 核心包到 `PortableEnv\arduino-cli\packages\`。
3. 解压 VS Code 便携版到 `PortableEnv\VSCode\`，创建 `data` 目录启用便携模式。
4. 复制 CH343/CH340 与 CP210x 驱动到 `PortableEnv\Drivers\`。
5. （可选）将 Portable Git for Windows 解压到 `PortableEnv\Git\`，确保 `PortableEnv\Git\cmd\git.exe` 存在。
6. 部署 Arsenal Image Mounter 工具到 `PortableEnv\ImDisk\`：
   - `aim_cli\x64\aim_ll.exe` 等架构版本
   - `RamService.exe`、`RamdiskUI.exe`
   - 将 `aimapi.dll` 复制到 `ImDisk\` 根目录
7. 编写并放置 `StartDevEnv.bat`、`StopDevEnv.bat`、`PortableEnv\_env_init.bat`、`PortableEnv\_build_with_progress.ps1`、`PortableEnv\_cleanup_ramdisks.ps1`、`PortableEnv\_git_failsafe.bat`。
8. 创建示例工程 `Projects\Blink`、`Projects\WiFiScan` 与 VS Code 任务；如包含 MUS4_FW，同步放置到 `Projects\MUS4_FW\`。

### 7.2 已知待完善项

- **Arsenal Image Mounter 驱动**：`PortableEnv\ImDisk\` 已包含 `aim_cli\x64\aim_ll.exe`（推荐）、`RamService.exe` 与 `RamdiskUI.exe`（备用）。Arsenal Image Mounter 驱动需要预先在主机上安装，安装方法参见 https://github.com/tmcdos/ramdisk 的 README（通常使用 `aim_ll.exe --install ..\..` 自动安装驱动）。安装驱动后，以管理员模式运行 `StartDevEnv.bat` 即可自动创建 RAMDisk。
- **ESP-IDF 支持**：本机 `C:\Espressif` 可作为二期移植来源。
- **AI 辅助**：Continue 插件尚未预装，需联网下载 `.vsix` 后离线安装。
- **Portable Git**：脚本已支持自动识别 `PortableEnv\Git\cmd\git.exe`；如交付盘尚未内置，可从 https://git-scm.com/download/win 下载 64-bit Portable 版并解压到 `PortableEnv\Git\`。
- **量产镜像**：尚未制作 `ESP32_Dev_v1.0.img`。

### 7.3 量产方案

- 使用 Win32 Disk Imager 制作镜像 `ESP32_Dev_v1.0.img`。
- 使用 Rufus / BalenaEtcher 批量烧录到同型号 U 盘。

---

## 8. 安全与风险控制

| 风险 | 应对措施 |
| :--- | :--- |
| 串口驱动缺失 | U 盘内置 CH343/CH340 与 CP210x 驱动包，首次手动安装 |
| 机房禁用管理员权限 | `StartDevEnv.bat` 普通模式自动回退到本地临时目录，无需管理员 |
| U 盘异常拔出 | 源码始终保存在 U 盘；RAMDisk/临时目录仅用于构建中间文件 |
| 杀毒软件误报 | 提前将 U 盘路径加入机房白名单 |
| 路径泄露 | 脚本中严格使用 `%~dp0` 与隔离 `PATH`，避免调用本机开发工具 |
| Arsenal Image Mounter 驱动未安装 | 提供无 RAMDisk 降级模式，并文档说明使用 `aim_ll.exe --install` 手动安装驱动 |
| 默认串口号不匹配 | 用户上传前需根据设备管理器修改 `tasks.json` 中的 `--port` |
| 遗留 RAMDisk 占用 | `_cleanup_ramdisks.ps1` 在启动/退出时强制清理 |
| Git 元数据损坏 | `_git_failsafe.bat` 自动备份与恢复 |
| MUS4_FW 固件安全 | 该子项目直接控制舵机/电调，修改前必须阅读其 `AGENTS.md` 中的安全章节 |

---

## 9. 给代理的实用提示

- 修改前请先检查 `Doc_Dev\DevUDisk_Plan_v1.0\DevUDisk_Plan_v1.0.md` 与 `Doc_Dev\DevUDisk_Plan_v1.0\DevUDisk_Plan_ActionPlan_v1.0.md`，确保与整体规划一致。
- **如果涉及 `Projects/MUS4_FW/` 的修改，优先阅读并遵循 `Projects/MUS4_FW/AGENTS.md` 与 `Projects/MUS4_FW/CLAUDE.md` 的约定。**
- 当前仓库没有根级 `pyproject.toml`、`package.json`、`Cargo.toml` 或 CI/CD 配置文件。
- 由于项目面向教学场景，脚本与文档应优先保证**可读性**和**可维护性**，避免过度工程化。
- 若需引入新依赖，必须确保其能运行在便携/离线环境中。
- Batch 脚本涉及中文时，保存为 **UTF-8 without BOM + CRLF 换行**，并在 `@echo off` 后立即执行 `chcp 65001 >nul` 切换到 UTF-8 代码页。实测 UTF-8 with BOM 会被 cmd 解析为首行乱码命令。
- PowerShell 脚本涉及中文时，保存为 **UTF-8 with BOM**。
- 修改 `.gitignore`、`AGENTS.md`、文档结构或脚本接口后，应同步更新相关文档。
- 新增 Arduino 示例工程时，可复制 `Projects\_template_.vscode\tasks.json` 到 `<工程名>\.vscode\tasks.json`，并同步更新 `DevUDisk.code-workspace`。
