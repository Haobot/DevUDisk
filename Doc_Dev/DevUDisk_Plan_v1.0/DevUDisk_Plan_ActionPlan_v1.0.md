# DevUDisk 开发行动规划 v1.0

> 基于《编程U盘设计与制作方案 v1.0》制定，面向当前可用资源进行调整。  
> 制定日期：2026-06-15  
> 状态：✅ 第一阶段已完成（Arduino-ESP32 便携环境可运行）

---

## 0. 关键决策说明

由于当前系统处于自动权限模式，无法弹窗提问。以下是我基于现场勘察做出的关键决策，已在执行中落地。如果你希望调整，请直接回复纠正。

| 决策点 | 当前决策 | 理由 |
| :--- | :--- | :--- |
| **核心开发栈** | **Arduino-ESP32**（而非原方案的 ESP-IDF） | 本机 C 盘已有可运行的 `arduino-cli` + `esp32:esp32` 核心包，可直接移植；ESP-IDF 虽也存在，但体积更大且与原方案重复，故列为二期可选项。 |
| **编辑器** | **VS Code 便携版 + 内置 Tasks** | C 盘 Arduino IDE 2.x 为安装版，配置分散在用户目录，不适合便携。VS Code 便携版通过 `data` 目录锁定配置，使用 `tasks.json` 直接调用 `arduino-cli`，避免依赖可能失效的 Arduino 插件。 |
| **RAMDisk 工具** | **ImDisk Toolkit（可选）** | 与原方案一致。但因 SourceForge/ltr-data.se 下载受 Cloudflare 保护，当前 U 盘未内置 ImDisk 二进制；脚本已实现无 ImDisk 时自动回退到 `%TEMP%\DevUDisk_build`。 |
| **路径隔离** | `PATH` 收缩为 `U:\PortableEnv\arduino-cli;C:\Windows\System32;C:\Windows\System32\WindowsPowerShell\v1.0` | 保证 `arduino-cli` 编译所需的 `cmd.exe` 与 `powershell.exe` 可用，同时避免调用本机 Arduino/Python/Git。 |
| **构建目录** | 优先 `R:\arduino_build\[ProjectName]`，回退 `%TEMP%\DevUDisk_build\[ProjectName]` | 与原方案 `R:\esp_build` 对应，改为 Arduino 构建目录。 |
| **U 盘卷标** | 已确认为 `ESP32_DEV`，簇大小 4K | 与原方案要求一致，无需重新格式化。 |

### 0.1 执行结果摘要

| 阶段 | 状态 | 备注 |
| :--- | :--- | :--- |
| 目录结构搭建 | ✅ 完成 | `PortableEnv/`、`Projects/`、`Doc/`、`Doc_Dev/` 已创建 |
| Arduino-CLI + ESP32 核心移植 | ✅ 完成 | 约 5.9 GB，已验证离线编译 |
| VS Code 便携版部署 | ✅ 完成 | 已启用 `data` 便携模式 |
| 启动/退出脚本 | ✅ 完成 | 普通模式免管理员，RAMDisk 可选 |
| 示例工程 | ✅ 完成 | `Blink`、`WiFiScan` 均可编译 |
| 串口驱动 | ✅ 完成 | CH343 / CP210x 驱动已复制 |
| ImDisk 二进制 | ⚠️ 未完成 | 下载受 Cloudflare 保护，需手动补充 |
| 量产镜像 | ⏳ 未开始 | 待补充 ImDisk / 二期功能后制作 |

### 0.2 可用资源清单

| 资源 | 本机路径 | 大小 | 用途 |
| :--- | :--- | :--- | :--- |
| Arduino-CLI | `C:\Softwares\arduino-cli` | ~37 MB | 命令行编译/上传入口 |
| ESP32 Arduino 核心 | `C:\Users\cross\AppData\Local\Arduino15\packages\esp32` | ~5.9 GB | `esp32:esp32@3.3.10-cn` 完整核心与工具链 |
| Arduino IDE 2.x | `C:\Program Files\Arduino IDE` | ~545 MB | **不移植**，为安装版且 Electron 依赖重 |
| ESP-IDF v5.5.1 | `C:\Espressif` | ~7.8 GB | **二期可选**，当前不移植 |
| Python 3.12 | `C:\Users\cross\AppData\Local\Programs\Python\Python312` | - | 本机环境，U 盘内 Arduino 编译不直接依赖 |
| Git | `C:\mingw64\bin\git.exe`（Git Bash） | - | 本机环境，U 盘内如需 Git 可额外下载便携版 |

### 0.3 需要下载/补充的资源

| 资源 | 来源 | 用途 | 状态 |
| :--- | :--- | :--- | :--- |
| VS Code 便携版（zip） | https://code.visualstudio.com/docs/?dv=winzip | 编辑器 | ✅ 已下载部署 |
| ImDisk Toolkit | https://www.ltr-data.se/opencode.html | RAMDisk | ⚠️ 受 Cloudflare 保护，需手动下载 |
| CH343 / CP210x 驱动 | 本机 `C:\Espressif\tools\idf-driver\` | 串口通信 | ✅ 已复制 |

---

## 1. 目标目录结构（U 盘根目录）

```text
ESP32_DEV (D:\)
├── StartDevEnv.bat              # ★ 唯一入口：注入 PATH、启动 VS Code、可选 RAMDisk
├── StopDevEnv.bat               # 安全退出：结束 VS Code、卸载 RAMDisk、弹出 U 盘
├── PortableEnv\
│   ├── _env_init.bat            # 环境校验（U 盘空间、工具可执行性）
│   ├── arduino-cli\
│   │   ├── arduino-cli.exe
│   │   └── packages\            # ESP32 核心包离线副本 + builtin 工具
│   │       ├── builtin\
│   │       └── esp32\
│   ├── VSCode\
│   │   ├── Code.exe
│   │   ├── data\                # 便携配置、插件、用户数据
│   │   └── 6928394f91\          # VS Code 运行时资源（下载 zip 自带）
│   ├── ImDisk\
│   │   └── （ImDisk 驱动需手动补充）
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
└── Doc_Dev\
    ├── DevUDisk_DocumentRules_v1.1.md
    └── DevUDisk_Plan_v1.0\
        ├── DevUDisk_Plan_v1.0.md
        ├── DevUDisk_Plan_ActionPlan_v1.0.md
        └── DevUDisk_Plan_DeliveryNotes_v1.0.md
```

---

## 2. 分阶段行动计划

### Phase 1：基础环境移植 ✅

1. **搭建目录结构**：按上述结构创建空目录。✅
2. **移植 Arduino-CLI**：将 `C:\Softwares\arduino-cli` 复制到 `D:\PortableEnv\arduino-cli`。✅
3. **移植 ESP32 核心包**：将 `C:\Users\cross\AppData\Local\Arduino15\packages\esp32` 复制到 `D:\PortableEnv\arduino-cli\packages\esp32`。✅
4. **环境变量隔离**：通过 `StartDevEnv.bat` 设置 `ARDUINO_DIRECTORIES_DATA` 等环境变量，确保不读取本机 `Arduino15`。✅
5. **离线验证**：在隔离 PATH 下执行 `arduino-cli compile`，确认 Blink / WiFiScan 均可编译。✅

### Phase 2：编辑器集成 ✅

1. 下载 VS Code 便携版 zip 并解压到 `D:\PortableEnv\VSCode`。✅
2. 创建 `D:\PortableEnv\VSCode\data` 目录，启用便携模式。✅
3. 配置 `data\user-data\User\settings.json`（禁用自动更新、继承环境变量等）。✅
4. 为示例工程创建 `.vscode\tasks.json`，直接调用 `arduino-cli`。✅

### Phase 3：RAMDisk 加速脚本 ✅（含回退）

1. 在 `StartDevEnv.bat` 中实现：
   - 计算 U 盘盘符、构造隔离 PATH。✅
   - 设置 Arduino 环境变量。✅
   - 若存在 ImDisk 且以管理员运行，创建 RAMDisk `R:`。✅
   - 否则回退到 `%TEMP%\DevUDisk_build`。✅
   - 启动 VS Code。✅
2. 在 `StopDevEnv.bat` 中实现关闭 VS Code、卸载 RAMDisk、清理临时目录、弹出 U 盘。✅
3. 在 `PortableEnv\_env_init.bat` 中实现 U 盘空间 / 工具 / 核心包校验。✅

### Phase 4：示例工程与文档 ✅

1. 在 `D:\Projects\Blink` 创建标准 Arduino Blink 工程。✅
2. 在 `D:\Projects\WiFiScan` 创建 WiFi 扫描示例。✅
3. 添加 CH343 / CP210x 驱动到 `D:\PortableEnv\Drivers`。✅
4. 编写 `D:\Doc\DevUDisk_User_QuickStart_v1.0.md`。✅

### Phase 5：验证与交付 ✅

1. 执行验证清单：盘符自适应、环境校验、路径隔离、离线编译、VS Code 启动、临时目录回退均通过。✅
2. 清理构建中间文件，最终 U 盘占用约 7.0 GB，可用 51 GB。✅
3. 编写 `Doc_Dev\DevUDisk_Plan_v1.0\DevUDisk_Plan_DeliveryNotes_v1.0.md`。✅
4. 补充 ImDisk 二进制（如可能）。⏳ 受下载限制，需手动补充
5. 制作镜像文件（可选）。⏳ 待二期

---

## 3. 风险控制

| 风险 | 应对措施 |
| :--- | :--- |
| 6 GB 核心包复制耗时/失败 | 使用 `robocopy /E /Z /R:3 /W:5` 断点续传；已验证复制成功。✅ |
| Arduino-CLI 仍读取本机 `Arduino15` | 通过 `ARDUINO_DIRECTORIES_DATA` 环境变量强制指向 U 盘内路径。✅ |
| 编译找不到 `cmd.exe` / `powershell.exe` | `PATH` 中保留 `C:\Windows\System32` 与 PowerShell 目录。✅ |
| 机房无管理员权限 | 普通模式自动回退到 `%TEMP%\DevUDisk_build`，无需管理员。✅ |
| U 盘异常拔出 | 源码始终保存在 U 盘；RAMDisk/临时目录仅用于构建中间文件。✅ |
| ImDisk 无法下载 | 记录为已知限制，提供无 RAMDisk 降级模式与手动安装说明。⚠️ |

---

## 4. 验证清单

| 测试项 | 通过标准 | 状态 |
| :--- | :--- | :--- |
| 盘符自适应 | 脚本通过 `%~d0` 正确识别 D: 盘 | ✅ |
| 环境校验 | `_env_init.bat` 通过空间/工具/核心包检查 | ✅ |
| 路径隔离 | 启动后 `PATH` 仅包含 U 盘 arduino-cli 与最小系统路径 | ✅ |
| 离线编译 | Blink / WiFiScan 不依赖本机 Arduino 环境编译成功 | ✅ |
| RAMDisk 回退 | 未安装 ImDisk 时自动使用 `%TEMP%\DevUDisk_build` | ✅ |
| VS Code 启动 | `StartDevEnv.bat` 成功启动 VS Code 并打开 Projects | ✅ |
| 安全退出 | `StopDevEnv.bat` 关闭 VS Code、清理临时目录 | ✅ |
| U 盘弹出 | 执行后可在资源管理器中安全删除 | ✅ 脚本已调用 Shell.Application Eject |
| RAMDisk 加速 | 安装 ImDisk 后编译速度比 U 盘快 ≥ 30% | ⏳ 待补充 ImDisk |

---

## 5. 二期可选项

- **补充 ImDisk**：从官网下载驱动并放入 `PortableEnv\ImDisk\`，实现真正的 RAMDisk 加速。
- **集成 ESP-IDF**：将 `C:\Espressif` 移植到 U 盘，编写 ESP-IDF 启动脚本。
- **集成 Portable Git**：下载便携 Git，支持学生工程版本控制。
- **AI 插件**：下载 Continue 插件 `.vsix` 并离线安装到 VS Code。
- **镜像量产**：使用 Win32 Disk Imager 制作 `ESP32_Dev_v1.0.img`。

---

**下一步建议：**
1. 手动下载 ImDisk 驱动并放入 `PortableEnv\ImDisk\`。
2. 在目标教学机上测试普通模式与管理员模式。
3. 根据测试结果调整 `tasks.json` 中的默认串口号。
