# DevUDisk 第一阶段交付说明

> 交付日期：2026-06-15  
> 交付版本：v1.0（Arduino-ESP32 基础环境）  
> U 盘卷标：`ESP32_DEV`  
> 文件系统：NTFS / 4K 簇

---

## 1. 交付内容

本次完成 DevUDisk 第一阶段开发，U 盘内已实现**插上即用**的 Arduino-ESP32 开发环境。

### 1.1 入口脚本

| 文件 | 用途 | 运行方式 |
| :--- | :--- | :--- |
| `StartDevEnv.bat` | 启动开发环境：校验环境、注入隔离 PATH、启动 VS Code | 双击运行；需要 RAMDisk 时右键“以管理员身份运行” |
| `StopDevEnv.bat` | 安全退出：关闭 VS Code、卸载 RAMDisk、清理临时目录、弹出 U 盘 | 双击运行 |
| `PortableEnv\_env_init.bat` | 环境校验：空间、arduino-cli、ESP32 核心包 | 被 `StartDevEnv.bat` 自动调用 |

### 1.2 工具链

| 目录 | 内容 | 大小 |
| :--- | :--- | :--- |
| `PortableEnv\arduino-cli\` | Arduino-CLI 1.4.1 + ESP32 核心包 v3.3.10-cn + builtin 工具 | ~6.0 GB |
| `PortableEnv\VSCode\` | VS Code 便携版（启用 `data` 目录锁定配置） | ~837 MB |
| `PortableEnv\Drivers\CH343\` | CH343/CH340 串口驱动 | ~1.0 MB |
| `PortableEnv\Drivers\CP210x\` | CP210x 串口驱动 | ~0.6 MB |
| `PortableEnv\ImDisk\` | ImDisk 占位目录（**二进制需手动补充**） | - |

### 1.3 示例工程

| 工程 | 说明 |
| :--- | :--- |
| `Projects\Blink\` | ESP32 板载 LED 闪烁示例 |
| `Projects\WiFiScan\` | ESP32 WiFi 扫描示例 |

每个工程目录下包含 `.vscode\tasks.json`，提供：
- **Arduino: Build (RAMDisk)**：`Ctrl + Shift + B` 编译
- **Arduino: Upload**：上传固件（需修改默认串口 `COM3`）

### 1.4 文档

| 文件 | 说明 |
| :--- | :--- |
| `Doc\DevUDisk_Plan_v1.0.md` | 原始设计与制作方案 |
| `Docs\DevUDisk_ActionPlan_v1.0.md` | 当前开发行动规划 |
| `Docs\QuickStart.md` | 5 分钟上手指南 |
| `AGENTS.md` | 项目代理指南 |

---

## 2. 已验证项目

| 验证项 | 结果 |
| :--- | :--- |
| 盘符自适应 | ✅ 通过 `%~d0` 正确识别 D: 盘 |
| 环境校验 | ✅ `_env_init.bat` 通过空间/工具/核心包检查 |
| 路径隔离 | ✅ `PATH` 仅包含 U 盘 arduino-cli 与最小系统路径 |
| Blink 离线编译 | ✅ 成功，固件 285084 字节 |
| WiFiScan 离线编译 | ✅ 成功，固件 888548 字节 |
| VS Code 启动 | ✅ `StartDevEnv.bat` 成功启动并打开 Projects |
| 临时目录回退 | ✅ 无 ImDisk 时自动使用 `%TEMP%\DevUDisk_build` |
| 安全退出 | ✅ 关闭 VS Code、清理临时目录 |

---

## 3. 已知限制与后续工作

### 3.1 ImDisk RAMDisk 未内置

- **原因**：ImDisk 官方下载站点（ltr-data.se / SourceForge）启用 Cloudflare 保护，自动化下载被拦截。
- **影响**：当前版本优先使用 `%TEMP%\DevUDisk_build`（主机本地临时目录）作为构建目录，速度仍明显优于直接在 U 盘构建，但不及真正 RAMDisk。
- **解决方案**：
  1. 从 https://www.ltr-data.se/opencode.html 手动下载 ImDisk Toolkit 安装包。
  2. 将 `imdisk.exe` 及相关驱动文件放入 `PortableEnv\ImDisk\`。
  3. 在目标机器上安装 ImDisk 驱动（需管理员权限一次）。
  4.  thereafter 以管理员身份运行 `StartDevEnv.bat` 即可启用 `R:\arduino_build`。

### 3.2 默认串口号

- 示例工程 `tasks.json` 中上传任务默认使用 `COM3`。
- 实际使用前请根据设备管理器中的串口号修改。

### 3.3 未集成的二期功能

- **ESP-IDF**：本机 `C:\Espressif` 已就绪，可作为二期移植来源。
- **AI 插件（Continue）**：需联网下载 `.vsix` 后离线安装。
- **Portable Git**：如需版本控制，可补充。
- **量产镜像**：待补充 ImDisk / 二期功能后，使用 Win32 Disk Imager 制作 `.img`。

---

## 4. 使用步骤

1. 将 U 盘插入 Windows 电脑 USB 3.0 接口。
2. 打开文件资源管理器，进入 U 盘根目录。
3. 双击 `StartDevEnv.bat`。
4. 在 VS Code 中打开 `Projects\Blink`，按 `Ctrl + Shift + B` 编译。
5. 开发完成后，双击 `StopDevEnv.bat` 安全退出。

---

## 5. 磁盘空间

```text
Filesystem: D: (NTFS)
Total:      58 GB
Used:       7.0 GB
Available:  51 GB
```

---

**方案制定人：** ESP32 课程开发组  
**生效日期：** 2026-06-15  
**状态：** ✅ 可交付（第一阶段）
