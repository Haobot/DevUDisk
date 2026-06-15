# DevUDisk

**A portable, plug-and-play ESP32 Arduino development environment on a USB drive for Windows.**

> **中文版介绍见下方。**

DevUDisk lets students, teachers, and makers carry a complete ESP32 Arduino-CLI + VS Code setup on a USB drive. Insert the drive into any Windows PC, double-click `StartDevEnv.bat`, and start coding without installing anything on the host machine.

---

## ✨ Features

- **Zero Installation**: No software needs to be installed on the host PC (except the optional ImDisk RAMDisk driver).
- **Environment Isolation**: `PATH` is restricted to tools on the USB drive plus minimal Windows system paths.
- **Fast Compilation**: Builds go to a RAMDisk when ImDisk is available; otherwise they fall back to the local `%TEMP%` directory.
- **Portable VS Code**: Settings, extensions, and user data are locked inside `PortableEnv\VSCode\data`.
- **Offline Ready**: ESP32 Arduino core, toolchains, and serial drivers are pre-copied to the drive.
- **Teaching Friendly**: Includes sample projects (`Blink`, `WiFiScan`) with VS Code tasks for build and upload.

---

## 📋 Requirements

- Windows 10/11 PC
- USB 3.0 port (recommended)
- A USB drive formatted as:
  - **File system**: NTFS
  - **Cluster size**: 4096 bytes (4K)
  - **Volume label**: `ESP32_DEV`
- At least **60 GB** drive capacity (≥ 55 GB usable)

---

## 🚀 Quick Start

1. Insert the `ESP32_DEV` USB drive into a Windows PC.
2. Open File Explorer and go to the drive root.
3. Double-click **`StartDevEnv.bat`**.
4. In VS Code:, open `Blink → Blink.ino` from the workspace explorer.
5. Press `Ctrl + Shift + B` to run the default build task.
6. Connect an ESP32 board and update the COM port in `.vscode\tasks.json` if needed.
7. Run the **Arduino: Upload** task to flash the firmware.

For a more detailed guide, see [`Doc\DevUDisk_User_QuickStart_v1.0.md`](Doc/DevUDisk_User_QuickStart_v1.0.md).

---

## 📁 Directory Structure

```text
D:/
├── Doc/                                          # End-user documentation
│   └── DevUDisk_User_QuickStart_v1.0.md
├── Doc_Dev/                                      # Developer/agent documentation
│   ├── DevUDisk_DocumentRules_v1.1.md
│   └── DevUDisk_Plan_v1.0/
│       ├── DevUDisk_Plan_v1.0.md
│       ├── DevUDisk_Plan_ActionPlan_v1.0.md
│       └── DevUDisk_Plan_DeliveryNotes_v1.0.md
├── PortableEnv/                                  # Portable toolchain (not tracked by git)
│   ├── _env_init.bat
│   ├── arduino-cli/                              # Arduino-CLI + ESP32 core
│   ├── VSCode/                                   # VS Code portable edition
│   ├── ImDisk/                                   # ImDisk placeholder (driver not included)
│   └── Drivers/                                  # CH343/CH340 and CP210x drivers
├── Projects/                                     # Sample projects (not tracked by git)
│   ├── Blink/
│   └── WiFiScan/
├── DevUDisk.code-workspace                       # Multi-project VS Code: workspace
├── StartDevEnv.bat                               # Launch development environment
├── StopDevEnv.bat                                # Safely stop and eject
└── README.md                                     # This file
```

> `PortableEnv/` and `Projects/` are excluded from version control by `.gitignore`. A deliverable U drive must contain the full `PortableEnv/` directory.

---

## ⚙️ How It Works

### StartDevEnv.bat

1. Detects the USB drive letter from the script location (`%~d0`).
2. Calls `PortableEnv\_env_init.bat` to verify free space, `arduino-cli`, and the ESP32 core.
3. Sets Arduino environment variables so only the USB drive's packages are used.
4. Creates an `R:` RAMDisk if ImDisk is installed and the script is run as administrator.
5. Falls back to `%TEMP%\DevUDisk_build` if RAMDisk is unavailable.
6. Launches portable VS Code: with the `DevUDisk.code-workspace` multi-project workspace and an isolated `PATH`.

### StopDevEnv.bat

1. Closes VS Code.
2. Unmounts the `R:` RAMDisk if present.
3. Cleans up `%TEMP%\DevUDisk_build`.
4. Ejects the USB drive safely.

---

## ✅ Verified Projects

| Project | Result |
| :--- | :--- |
| `Projects\Blink` | ✅ Compiles offline, firmware 285,084 bytes |
| `Projects\WiFiScan` | ✅ Compiles offline, firmware 888,548 bytes |

---

## ⚠️ Known Limitations

- **ImDisk RAMDisk not included**: Automated downloads from ltr-data.se / SourceForge are blocked by Cloudflare. The environment falls back to `%TEMP%` for builds. To enable true RAMDisk, install ImDisk manually and run `StartDevEnv.bat` as administrator.
- **Default upload port is COM3**: Update `.vscode\tasks.json` for your actual board port.
- **ESP-IDF not included**: The original plan targeted ESP-IDF; the current release uses Arduino-ESP32 for faster deployment. ESP-IDF can be added in Phase 2.

---

## 🗺️ Roadmap

- [x] Arduino-ESP32 portable environment
- [x] VS Code portable with build/upload tasks
- [x] Sample projects (Blink, WiFiScan)
- [x] Serial drivers (CH343/CH340, CP210x)
- [ ] ImDisk RAMDisk binary and auto-install
- [ ] ESP-IDF support
- [ ] Continue AI plugin (offline `.vsix`)
- [ ] Portable Git
- [ ] Mass-production disk image (`ESP32_Dev_v1.0.img`)

---

## 📚 Documentation

- User quick start: [`Doc\DevUDisk_User_QuickStart_v1.0.md`](Doc/DevUDisk_User_QuickStart_v1.0.md)
- Developer planning: [`Doc_Dev\DevUDisk_Plan_v1.0\DevUDisk_Plan_v1.0.md`](Doc_Dev/DevUDisk_Plan_v1.0/DevUDisk_Plan_v1.0.md)
- Development action plan: [`Doc_Dev\DevUDisk_Plan_v1.0\DevUDisk_Plan_ActionPlan_v1.0.md`](Doc_Dev/DevUDisk_Plan_v1.0/DevUDisk_Plan_ActionPlan_v1.0.md)
- Delivery notes: [`Doc_Dev\DevUDisk_Plan_v1.0\DevUDisk_Plan_DeliveryNotes_v1.0.md`](Doc_Dev/DevUDisk_Plan_v1.0/DevUDisk_Plan_DeliveryNotes_v1.0.md)
- Document rules: [`Doc_Dev\DevUDisk_DocumentRules_v1.1.md`](Doc_Dev/DevUDisk_DocumentRules_v1.1.md)

---

## 🤝 Contributing

This project is primarily for ESP32 teaching and competition use. Keep changes:

- Simple and maintainable
- Portable and offline-friendly
- Consistent with the document rules in `Doc_Dev\DevUDisk_DocumentRules_v1.1.md`

---

## 📄 License

DevUDisk is licensed under the **Apache License 2.0**. See [`LICENSE`](LICENSE) for the full text.

Third-party components bundled or referenced by this project (Arduino-CLI, ESP32 Arduino core, VS Code, ImDisk, serial drivers, etc.) remain under their respective licenses.

---
---

# DevUDisk（中文版）

**基于 U 盘的 Windows 平台 ESP32 Arduino 便携开发环境，即插即用。**

DevUDisk 让学生、教师和创客把完整的 ESP32 Arduino-CLI + VS Code 环境带在 U 盘上。插入任意 Windows 电脑，双击 `StartDevEnv.bat` 即可开始开发，无需在主机安装任何软件。

---

## ✨ 特性

- **零安装**：无需在主机安装软件（可选的 ImDisk RAMDisk 驱动除外）。
- **环境隔离**：`PATH` 被限制为 U 盘内工具加最小 Windows 系统路径。
- **快速编译**：可用时优先使用 RAMDisk 构建；不可用时自动回退到本地 `%TEMP%` 目录。
- **便携 VS Code**：配置、插件、用户数据全部锁定在 `PortableEnv\VSCode\data`。
- **离线可用**：ESP32 Arduino 核心、工具链、串口驱动均已预复制到 U 盘。
- **教学友好**：内置 `Blink`、`WiFiScan` 示例工程，配置好 VS Code 编译/上传任务。

---

## 📋 系统要求

- Windows 10/11 电脑
- USB 3.0 接口（推荐）
- U 盘需格式化为：
  - **文件系统**：NTFS
  - **簇大小**：4096 字节（4K）
  - **卷标**：`ESP32_DEV`
- 容量至少 **60 GB**（可用空间 ≥ 55 GB）

---

## 🚀 快速开始

1. 将 `ESP32_DEV` U 盘插入 Windows 电脑。
2. 打开文件资源管理器，进入 U 盘根目录。
3. 双击 **`StartDevEnv.bat`**。
4. 在 VS Code: 工作区资源管理器中打开 `Blink → Blink.ino`。
5. 按 `Ctrl + Shift + B` 运行默认构建任务。
6. 连接 ESP32 开发板，如有需要修改 `.vscode\tasks.json` 中的 COM 口号。
7. 运行 **Arduino: Upload** 任务上传固件。

详细指南见 [`Doc\DevUDisk_User_QuickStart_v1.0.md`](Doc/DevUDisk_User_QuickStart_v1.0.md)。

---

## 📁 目录结构

```text
D:/
├── Doc/                                          # 用户说明文档
│   └── DevUDisk_User_QuickStart_v1.0.md
├── Doc_Dev/                                      # 开发者/代理文档
│   ├── DevUDisk_DocumentRules_v1.1.md
│   └── DevUDisk_Plan_v1.0/
│       ├── DevUDisk_Plan_v1.0.md
│       ├── DevUDisk_Plan_ActionPlan_v1.0.md
│       └── DevUDisk_Plan_DeliveryNotes_v1.0.md
├── PortableEnv/                                  # 便携工具链（不被 git 追踪）
│   ├── _env_init.bat
│   ├── arduino-cli/                              # Arduino-CLI + ESP32 核心
│   ├── VSCode/                                   # VS Code 便携版
│   ├── ImDisk/                                   # ImDisk 占位目录（未包含驱动）
│   └── Drivers/                                  # CH343/CH340 与 CP210x 驱动
├── Projects/                                     # 示例工程（不被 git 追踪）
│   ├── Blink/
│   └── WiFiScan/
├── DevUDisk.code-workspace                       # 多工程 VS Code: 工作区
├── StartDevEnv.bat                               # 启动开发环境
├── StopDevEnv.bat                                # 安全退出并弹出 U 盘
└── README.md                                     # 本文件
```

> `PortableEnv/` 和 `Projects/` 被 `.gitignore` 排除。实际交付的 U 盘必须包含完整的 `PortableEnv/` 目录。

---

## ⚙️ 工作原理

### StartDevEnv.bat

1. 根据脚本位置自动识别 U 盘盘符（`%~d0`）。
2. 调用 `PortableEnv\_env_init.bat` 校验剩余空间、`arduino-cli` 和 ESP32 核心。
3. 设置 Arduino 环境变量，确保只使用 U 盘内的包。
4. 如果已安装 ImDisk 且以管理员身份运行，则创建 `R:` RAMDisk。
5. 无 RAMDisk 时回退到 `%TEMP%\DevUDisk_build`。
6. 在隔离的 `PATH` 下启动便携版 VS Code:，并打开 `DevUDisk.code-workspace` 多工程工作区。

### StopDevEnv.bat

1. 关闭 VS Code。
2. 如果存在则卸载 `R:` RAMDisk。
3. 清理 `%TEMP%\DevUDisk_build`。
4. 安全弹出 U 盘。

---

## ✅ 已验证工程

| 工程 | 结果 |
| :--- | :--- |
| `Projects\Blink` | ✅ 离线编译通过，固件 285,084 字节 |
| `Projects\WiFiScan` | ✅ 离线编译通过，固件 888,548 字节 |

---

## ⚠️ 已知限制

- **未内置 ImDisk RAMDisk**：ltr-data.se / SourceForge 的自动下载受 Cloudflare 保护拦截，当前构建回退到 `%TEMP%`。如需真正 RAMDisk，请手动安装 ImDisk 驱动并以管理员身份运行 `StartDevEnv.bat`。
- **默认上传串口为 COM3**：请根据实际板子修改 `.vscode\tasks.json`。
- **未包含 ESP-IDF**：原方案面向 ESP-IDF，当前版本为快速交付改用 Arduino-ESP32，ESP-IDF 列为二期可选项。

---

## 🗺️ 路线图

- [x] Arduino-ESP32 便携环境
- [x] 带编译/上传任务的 VS Code 便携版
- [x] 示例工程（Blink、WiFiScan）
- [x] 串口驱动（CH343/CH340、CP210x）
- [ ] ImDisk RAMDisk 二进制与自动安装
- [ ] ESP-IDF 支持
- [ ] Continue AI 插件（离线 `.vsix`）
- [ ] 便携 Git
- [ ] 量产镜像（`ESP32_Dev_v1.0.img`）

---

## 📚 文档索引

- 用户快速入门：[`Doc\DevUDisk_User_QuickStart_v1.0.md`](Doc/DevUDisk_User_QuickStart_v1.0.md)
- 开发者规划：[`Doc_Dev\DevUDisk_Plan_v1.0\DevUDisk_Plan_v1.0.md`](Doc_Dev/DevUDisk_Plan_v1.0/DevUDisk_Plan_v1.0.md)
- 开发行动规划：[`Doc_Dev\DevUDisk_Plan_v1.0\DevUDisk_Plan_ActionPlan_v1.0.md`](Doc_Dev/DevUDisk_Plan_v1.0/DevUDisk_Plan_ActionPlan_v1.0.md)
- 交付说明：[`Doc_Dev\DevUDisk_Plan_v1.0\DevUDisk_Plan_DeliveryNotes_v1.0.md`](Doc_Dev/DevUDisk_Plan_v1.0/DevUDisk_Plan_DeliveryNotes_v1.0.md)
- 文档管理规则：[`Doc_Dev\DevUDisk_DocumentRules_v1.1.md`](Doc_Dev/DevUDisk_DocumentRules_v1.1.md)

---

## 🤝 贡献

本项目主要面向 ESP32 教学和竞赛场景。请保持变更：

- 简单且可维护
- 便携且可离线运行
- 与 `Doc_Dev\DevUDisk_DocumentRules_v1.1.md` 的文档规则一致

---

## 📄 许可

DevUDisk 采用 **Apache License 2.0** 许可证。完整文本见 [`LICENSE`](LICENSE)。

本项目附带或引用的第三方组件（Arduino-CLI、ESP32 Arduino 核心、VS Code、ImDisk、串口驱动等）仍遵循其各自许可协议。
