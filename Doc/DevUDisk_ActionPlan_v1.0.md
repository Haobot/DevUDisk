# DevUDisk 开发行动规划 v1.0

> 基于《编程U盘设计与制作方案 v1.0》制定，面向当前可用资源进行调整。  
> 制定日期：2026-06-15  
> 状态：🚧 执行中

---

## 0. 关键假设与决策说明（请先确认）

由于当前系统处于自动权限模式，无法弹窗提问。以下是我基于现场勘察做出的**关键决策**，如果你希望调整，请直接回复纠正。

| 决策点 | 当前决策 | 理由 |
| :--- | :--- | :--- |
| **核心开发栈** | **Arduino-ESP32**（而非原方案的 ESP-IDF） | 本机 C 盘已有可运行的 `arduino-cli` + `esp32:esp32` 核心包，可直接移植；ESP-IDF 虽也存在，但体积更大且与原方案重复，故列为二期可选项。 |
| **编辑器** | **VS Code 便携版 + Arduino 插件** | C 盘 Arduino IDE 2.x 为安装版，配置分散在用户目录，不适合便携。VS Code 便携版可通过 `data` 目录锁定配置，与原方案一致。 |
| **RAMDisk 工具** | **ImDisk Toolkit（便携版）** | 与原方案一致，需从网络下载。 |
| **路径隔离** | 所有工具路径通过 `%~dp0` 脚本注入，不依赖系统 PATH | 与原方案一致。 |
| **构建目录** | `R:\arduino_build\[ProjectName]` | 与原方案 `R:\esp_build` 对应，改为 Arduino 构建目录。 |
| **U 盘卷标** | 已确认为 `ESP32_DEV`，簇大小 4K | 与原方案要求一致，无需重新格式化。 |

### 0.1 可用资源清单

| 资源 | 本机路径 | 大小 | 用途 |
| :--- | :--- | :--- | :--- |
| Arduino-CLI | `C:\Softwares\arduino-cli` | ~37 MB | 命令行编译/上传入口 |
| ESP32 Arduino 核心 | `C:\Users\cross\AppData\Local\Arduino15\packages\esp32` | ~5.9 GB | `esp32:esp32@3.3.10-cn` 完整核心与工具链 |
| Arduino IDE 2.x | `C:\Program Files\Arduino IDE` | ~545 MB | **不移植**，为安装版且Electron依赖重 |
| ESP-IDF v5.5.1 | `C:\Espressif` | ~7.8 GB | **二期可选**，当前不移植 |
| Python 3.12 | `C:\Users\cross\AppData\Local\Programs\Python\Python312` | - | 本机环境，U 盘内 Arduino 编译不直接依赖 |
| Git | `C:\mingw64\bin\git.exe`（Git Bash） | - | 本机环境，U 盘内如需 Git 可额外下载便携版 |

### 0.2 需要下载的资源

| 资源 | 来源 | 用途 |
| :--- | :--- | :--- |
| VS Code 便携版（zip） | https://code.visualstudio.com/docs/?dv=winzip | 编辑器 |
| Arduino 插件（VSIX） | VS Code Marketplace | Arduino 语言支持 |
| ImDisk Toolkit | https://www.ltr-data.se/opencode.html | RAMDisk |
| CH340 / CP210x 驱动 | 官方或现有驱动包 | 串口通信 |

---

## 1. 目标目录结构（U 盘根目录）

```text
ESP32_DEV (D:\)
├── StartDevEnv.bat              # ★ 唯一入口：创建 RAMDisk、注入 PATH、启动 VS Code
├── StopDevEnv.bat               # 安全退出：结束 VS Code、卸载 RAMDisk、弹出 U 盘
├── PortableEnv\
│   ├── _env_init.bat            # 环境校验（U 盘空间、工具可执行性）
│   ├── arduino-cli\
│   │   ├── arduino-cli.exe
│   │   └── packages\            # ESP32 核心包离线副本
│   │       └── esp32\
│   │           ├── hardware\
│   │           └── tools\
│   ├── VSCode\
│   │   ├── Code.exe
│   │   └── data\                # 便携配置、插件、用户数据
│   ├── ImDisk\
│   │   └── imdisk.exe           # RAMDisk 工具
│   └── Drivers\
│       ├── CH341SER.exe
│       └── CP210x_VCP.exe
├── Projects\
│   ├── Blink\
│   └── WiFiScan\
└── Docs\
    ├── DevUDisk_Plan_v1.0.md
    └── DevUDisk_ActionPlan_v1.0.md
```

---

## 2. 分阶段行动计划

### Phase 1：基础环境移植（~30 分钟，主要耗时在复制 6 GB 数据）

1. **搭建目录结构**：按上述结构创建空目录。
2. **移植 Arduino-CLI**：将 `C:\Softwares\arduino-cli` 复制到 `D:\PortableEnv\arduino-cli`。
3. **移植 ESP32 核心包**：将 `C:\Users\cross\AppData\Local\Arduino15\packages\esp32` 复制到 `D:\PortableEnv\arduino-cli\packages\esp32`。
4. **创建便携配置**：在 `D:\PortableEnv\arduino-cli\arduino-cli.yaml` 中指定 `directories.data` 为 U 盘内路径，确保不读取本机 `Arduino15`。
5. **离线验证**：在干净 PATH 下执行 `arduino-cli compile`，确认不依赖本机环境即可编译 Blink。

### Phase 2：编辑器集成（~15 分钟）

1. 下载 VS Code 便携版 zip 并解压到 `D:\PortableEnv\VSCode`。
2. 创建 `D:\PortableEnv\VSCode\data` 目录，启用便携模式。
3. 下载/安装 Arduino VS Code 插件到 `data\extensions`。
4. 配置 `data\user-data\User\settings.json`，指向 U 盘内 `arduino-cli` 与构建目录。

### Phase 3：RAMDisk 加速脚本（~20 分钟）

1. 下载 ImDisk Toolkit 并部署到 `D:\PortableEnv\ImDisk`。
2. 编写 `StartDevEnv.bat`：
   - 请求管理员权限（ImDisk 需要）。
   - 通过 `%~dp0` 计算 U 盘盘符。
   - 构造隔离 PATH：`U:\PortableEnv\arduino-cli`。
   - 创建 RAMDisk `R:`，大小可配置（默认 1 GB）。
   - 设置 `ARDUINO_BUILD_PATH=R:\arduino_build`。
   - 启动 `U:\PortableEnv\VSCode\Code.exe`。
3. 编写 `StopDevEnv.bat`：
   - 结束 VS Code 进程。
   - 卸载 RAMDisk。
   - 弹出 U 盘。
4. 编写 `PortableEnv\_env_init.bat`：
   - 校验 U 盘剩余空间 ≥ 5 GB。
   - 校验 `arduino-cli` 可执行。
   - 校验 ESP32 核心包完整性。

### Phase 4：示例工程与文档（~15 分钟）

1. 在 `D:\Projects\Blink` 创建标准 Arduino Blink 工程（针对 ESP32）。
2. 在 `D:\Projects\WiFiScan` 创建 WiFi 扫描示例。
3. 添加 CH340/CP210x 驱动到 `D:\PortableEnv\Drivers`。
4. 编写 `D:\Docs\QuickStart.md`（5 分钟上手指南）。

### Phase 5：验证与交付（~15 分钟）

1. 执行验证清单：
   - 盘符变化不影响启动。
   - 脏机器（已装 Arduino IDE 的主机）仍能正常运行。
   - RAMDisk 编译速度比 U 盘直接编译快 ≥ 30%。
   - VS Code Arduino 插件可正常编译/上传。
   - 安全退出无残留。
2. 更新 `AGENTS.md`（如新增代码/脚本）。
3. 输出交付说明与已知限制。

---

## 3. 风险控制

| 风险 | 应对措施 |
| :--- | :--- |
| 6 GB 核心包复制耗时/失败 | 使用 `robocopy /MIR /Z /R:3 /W:5` 断点续传，复制完成后校验文件数。 |
| Arduino-CLI 仍读取本机 `Arduino15` | 通过 `arduino-cli.yaml` 强制 `directories.data` 指向 U 盘内路径。 |
| VS Code 插件依赖网络 | 提前下载 `.vsix` 并离线安装到 `data\extensions`。 |
| 机房无管理员权限 | 提供无 RAMDisk 降级模式：`StartDevEnv.bat` 检测权限，失败时直接在 U 盘构建。 |
| U 盘异常拔出 | 源码始终保存在 U 盘；RAMDisk 仅用于构建中间文件。 |

---

## 4. 验证清单

| 测试项 | 通过标准 |
| :--- | :--- |
| 盘符自适应 | 将 U 盘插入不同盘符，双击 `StartDevEnv.bat` 仍能正确识别盘符 |
| 路径隔离 | 启动后 `PATH` 仅包含 U 盘内 `arduino-cli` 目录 |
| 离线编译 | 断开外网后，`arduino-cli compile` 成功生成固件 |
| RAMDisk 加速 | 同工程在 RAMDisk 构建时间比 U 盘构建时间短 ≥ 30% |
| VS Code 集成 | 在 VS Code 中点击“上传”可完成编译并上传 |
| 安全退出 | 执行 `StopDevEnv.bat` 后 R 盘消失，U 盘可正常弹出 |

---

## 5. 二期可选项

- **集成 ESP-IDF**：将 `C:\Espressif` 移植到 U 盘，编写 ESP-IDF 启动脚本。
- **集成 Portable Git**：下载便携 Git，支持学生工程版本控制。
- **镜像量产**：使用 Win32 Disk Imager 制作 `ESP32_Dev_v1.0.img`。

---

**下一步：** 立即开始 Phase 1，搭建目录结构并移植 Arduino-CLI。
