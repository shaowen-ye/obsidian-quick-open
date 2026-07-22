# Obsidian Quick Open

> 从 Finder 双击 Markdown 文件，直达对应的 Obsidian 库；空格预览也能渲染成排版。
> Double-click a Markdown file in Finder to open it in the *right* Obsidian vault — and get a rendered Quick Look preview instead of raw `##`/`**`.

macOS · JXA + Automator · 无需编译、无需开发者账号 / no build toolchain, no developer account

---

## 中文

### 痛点

用 Obsidian 管理多个库（vault）时，日常有两处反复出现的摩擦：

1. **打不开。** 在 Finder 里看到库里的某个 `.md`，想直接用它，却只能：打开 Obsidian → 进入"切换库"界面 → 找到那个库 → 再逐层点进文件夹找到文件。双击文件本身要么被别的编辑器接管，要么根本进不了 Obsidian。文件就在眼前，却要绕上好几步。
2. **看不清。** 选中 `.md` 按空格预览，出来的是**原始 Markdown 源码**——满屏的 `#`、`**`、`|`，而不是渲染后的标题、加粗、表格。快速扫一眼内容都费劲。

多设备用户还有第三处坑：**iCloud 库跨设备"隐身"。** 在手机 / iPad 上新建的 iCloud 库，Mac 双击其中的文件会被误导向别的编辑器——因为 Obsidian 的库注册表是**每台设备各自本地、不随 iCloud 同步**的。

### 对策

一套三件小工具，全部基于 macOS 原生机制（`obsidian://` URL scheme、LaunchServices、Automator、Quick Look 扩展），不修改 Obsidian 本体：

| 工具 | 解决 |
|------|------|
| **智能打开器**（`Obsidian Opener.app`） | 双击库内 `.md` → 自动在**对应库**里用 Obsidian 打开；库外 `.md` → 回退到你指定的编辑器（默认 Typora）。库列表**动态读取**，新建库零维护。 |
| **右键快捷操作**（"Open in Obsidian"） | 右键任意文件夹 → 作为整个库在 Obsidian 打开。 |
| **库注册脚本**（`register-vaults.sh`） | 一键把"是库但 Mac 没注册"的 iCloud / 本地文件夹补登记，解决跨设备隐身。 |

空格预览的渲染，用成熟的开源 [QLMarkdown](https://github.com/sbarex/QLMarkdown) Quick Look 扩展即可（见下方"可选：渲染预览"）。

### 为什么值得

把 Obsidian 库真正**融进 macOS 的原生文件工作流**：`.md` 文件回归"像普通文件一样双击即用"，无论它在 Finder 里，还是某个搜索结果里。省掉的是每次打开库内文件都要重复的"开 app → 找库 → 找文件"绕行；对 Mac + iPhone/iPad 多端同步的人尤其关键。

### 安装

```bash
git clone https://github.com/Shaowen-Ye/obsidian-quick-open.git
cd obsidian-quick-open
zsh install.sh
```

`install.sh` 会：构建打开器 app → 设为 `.md` 默认程序（自动用 Homebrew 装 [`duti`](https://github.com/moretension/duti)，没有则给出手动步骤）→ 安装右键快捷操作。可重复运行。

**前置条件**：macOS 11+、已安装 Obsidian。回退编辑器默认 Typora（可改，见下）。

### 使用

- **双击**任意库内的 `.md` / `.canvas` / `.base` → 在对应库中打开。
- **库外的 `.md`** → 用回退编辑器打开（不打扰非笔记类 Markdown，如代码仓库的 README）。
- **右键文件夹** → 服务 / 快速操作 → **Open in Obsidian** → 作为整库打开。
- **手机上新建的 iCloud 库双击进错程序？** 运行一次 `zsh register-vaults.sh` 补登记。

> 首次在 Mac 打开一个新 iCloud 库时，Obsidian 可能弹一次"信任作者 / 启用社区插件"确认，点一下即可，只弹一次。

### 可选：让空格预览渲染

```bash
brew install --cask qlmarkdown
open -a QLMarkdown            # 打开一次以注册扩展
```

然后到 **系统设置 → 通用 → 登录项与扩展 → 快速查看**，勾选 QLMarkdown。此后按空格预览 `.md` 即为渲染排版。QLMarkdown 支持自定义 CSS，可把预览调得接近你的 Obsidian 主题。

### 自定义 / 卸载

- **换回退编辑器**：编辑 `src/opener.js` 顶部的 `FALLBACK_APP`（如改成 `'Visual Studio Code'`），重跑 `zsh install.sh`。
- **卸载**：`zsh uninstall.sh`（移除 app、默认程序绑定与右键操作；`register-vaults.sh` 注册过的库仍保留在 Obsidian，可自行在库列表移除）。

### 工作原理

打开器是用 `osacompile` 编译的微型 JXA app。收到文件时：读取 `~/Library/Application Support/obsidian/obsidian.json` 拿到所有库路径，按长度降序做**最长前缀匹配**（保证像 `~/Documents` 这种大范围库不会抢走更深库里的文件）；命中就调用 `obsidian://open?path=<URL 编码的绝对路径>`（正确处理中文、空格、括号），否则回退到 `open -a <编辑器>`。出错只发通知，绝不裸 `open`（默认程序是它自己，否则会死循环）。

---

## English

### The problem

Managing several Obsidian vaults, two frictions keep coming up:

1. **Can't open it.** You see a `.md` inside a vault in Finder, but to actually use it you must launch Obsidian → open the *switch vault* screen → find the vault → drill down to the file. Double-clicking the file either gets hijacked by another editor or never reaches Obsidian at all.
2. **Can't read it.** Hit Space to Quick Look a `.md` and you get **raw Markdown source** — `#`, `**`, `|` everywhere — instead of rendered headings, bold, and tables.

Multi-device users hit a third trap: **iCloud vaults are "invisible" across devices.** A vault created on your iPhone/iPad lives in iCloud, but this Mac routes its files to the wrong app — because Obsidian's vault registry is **per-device and not synced by iCloud**.

### The fix

Three small tools, all built on native macOS mechanisms (`obsidian://` URL scheme, LaunchServices, Automator, Quick Look extensions). Nothing about Obsidian itself is modified:

| Tool | What it does |
|------|--------------|
| **Smart opener** (`Obsidian Opener.app`) | Double-click a `.md` in a vault → opens in Obsidian in the **correct vault**; a `.md` outside any vault → opens in your fallback editor (default Typora). The vault list is read **live**, so new vaults need zero maintenance. |
| **Right-click action** ("Open in Obsidian") | Right-click any folder → open it as a whole vault. |
| **Vault registrar** (`register-vaults.sh`) | One command to register any "is-a-vault-but-unregistered" iCloud/local folder, fixing the cross-device invisibility. |

For rendered previews, use the excellent open-source [QLMarkdown](https://github.com/sbarex/QLMarkdown) Quick Look extension (see *Optional: rendered previews*).

### Why it matters

It folds Obsidian vaults into the **native macOS file workflow**: `.md` files behave like any other file you can just double-click — whether in Finder or a search result. What you save is the "launch app → find vault → find file" detour every time you open a note — and for Mac + iPhone/iPad users it removes a real dead end.

### Install

```bash
git clone https://github.com/Shaowen-Ye/obsidian-quick-open.git
cd obsidian-quick-open
zsh install.sh
```

`install.sh` builds the opener app, sets it as the default `.md` handler (auto-installs [`duti`](https://github.com/moretension/duti) via Homebrew, or prints manual steps), and installs the right-click action. Re-runnable. **Requires** macOS 11+ and Obsidian.

### Usage

- **Double-click** any `.md` / `.canvas` / `.base` in a vault → opens in the right vault.
- **A `.md` outside any vault** → opens in the fallback editor (won't disturb non-note Markdown like a repo README).
- **Right-click a folder** → Services / Quick Actions → **Open in Obsidian**.
- **A vault made on your phone opens in the wrong app?** Run `zsh register-vaults.sh` once.

### Optional: rendered previews

```bash
brew install --cask qlmarkdown
open -a QLMarkdown            # launch once to register the extension
```

Then enable QLMarkdown under **System Settings → General → Login Items & Extensions → Quick Look**. QLMarkdown supports custom CSS, so you can style previews close to your Obsidian theme.

### Customize / uninstall

- **Change the fallback editor**: edit `FALLBACK_APP` at the top of `src/opener.js`, then re-run `zsh install.sh`.
- **Uninstall**: `zsh uninstall.sh`.

### How it works

The opener is a tiny JXA app compiled with `osacompile`. On receiving a file it reads Obsidian's `obsidian.json`, does a **longest-prefix match** against all vault paths (so a broad vault like `~/Documents` never steals files that belong to a deeper vault), and either calls `obsidian://open?path=<url-encoded absolute path>` or falls back to `open -a <editor>`. On error it only posts a notification — never a bare `open`, which would loop back into itself.

---

## License

[MIT](LICENSE) © 2026 Shaowen-Ye
