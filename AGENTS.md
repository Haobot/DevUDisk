# DevUDisk 项目代理指南

> 本文档面向需要在该仓库中工作的 AI 编码代理。阅读前假设你对项目一无所知。

---

## 1. 项目概述

**DevUDisk** 是一个面向 ESP32 教学、竞赛与现场开发的“编程 U 盘”设计与制作方案仓库。

- **仓库地址：** `https://github.com/Haobot/DevUDisk.git`
- **当前分支：** `main`
- **当前状态：** 已根据《编程 U 盘设计与制作方案 v1.0》完成第一阶段实现：U 盘内包含可独立运行的 Arduino-ESP32 开发环境、VS Code 便携版、示例工程与启动/退出脚本。ESP-IDF 与 AI 插件列为二期可选项。
- **核心目标：** 实现“插上即用、环境隔离、极速编译、AI 辅助、批量交付”的便携式 ESP32 开发环境。

### 1.1 已存在的文件

```text
D:/
├── .git/                                         # Git 仓库
├── Doc/                                          # 用户说明文档
│   └── DevUDisk_User_QuickStart_v1.0.md          # 5 分钟上手指南
├── Docs_Dev/                                     # 开发者/代理文档
│   ├── DevUDisk_DocumentRules_v1.0.md            # 文档管理规则
│   ├── DevUDisk_Plan_v1.0.md                     # 《编程 U 盘设计与制作方案 v1.0》（原版 ESP-IDF 规划）
│   ├── DevUDisk_Plan_ActionPlan_v1.0.md          # 当前开发行动规划
│   └── DevUDisk_Plan_DeliveryNotes_v1.0.md       # 第一阶段交付说明
├── PortableEnv/                                  # 便携工具链（被 .gitignore 排除）
│   ├── _env_init.bat             # 环境校验脚本
│   ├── arduino-cli/              # Arduino-CLI + ESP32 核心包
│   ├── VSCode/                   # VS Code 便携版
│   ├── ImDisk/                   # RAMDisk 工具占位（ImDisk 需另行安装）
│   └── Drivers/                  # CH343 / CP210x 驱动
├── Projects/                     # 学生示例工程（被 .gitignore 排除）
│   ├── Blink/
│   └── WiFiScan/
├── StartDevEnv.bat               # 开发环境启动入口
├── StopDevEnv.bat                # 安全退出脚本
└── AGENTS.md                     # 本文件
```

> **注意：** `PortableEnv/` 与 `Projects/` 被 `.gitignore` 排除，版本控制仅追踪脚本与文档。

---

## 2. 技术栈与运行时架构

当前实现采用以下技术栈：

| 层级 | 技术 / 工具 | 说明 |
| :--- | :--- | :--- |
| 操作系统 | Windows 原生 | 机房兼容性优先，不使用 WSL |
| 文件系统 | NTFS（4K 簇） | 已格式化为卷标 `ESP32_DEV`，簇大小 4096 字节 |
| 启动脚本 | Windows Batch (`.bat`) | `StartDevEnv.bat`、`StopDevEnv.bat`、`_env_init.bat` |
| 编辑器 | VS Code 便携版 | 配置锁定在 `VSCode\data` 目录 |
| 开发框架 | Arduino-ESP32 v3.3.10-cn | 离线预装，路径 `PortableEnv\arduino-cli\packages\esp32` |
| 命令入口 | Arduino-CLI 1.4.1 | 不依赖 Arduino IDE 安装 |
| 编译加速 | RAMDisk（ImDisk，可选） | 构建目录优先映射到 `R:\arduino_build\[ProjectName]`；无 ImDisk 时回退到 `%TEMP%\DevUDisk_build` |
| 驱动 | CH343 / CP210x | ESP32 串口驱动包 |

### 2.1 当前目录结构

```text
ESP32_DEV (U:\)
├── StartDevEnv.bat
├── StopDevEnv.bat
├── PortableEnv\
│   ├── _env_init.bat
│   ├── arduino-cli\
│   │   ├── arduino-cli.exe
│   │   └── packages\
│   │       ├── builtin\         # arduino-cli 内置工具（discovery、monitor 等）
│   │       └── esp32\           # ESP32 Arduino 核心与工具链
│   ├── VSCode\
│   │   ├── Code.exe
│   │   └── data\                # 便携配置、插件、用户数据
│   ├── ImDisk\
│   │   └── （ImDisk 驱动需另行安装）
│   └── Drivers\
│       ├── CH343\
│       └── CP210x\
├── Projects\
│   ├── Blink\
│   │   ├── Blink.ino
│   │   └── .vscode\tasks.json
│   └── WiFiScan\
│       ├── WiFiScan.ino
│       └── .vscode\tasks.json
├── Doc\
│   └── DevUDisk_User_QuickStart_v1.0.md
└── Docs_Dev\
    ├── DevUDisk_DocumentRules_v1.0.md
    ├── DevUDisk_Plan_v1.0.md
    ├── DevUDisk_Plan_ActionPlan_v1.0.md
    └── DevUDisk_Plan_DeliveryNotes_v1.0.md
```

### 2.2 核心运行原则

1. **Zero Installation**：不依赖主机安装任何软件；普通用户模式即可编译，管理员权限仅用于 RAMDisk。
2. **Path Isolation**：`StartDevEnv.bat` 将 `PATH` 收缩为 `U:\PortableEnv\arduino-cli;C:\Windows\System32;C:\Windows\System32\WindowsPowerShell\v1.0`，避免调用本机 Arduino/Python/Git。
3. **Performance First**：源码保留在 U 盘；优先在 RAMDisk 构建，其次回退到本地临时目录，避免 U 盘 I/O 瓶颈。

---

## 3. 代码组织

- **入口脚本**
  - `StartDevEnv.bat`：计算 U 盘盘符、调用 `_env_init.bat`、构造隔离 `PATH`、创建 RAMDisk（可选）、设置 Arduino 环境变量、启动 VS Code。
  - `StopDevEnv.bat`：结束 VS Code、卸载 RAMDisk（可选）、清理临时构建目录、弹出 U 盘。
- **环境初始化**
  - `PortableEnv\_env_init.bat`：校验 U 盘剩余空间、Arduino-CLI 可执行性、ESP32 核心包完整性。
- **工具目录**
  - `PortableEnv\arduino-cli\`：Arduino-CLI 与 ESP32 核心包。
  - `PortableEnv\VSCode\`：VS Code 便携版。
  - `PortableEnv\Drivers\`：串口驱动。
- **用户空间**
  - `Projects\`：学生工程目录。
  - `Doc\`：面向最终用户的说明文档。
  - `Docs_Dev\`：面向开发者/代理的设计与规划文档。

---

## 4. 构建与测试命令

### 4.1 当前仓库

由于 `PortableEnv/` 与 `Projects/` 被 `.gitignore` 排除，**版本控制内没有可执行代码**。实际 U 盘应包含完整的 `PortableEnv/` 目录。

### 4.2 Arduino 工程构建流程

在 VS Code 内通过任务完成：

```bat
set ARDUINO_DIRECTORIES_DATA=U:\PortableEnv\arduino-cli
set ARDUINO_DIRECTORIES_USER=U:\Projects
set ARDUINO_DIRECTORIES_DOWNLOADS=U:\PortableEnv\arduino-cli\staging
set ARDUINO_BUILD_BASE=%TEMP%\DevUDisk_build
arduino-cli compile --fqbn esp32:esp32:esp32 --build-path %ARDUINO_BUILD_BASE%\Blink --output-dir U:\Projects\Blink\build U:\Projects\Blink
```

> 注意：`StartDevEnv.bat` 已自动设置上述环境变量；VS Code 任务直接调用 `arduino-cli`。

### 4.3 已验证项目

| 工程 | 验证结果 |
| :--- | :--- |
| `Projects/Blink` | ✅ 离线编译通过，固件 285084 字节 |
| `Projects/WiFiScan` | ✅ 离线编译通过，固件 888548 字节 |

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

### 5.2 文档

- 项目主要使用**中文**编写方案与说明。
- 文档分两类存放：
  - 开发者/代理文档放入 `Docs_Dev/`，命名格式 `DevUDisk_{继承关系}_{含义}_v{版本号}.md`。
  - 用户说明文档放入 `Doc/`，命名格式 `DevUDisk_User_{含义}_v{版本号}.md`。
- 具体规则参见 `Docs_Dev/DevUDisk_DocumentRules_v1.0.md`，后续必须严格执行。
- 版本号、生效日期、状态字段需与 `DevUDisk_Plan_v1.0.md` 保持一致的风格。

---

## 6. 测试策略

当前无自动化测试，已执行手动验证清单：

| 测试项 | 预期结果 | 状态 |
| :--- | :--- | :--- |
| 盘符自适应 | 脚本通过 `%~d0` 正确识别 D: 盘 | ✅ |
| 环境校验 | `_env_init.bat` 通过空间/工具/核心包检查 | ✅ |
| 路径隔离 | 启动后 `PATH` 仅包含 U 盘 arduino-cli 与最小系统路径 | ✅ |
| 离线编译 | Blink / WiFiScan 不依赖本机 Arduino 环境编译成功 | ✅ |
| RAMDisk | 未安装 ImDisk 时自动回退到 `%TEMP%\DevUDisk_build` | ✅ |
| 安全退出 | `StopDevEnv.bat` 关闭 VS Code、清理临时目录、弹出 U 盘 | ✅（待实测弹出） |

建议后续补充：

1. Batch 脚本语法检查。
2. 多盘符机器上的启动测试。
3. 已安装 Arduino IDE 的“脏机器”隔离测试。
4. ImDisk 安装后的 RAMDisk 速度对比测试。

---

## 7. 部署与交付

### 7.1 母盘制作流程（已执行）

1. 确认 U 盘为 NTFS / 4K 簇 / 卷标 `ESP32_DEV`。
2. 复制 Arduino-CLI 与 ESP32 核心包到 `PortableEnv\arduino-cli\packages\`。
3. 解压 VS Code 便携版到 `PortableEnv\VSCode\`，创建 `data` 目录启用便携模式。
4. 复制 CH343 / CP210x 驱动到 `PortableEnv\Drivers\`。
5. 编写并放置 `StartDevEnv.bat`、`StopDevEnv.bat`、`PortableEnv\_env_init.bat`。
6. 创建示例工程 `Projects\Blink`、`Projects\WiFiScan` 与 VS Code 任务。

### 7.2 已知待完善项

- **ImDisk 驱动**：因 SourceForge/ltr-data.se 下载受 Cloudflare 保护，当前 U 盘未内置 ImDisk 二进制。如需 RAMDisk，需手动下载安装驱动后使用管理员模式运行 `StartDevEnv.bat`。
- **ESP-IDF 支持**：本机 `C:\Espressif` 可作为二期移植来源。
- **AI 辅助**：Continue 插件尚未预装，需联网下载 `.vsix` 后离线安装。
- **量产镜像**：尚未制作 `ESP32_Dev_v1.0.img`。

### 7.3 量产方案

- 使用 Win32 Disk Imager 制作镜像 `ESP32_Dev_v1.0.img`。
- 使用 Rufus / BalenaEtcher 批量烧录到同型号 U 盘。

---

## 8. 安全与风险控制

| 风险 | 应对措施 |
| :--- | :--- |
| 串口驱动缺失 | U 盘内置 CH343/CP210x 驱动包，首次手动安装 |
| 机房禁用管理员权限 | `StartDevEnv.bat` 普通模式自动回退到本地临时目录，无需管理员 |
| U 盘异常拔出 | 源码始终保存在 U 盘；RAMDisk/临时目录仅用于构建中间文件 |
| 杀毒软件误报 | 提前将 U 盘路径加入机房白名单 |
| 路径泄露 | 脚本中严格使用 `%~dp0` 与隔离 `PATH`，避免调用本机开发工具 |
| ImDisk 驱动未安装 | 提供无 RAMDisk 降级模式，并文档说明手动安装方式 |

---

## 9. 给代理的实用提示

- 修改前请先检查 `Docs_Dev/DevUDisk_Plan_v1.0.md` 与 `Docs_Dev/DevUDisk_Plan_ActionPlan_v1.0.md`。
- 当前仓库没有 `pyproject.toml`、`package.json`、`Cargo.toml` 或 CI/CD 配置文件。
- 由于项目面向教学场景，脚本与文档应优先保证**可读性**和**可维护性**，避免过度工程化。
- 若需引入新依赖，必须确保其能运行在便携/离线环境中。
- Batch 脚本涉及中文时，务必保存为 **UTF-8 with BOM**。
