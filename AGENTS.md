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
├── README.md                                     # 项目双语说明（GitHub 入口）
├── Doc/                                          # 用户说明文档
│   └── DevUDisk_User_QuickStart_v1.0.md          # 5 分钟上手指南
├── Doc_Dev/                                      # 开发者/代理文档
│   ├── DevUDisk_DocumentRules_v1.1.md            # 文档管理规则
│   └── DevUDisk_Plan_v1.0/                       # Plan v1.0 文档族
│       ├── DevUDisk_Plan_v1.0.md                 # 《编程 U 盘设计与制作方案 v1.0》（原版 ESP-IDF 规划）
│       ├── DevUDisk_Plan_ActionPlan_v1.0.md      # 当前开发行动规划
│       └── DevUDisk_Plan_DeliveryNotes_v1.0.md   # 第一阶段交付说明
├── PortableEnv/                                  # 便携工具链（被 .gitignore 排除）
│   ├── _env_init.bat                             # 环境校验脚本
│   ├── arduino-cli/                              # Arduino-CLI 1.4.1 + ESP32 核心包
│   │   ├── arduino-cli.exe
│   │   └── packages/
│   │       ├── builtin/                          # arduino-cli 内置工具
│   │       └── esp32/                            # ESP32 Arduino 核心 v3.3.10-cn
│   ├── VSCode/                                   # VS Code 便携版（启用 data 目录）
│   │   ├── Code.exe
│   │   └── data/                                 # 便携配置、插件、用户数据
│   ├── ImDisk/                                   # ImDisk 占位目录（当前仅有下载失败的 HTML 文件）
│   └── Drivers/                                  # 串口驱动
│       ├── CH343/CH341SER/                       # CH343/CH340 驱动
│       └── CP210x/                               # CP210x 驱动
├── Projects/                                     # 学生示例工程（被 .gitignore 排除）
│   ├── Blink/
│   │   ├── Blink.ino
│   │   └── .vscode/tasks.json
│   └── WiFiScan/
│       ├── WiFiScan.ino
│       └── .vscode/tasks.json
├── StartDevEnv.bat                               # 开发环境启动入口
└── StopDevEnv.bat                                # 安全退出脚本
```

> **注意：** `PortableEnv/` 与 `Projects/` 被 `.gitignore` 排除，版本控制仅追踪脚本与文档。实际交付的 U 盘必须包含完整的 `PortableEnv/` 目录。

---

## 2. 技术栈与运行时架构

当前实现采用以下技术栈：

| 层级 | 技术 / 工具 | 版本 / 说明 |
| :--- | :--- | :--- |
| 操作系统 | Windows 原生 | 机房兼容性优先，不使用 WSL |
| 文件系统 | NTFS（4K 簇） | 卷标 `ESP32_DEV`，簇大小 4096 字节 |
| 启动脚本 | Windows Batch (`.bat`) | `StartDevEnv.bat`、`StopDevEnv.bat`、`_env_init.bat` |
| 编辑器 | VS Code 便携版 | 通过 `VSCode\data` 目录锁定配置 |
| 开发框架 | Arduino-ESP32 | `esp32:esp32@3.3.10-cn`，离线预装 |
| 命令入口 | Arduino-CLI | `1.4.1`（Commit: e39419312） |
| 编译加速 | RAMDisk（ImDisk，可选） | 优先 `R:\arduino_build\[ProjectName]`；无 ImDisk 时回退到 `%TEMP%\DevUDisk_build` |
| 串口驱动 | CH343/CH340、CP210x | 位于 `PortableEnv\Drivers\` |

### 2.1 关键目录占用（实测）

| 目录 | 大小 | 说明 |
| :--- | :--- | :--- |
| `PortableEnv\arduino-cli\` | ~6.0 GB | Arduino-CLI + ESP32 核心包与工具链 |
| `PortableEnv\VSCode\` | ~837 MB | VS Code 便携版及运行时数据 |
| `PortableEnv\Drivers\` | ~1.8 MB | CH343/CH340 与 CP210x 驱动 |
| `Projects\` | ~18 KB | 示例工程源码 |

### 2.2 核心运行原则

1. **Zero Installation**：不依赖主机安装任何软件；普通用户模式即可编译，管理员权限仅用于创建/卸载 RAMDisk。
2. **Path Isolation**：`StartDevEnv.bat` 将 `PATH` 收缩为 `U:\PortableEnv\arduino-cli;C:\Windows\System32;C:\Windows\System32\WindowsPowerShell\v1.0`，避免调用本机 Arduino/Python/Git。
3. **Performance First**：源码保留在 U 盘；优先在 RAMDisk 构建，其次回退到本地临时目录，避免 U 盘 I/O 瓶颈。

### 2.3 脚本执行流程

**`StartDevEnv.bat`**：
1. 通过 `%~d0` 计算 U 盘盘符。
2. 调用 `PortableEnv\_env_init.bat` 校验环境。
3. 设置 Arduino 环境变量（`ARDUINO_DIRECTORIES_DATA`、`ARDUINO_DIRECTORIES_USER`、`ARDUINO_DIRECTORIES_DOWNLOADS`）。
4. 检测是否以管理员运行；若存在 `PortableEnv\ImDisk\imdisk.exe` 且为管理员，则创建 `R:` RAMDisk。
5. 无 RAMDisk 时回退到 `%TEMP%\DevUDisk_build`。
6. 构造隔离 `PATH` 并启动 VS Code，打开 `Projects` 目录。

**`StopDevEnv.bat`**：
1. 结束 VS Code 进程。
2. 若存在 ImDisk 且为管理员，卸载 `R:` RAMDisk。
3. 清理 `%TEMP%\DevUDisk_build`。
4. 调用 PowerShell 弹出 U 盘。

**`PortableEnv\_env_init.bat`**：
1. 校验 U 盘剩余空间 >= 5 GB。
2. 校验 `arduino-cli.exe` 是否存在。
3. 校验 ESP32 Arduino 核心包是否存在。
4. 校验 VS Code 便携版是否存在（不存在仅警告）。
5. 打印 Arduino-CLI 版本。

---

## 3. 代码组织

### 3.1 入口脚本

- **`StartDevEnv.bat`**：计算 U 盘盘符、调用 `_env_init.bat`、构造隔离 `PATH`、创建 RAMDisk（可选）、设置 Arduino 环境变量、启动 VS Code。
- **`StopDevEnv.bat`**：结束 VS Code、卸载 RAMDisk（可选）、清理临时构建目录、弹出 U 盘。

### 3.2 环境初始化

- **`PortableEnv\_env_init.bat`**：校验 U 盘剩余空间、Arduino-CLI 可执行性、ESP32 核心包完整性、VS Code 便携版存在性。

### 3.3 工具目录

- **`PortableEnv\arduino-cli\`**：Arduino-CLI 与 ESP32 核心包。
- **`PortableEnv\VSCode\`**：VS Code 便携版，配置锁定在 `data` 目录。
- **`PortableEnv\Drivers\`**：串口驱动。
- **`PortableEnv\ImDisk\`**：ImDisk 占位目录（当前缺少可用的 `imdisk.exe`，仅有下载失败的 HTML 文件）。

### 3.4 用户空间

- **`Projects\`**：学生工程目录。
- **`Doc\`**：面向最终用户的说明文档。
- **`Doc_Dev\`**：面向开发者/代理的设计与规划文档。

### 3.5 版本控制

`.gitignore` 排除了以下内容：
- `/PortableEnv/`：体积巨大的工具链和运行时文件。
- `/Projects/`：用户工程目录。
- `/System Volume Information/`、`/$RECYCLE.BIN/`：Windows 系统目录。
- `Thumbs.db`、`desktop.ini`、`*.tmp`、`*.log`：操作系统生成文件和临时文件。

> 仓库内没有 `pyproject.toml`、`package.json`、`Cargo.toml` 或 CI/CD 配置文件。

---

## 4. 构建与测试命令

### 4.1 Arduino 工程构建流程

在 VS Code 内通过任务完成。每个工程目录下的 `.vscode\tasks.json` 定义了两个任务：

- **`Arduino: Build (RAMDisk)`**（默认构建任务，`Ctrl + Shift + B`）：
  ```bat
  arduino-cli compile --fqbn esp32:esp32:esp32 --build-path %ARDUINO_BUILD_BASE%\[ProjectName] --output-dir [Project]\build .
  ```
- **`Arduino: Upload`**：
  ```bat
  arduino-cli upload --fqbn esp32:esp32:esp32 --port COM3 --input-dir [Project]\build .
  ```
  > 上传前需根据实际串口号修改 `--port` 参数。

### 4.2 手动命令行构建示例

在已运行 `StartDevEnv.bat` 的 VS Code 终端中，或手动设置以下环境变量后执行：

```bat
set U_DISK=U:
set ARDUINO_DIRECTORIES_DATA=%U_DISK%\PortableEnv\arduino-cli
set ARDUINO_DIRECTORIES_USER=%U_DISK%\Projects
set ARDUINO_DIRECTORIES_DOWNLOADS=%U_DISK%\PortableEnv\arduino-cli\staging
set ARDUINO_BUILD_BASE=%TEMP%\DevUDisk_build

arduino-cli compile --fqbn esp32:esp32:esp32 --build-path %ARDUINO_BUILD_BASE%\Blink --output-dir %U_DISK%\Projects\Blink\build %U_DISK%\Projects\Blink
```

### 4.3 串口监视

```bat
arduino-cli monitor -p COM3 -b esp32:esp32:esp32
```

### 4.4 已验证项目

| 工程 | 验证结果 |
| :--- | :--- |
| `Projects\Blink` | ✅ 离线编译通过，固件 285084 字节 |
| `Projects\WiFiScan` | ✅ 离线编译通过，固件 888548 字节 |

---

## 5. 代码风格与开发规范

### 5.1 Batch 脚本

- **编码**：Batch 脚本使用 **UTF-8 with BOM**，确保中文显示正常。
- **路径解析**：使用 `%~dp0` / `%~d0` 动态计算脚本所在目录与 U 盘盘符，禁止硬编码盘符。
- **PATH 构造**：采用“收缩式注入”，最小必要集合为：
  ```bat
  set PATH=U:\PortableEnv\arduino-cli;C:\Windows\System32;C:\Windows\System32\WindowsPowerShell\v1.0
  ```
- **禁止行为**：不要使用 `where python`、`where git`、`dir /s` 等依赖系统搜索的命令。
- **管理员权限**：仅在创建/卸载 RAMDisk 时请求管理员权限；普通模式自动回退到本地临时构建目录。
- **错误处理**：使用 `if %errorlevel% neq 0` 检查关键步骤返回值，失败时给出明确提示并暂停。

### 5.2 VS Code 配置

VS Code 便携配置位于 `PortableEnv\VSCode\data\user-data\User\settings.json`，当前关键配置包括：
- 禁用自动更新和扩展自动检查更新。
- 关闭遥测。
- 终端继承环境变量，默认使用 Command Prompt。
- 构建缓存路径指向 `${env:ARDUINO_BUILD_BASE}/vscode-intellisense`。

修改 VS Code 配置时应保持便携模式，避免依赖本机用户目录。

### 5.3 Arduino 工程

- 每个工程独立目录，目录名与 `.ino` 主文件名一致（如 `Blink\Blink.ino`）。
- 工程内 `.vscode\tasks.json` 使用环境变量 `${env:U_DISK}` 和 `${env:ARDUINO_BUILD_BASE}`，避免硬编码盘符。
- 默认开发板型号为 `esp32:esp32:esp32`（ESP32 DevKit）。

### 5.4 文档

- 项目主要使用**中文**编写方案与说明。
- 文档分两类存放：
  - 开发者/代理文档放入 `Doc_Dev/`，命名格式 `DevUDisk_{继承关系}_{含义}_v{版本号}.md`。
  - 用户说明文档放入 `Doc/`，命名格式 `DevUDisk_User_{含义}_v{版本号}.md`。
- `Doc_Dev/` 内采用子目录分组：同一基础文档的派生文档放入 `Doc_Dev\DevUDisk_{基础}_{版本}\`。
- 具体规则参见 `Doc_Dev\DevUDisk_DocumentRules_v1.1.md`，后续必须严格执行。
- 版本号、生效日期、状态字段需与 `Doc_Dev\DevUDisk_Plan_v1.0\DevUDisk_Plan_v1.0.md` 保持一致的风格。

---

## 6. 测试策略

当前无自动化测试，已执行手动验证清单：

| 测试项 | 预期结果 | 状态 |
| :--- | :--- | :--- |
| 盘符自适应 | 脚本通过 `%~d0` 正确识别 U 盘盘符 | ✅ |
| 环境校验 | `_env_init.bat` 通过空间/工具/核心包检查 | ✅ |
| 路径隔离 | 启动后 `PATH` 仅包含 U 盘 arduino-cli 与最小系统路径 | ✅ |
| 离线编译 | Blink / WiFiScan 不依赖本机 Arduino 环境编译成功 | ✅ |
| RAMDisk 回退 | 无可用 ImDisk 时自动使用 `%TEMP%\DevUDisk_build` | ✅ |
| VS Code 启动 | `StartDevEnv.bat` 成功启动 VS Code 并打开 Projects | ✅ |
| 安全退出 | `StopDevEnv.bat` 关闭 VS Code、清理临时目录 | ✅ |
| U 盘弹出 | 执行后可在资源管理器中安全删除 | ✅（脚本已调用 Eject） |
| RAMDisk 加速 | 安装 ImDisk 后编译速度比 U 盘快 ≥ 30% | ⏳ 待补充 ImDisk 后实测 |

建议后续补充：
1. Batch 脚本语法检查（可使用 `cmd /c` 或第三方 linter）。
2. 多盘符机器上的启动测试。
3. 已安装 Arduino IDE 的“脏机器”隔离测试。
4. ImDisk 安装后的 RAMDisk 速度对比测试。
5. 上传任务串口号自动检测（当前默认 `COM3`，需手动修改）。

---

## 7. 部署与交付

### 7.1 母盘制作流程（已执行）

1. 确认 U 盘为 NTFS / 4K 簇 / 卷标 `ESP32_DEV`。
2. 复制 Arduino-CLI 与 ESP32 核心包到 `PortableEnv\arduino-cli\packages\`。
3. 解压 VS Code 便携版到 `PortableEnv\VSCode\`，创建 `data` 目录启用便携模式。
4. 复制 CH343/CH340 与 CP210x 驱动到 `PortableEnv\Drivers\`。
5. 编写并放置 `StartDevEnv.bat`、`StopDevEnv.bat`、`PortableEnv\_env_init.bat`。
6. 创建示例工程 `Projects\Blink`、`Projects\WiFiScan` 与 VS Code 任务。

### 7.2 已知待完善项

- **ImDisk 驱动**：`PortableEnv\ImDisk\` 当前仅有下载失败的 HTML 文件，缺少可用的 `imdisk.exe`。如需 RAMDisk，需手动从 https://www.ltr-data.se/opencode.html 下载 ImDisk Toolkit 并安装驱动，然后以管理员模式运行 `StartDevEnv.bat`。
- **ESP-IDF 支持**：本机 `C:\Espressif` 可作为二期移植来源。
- **AI 辅助**：Continue 插件尚未预装，需联网下载 `.vsix` 后离线安装。
- **Portable Git**：如需对学生工程进行版本控制，可补充便携 Git。
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
| ImDisk 驱动未安装 | 提供无 RAMDisk 降级模式，并文档说明手动安装方式 |
| 默认串口号不匹配 | 用户上传前需根据设备管理器修改 `tasks.json` 中的 `--port` |

---

## 9. 给代理的实用提示

- 修改前请先检查 `Doc_Dev\DevUDisk_Plan_v1.0\DevUDisk_Plan_v1.0.md` 与 `Doc_Dev\DevUDisk_Plan_v1.0\DevUDisk_Plan_ActionPlan_v1.0.md`，确保与整体规划一致。
- 当前仓库没有 `pyproject.toml`、`package.json`、`Cargo.toml` 或 CI/CD 配置文件。
- 由于项目面向教学场景，脚本与文档应优先保证**可读性**和**可维护性**，避免过度工程化。
- 若需引入新依赖，必须确保其能运行在便携/离线环境中。
- Batch 脚本涉及中文时，务必保存为 **UTF-8 with BOM**。
- 修改 `.gitignore`、`AGENTS.md`、文档结构或脚本接口后，应同步更新相关文档。
