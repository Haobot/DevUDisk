# DevUDisk 文档管理规则 v1.1

> 本文档规定 DevUDisk 项目所有 Markdown 文档的存放位置、命名规范与版本管理规则。  
> 制定日期：2026-06-15  
> 生效状态：✅ 严格执行

---

## 1. 目录结构规则

### 1.1 顶层划分

| 目录 | 用途 | 目标读者 |
| :--- | :--- | :--- |
| `D:\Doc_Dev\` | 开发者/代理/交付人员文档 | 项目开发者、AI 代理、课程开发组 |
| `D:\Doc\` | 用户说明文档 | 使用 U 盘的学生、教师 |

> **禁止**将开发者文档放入 `D:\Doc\`，也禁止将用户文档放入 `D:\Doc_Dev\`。

### 1.2 `Doc_Dev\` 内部子目录规则

为便于同一主题/版本的文档集中管理，`Doc_Dev\` 内部采用**子目录分组**：

| 位置 | 用途 | 示例 |
| :--- | :--- | :--- |
| `Doc_Dev\{基础文档名}_v{版本号}\` | 同一基础文档的派生文档分组 | `Doc_Dev\DevUDisk_Plan_v1.0\` |
| `Doc_Dev\` 根目录 | 项目级、跨主题的独立文档 | `DevUDisk_DocumentRules_v1.1.md` |

**分组原则：**
- 当某一基础文档存在 2 个及以上派生文档时，必须为其创建子目录。
- 子目录名称与基础文档文件名一致（不含扩展名）。
- 派生文档必须放入对应子目录，禁止平铺在 `Doc_Dev\` 根目录。

---

## 2. 文件命名规则

所有 Markdown 文档统一采用以下格式：

```text
DevUDisk_{继承关系}_{含义}_v{版本号}.md
```

### 2.1 各字段说明

| 字段 | 说明 | 示例 |
| :--- | :--- | :--- |
| `DevUDisk` | 项目前缀，固定不变 | `DevUDisk` |
| `{继承关系}` | 文档与顶层规划的层级关系 | `Plan`、`Plan_ActionPlan`、`Plan_DeliveryNotes`、`User` |
| `{含义}` | 文档核心主题 | `Plan`、`ActionPlan`、`DeliveryNotes`、`QuickStart`、`DocumentRules` |
| `v{版本号}` | 文档版本，采用 `主.次` 格式 | `v1.0`、`v1.1` |

### 2.2 继承关系示例

| 文件名 | 继承关系 | 存放路径 | 说明 |
| :--- | :--- | :--- | :--- |
| `DevUDisk_Plan_v1.0.md` | 顶层规划 | `Doc_Dev\DevUDisk_Plan_v1.0\` | 原始设计与制作方案 |
| `DevUDisk_Plan_ActionPlan_v1.0.md` | 派生自 Plan | `Doc_Dev\DevUDisk_Plan_v1.0\` | 基于规划制定的开发行动规划 |
| `DevUDisk_Plan_DeliveryNotes_v1.0.md` | 派生自 Plan | `Doc_Dev\DevUDisk_Plan_v1.0\` | 基于规划生成的交付说明 |
| `DevUDisk_DocumentRules_v1.1.md` | 项目级规则 | `Doc_Dev\` | 文档管理规则本身 |
| `DevUDisk_User_QuickStart_v1.0.md` | 用户文档 | `Doc\` | 面向最终用户的快速入门 |

### 2.3 命名禁忌

- 禁止省略 `DevUDisk` 前缀。
- 禁止省略版本号。
- 禁止使用模糊含义，如 `doc.md`、`note.md`、`temp.md`。
- 禁止在文件名中使用空格或特殊符号（除下划线 `_` 和点 `.` 外）。

---

## 3. 版本管理规则

1. **版本号格式**：`v{主版本}.{次版本}`，例如 `v1.0`、`v1.1`、`v2.0`。
2. **主版本升级**：文档结构、核心决策或适用范围发生重大变更时升级。
3. **次版本升级**：内容修正、补充说明、错误修复时升级。
4. **版本一致性**：同一子目录内的相关文档（如 Plan 与 Plan_ActionPlan）应尽量保持主版本一致。
5. **规则文档版本**：本规则当前版本为 **v1.1**（因新增子目录分组规则）。

---

## 4. 文档引用规则

1. 文档内部引用其他文档时，必须写明相对路径，且路径必须与当前目录结构一致。
2. 引用示例：
   - 在 `Doc_Dev\DevUDisk_Plan_v1.0\DevUDisk_Plan_ActionPlan_v1.0.md` 中引用用户指南：`..\..\Doc\DevUDisk_User_QuickStart_v1.0.md`
   - 在 `Doc\DevUDisk_User_QuickStart_v1.0.md` 中引用交付说明：`..\Doc_Dev\DevUDisk_Plan_v1.0\DevUDisk_Plan_DeliveryNotes_v1.0.md`
3. 禁止在文档中使用旧路径，如 `Docs\`、`Docs_Dev\`、平铺的 `Doc_Dev\DevUDisk_Plan_*.md`。

---

## 5. 目录与文件清单（当前）

```text
D:/
├── Doc/                                                      # 用户文档
│   └── DevUDisk_User_QuickStart_v1.0.md                      # 5 分钟上手指南
├── Doc_Dev/                                                  # 开发者文档
│   ├── DevUDisk_DocumentRules_v1.1.md                        # 本文档
│   └── DevUDisk_Plan_v1.0/                                   # Plan v1.0 文档族
│       ├── DevUDisk_Plan_v1.0.md                             # 原始设计与制作方案
│       ├── DevUDisk_Plan_ActionPlan_v1.0.md                  # 开发行动规划
│       └── DevUDisk_Plan_DeliveryNotes_v1.0.md               # 交付说明
└── AGENTS.md                                                 # 项目代理指南
```

---

## 6. 违规处理

- 新增或修改文档前，必须先对照本规则检查命名、存放位置与子目录分组。
- 发现历史文档不符合本规则时，应在下一次文档更新时同步修正。
- 任何代理或开发者不得在本规则外自行创建新的文档目录。

---

**制定人：** ESP32 课程开发组  
**生效日期：** 2026-06-15  
**状态：** ✅ 强制执行
