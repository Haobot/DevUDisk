# DevUDisk RAMDisk 静默创建设计

> 本文档说明如何在 `StartDevEnv.bat` 中屏蔽 RAMDisk 创建后资源管理器自动弹窗的问题。

## 1. 背景

当前 `StartDevEnv.bat` 在管理员模式下使用 Arsenal Image Mounter 的 `aim_ll.exe` 创建 RAMDisk 后，Windows 会为新挂载的卷自动打开资源管理器窗口。在教学机房等多窗口环境中，这会造成干扰，用户希望创建过程完全静默。

## 2. 目标

- RAMDisk 创建成功后，不弹出资源管理器窗口。
- 不改变 Windows 全局 AutoRun/AutoPlay 行为，避免影响其他 U 盘或移动硬盘。
- 改动最小，仅作用于当前启动流程创建的 RAMDisk 盘符。

## 3. 方案选择

| 方案 | 说明 | 优点 | 缺点 |
|------|------|------|------|
| 1. 关闭 RAMDisk 窗口（推荐） | 创建成功后，通过 Shell.Application COM 对象关闭指向该盘符的资源管理器窗口 | 只影响当前 RAMDisk；不修改系统设置 | 可能有极短窗口闪现 |
| 2. 临时禁用 AutoRun/AutoPlay | 创建前写入 `NoDriveTypeAutoRun`，创建后恢复 | 理论上可阻止弹窗 | 注册表刷新不及时；恢复失败会留下副作用 |
| 3. 永久禁用 AutoRun/AutoPlay | 直接修改当前用户注册表 | 一劳永逸 | 影响所有可移动设备的自动播放行为 |

采用 **方案 1**。

## 4. 实现细节

在 `StartDevEnv.bat` 中，`aim_ll.exe` 创建 RAMDisk 成功并等待卷就绪后，加入如下调用：

```bat
powershell -NoProfile -Command "& {$shell=New-Object -ComObject Shell.Application; $path='%RAMDISK_LETTER%'; $shell.Windows() | Where-Object { ($_.Document -and $_.Document.Folder -and ($_.Document.Folder.Self.Path -eq $path)) -or ($_.LocationURL -like ('file:///' + $path + '*')) } | ForEach-Object { $_.Quit() }}" >nul 2>&1
```

### 4.1 插入位置

位于 `:wait_volume` 标签内，在 `echo [INFO] RAMDisk 创建成功。` 之后、`set "ARDUINO_BUILD_BASE=%RAMDISK_LETTER%\arduino_build"` 之前。

### 4.2 行为说明

- 仅关闭指向当前 `RAMDISK_LETTER%` 的资源管理器窗口。
- 如果用户之前手动打开了同盘符窗口，也会被关闭；但该盘符在启动前不可能存在，因此不影响用户已有操作。
- 命令使用 `>nul 2>&1` 抑制输出，失败也不中断启动流程。

## 5. 避免重复建立 RAMDisk

用户反馈多次运行 `StartDevEnv.bat` 后会出现多个 RAMDisk。原因是在未正常卸载或 `StopDevEnv.bat` 未执行的情况下，已有 RAMDisk 仍占用盘符，`StartDevEnv.bat` 会回退到其他盘符并创建新的 RAMDisk。

### 5.1 解决方案

在 `StartDevEnv.bat` 创建新 RAMDisk 之前，先调用已存在的清理脚本 `PortableEnv\_cleanup_ramdisks.ps1`，强制卸载所有 Arsenal Image Mounter 类型的 RAMDisk（Virtual Memory）。清理完成后再重新检查盘符可用性并创建新的 RAMDisk。

```bat
if exist "%U_DISK%\PortableEnv\_cleanup_ramdisks.ps1" (
    echo [INFO] 正在清理可能遗留的 RAMDisk ...
    powershell -NoProfile -ExecutionPolicy Bypass -File "%U_DISK%\PortableEnv\_cleanup_ramdisks.ps1" -AimLlPath "%AIMLL%"
)
```

### 5.2 插入位置

该清理调用应放在盘符选择逻辑之后、`aim_ll.exe` 创建 RAMDisk 之前。如果清理脚本卸载了占用默认盘符的遗留 RAMDisk，则后续 `:try_pick_letter` 的结果可能需要重新评估；因此实际实现时可在清理后再次执行一次盘符选择。

## 6. 影响范围

- 修改文件：`StartDevEnv.bat`
- 复用已有脚本：`PortableEnv\_cleanup_ramdisks.ps1`
- 不新增外部依赖，仅使用 Windows 自带的 PowerShell 与 COM 对象。
- 不影响 RamService/ImDisk 回退路径（这些路径未报告弹窗问题，若后续需要可同样添加）。

## 7. 验证方式

1. 以管理员身份运行 `StartDevEnv.bat`，确认 RAMDisk 创建成功。
2. 不运行 `StopDevEnv.bat`，再次以管理员身份运行 `StartDevEnv.bat`，确认不会创建第二个 RAMDisk，而是复用/清理后重新创建在同一个默认盘符。
3. 观察 RAMDisk 创建完成后，资源管理器是否不再自动打开新磁盘窗口。
4. 确认 VS Code: 正常启动，构建任务可正常使用 RAMDisk 路径。
