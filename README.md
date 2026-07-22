# Obsidian Quick Open

在 Finder 中双击 Markdown 文件，即可在其所属的 Obsidian 库中打开；空格预览也渲染为排版后的样式。
Double-click a Markdown file in Finder to open it in its Obsidian vault, with a rendered Quick Look preview.

**平台** macOS 11+ · **实现** JXA / Automator / LaunchServices · **依赖** Obsidian（预览渲染另需 QLMarkdown）

---

## 中文

### 解决的问题

使用 Obsidian 管理多个库（vault）时，存在两处反复出现的摩擦：

1. **无法直接打开。** 在 Finder 中看到某个库内的 `.md` 文件，却无法直接使用：需要先启动 Obsidian，进入"切换库"界面，选择对应的库，再逐层进入文件夹定位该文件。若直接双击文件，则会被其他编辑器接管，无法进入 Obsidian。
2. **预览不可读。** 选中 `.md` 文件按空格预览，显示的是 Markdown 源码（`#`、`**`、`|` 等符号），而非渲染后的标题、加粗与表格。

对于多设备用户，还存在第三处问题：**iCloud 库跨设备不可见。** 在 iPhone 或 iPad 上创建的 iCloud 库，其笔记在 Mac 上会被导向错误的程序——因为 Obsidian 的库注册表（`obsidian.json`）由各设备独立维护，不经 iCloud 同步。

### 解决方案

三个基于 macOS 原生机制（`obsidian://` URL scheme、LaunchServices、Automator、Quick Look 扩展）的组件，均不修改 Obsidian 本体：

| 组件 | 功能 |
|------|------|
| 智能打开器 `Obsidian Opener.app` | 双击库内的 `.md` / `.canvas` / `.base`，在其所属库中打开；库外的 `.md` 交由指定编辑器（默认 Typora）。库列表在每次运行时实时读取，新建库无需额外配置。 |
| 右键操作 “Open in Obsidian” | 右键任意文件夹，将其作为完整的库打开。 |
| 库注册脚本 `register-vaults.sh` | 一键登记“本身是库、但当前 Mac 尚未注册”的 iCloud 或本地文件夹，解决跨设备不可见问题。 |

空格预览的渲染由开源的 [QLMarkdown](https://github.com/sbarex/QLMarkdown) Quick Look 扩展提供（见“预览渲染”）。

### 价值

该工具将 Obsidian 库纳入 macOS 的原生文件工作流：无论在 Finder 还是搜索结果中，`.md` 文件都可像普通文件一样双击使用，省去每次打开库内文件时“启动程序 → 选择库 → 定位文件”的重复步骤。对于在 Mac 与 iPhone / iPad 之间同步的用户，这一改善尤为明显。

### 安装

```bash
git clone https://github.com/Shaowen-Ye/obsidian-quick-open.git
cd obsidian-quick-open
zsh install.sh
```

`install.sh` 依次完成：构建打开器；将其设为 `.md` 的默认程序（自动经 Homebrew 安装 [`duti`](https://github.com/moretension/duti)，若不可用则给出手动步骤）；安装右键操作。脚本可重复运行。

**前置条件：** macOS 11 或更高版本，已安装 Obsidian。默认回退编辑器为 Typora（可修改，见“自定义与卸载”）。

### 使用

- **双击**库内的 `.md` / `.canvas` / `.base`：在其所属库中打开。
- **库外的 `.md`**：由回退编辑器打开，不干扰代码仓库 README 等非笔记类文件。
- **右键文件夹** → 服务 / 快速操作 → **Open in Obsidian**：作为完整的库打开。
- **在手机上新建的 iCloud 库被导向了错误程序：** 运行一次 `zsh register-vaults.sh` 完成登记。

首次在 Mac 上打开某个新的 iCloud 库时，Obsidian 可能弹出一次“信任作者 / 启用社区插件”的确认，确认即可，仅出现一次。

### 预览渲染（可选）

```bash
brew install --cask qlmarkdown
open -a QLMarkdown        # 首次启动以注册扩展
```

随后在**系统设置 → 通用 → 登录项与扩展 → 快速查看**中启用 QLMarkdown。此后 `.md` 的空格预览即为渲染后的排版。QLMarkdown 支持自定义 CSS，可将预览样式调整至接近所用的 Obsidian 主题。

### 自定义与卸载

- **更换回退编辑器：** 修改 `src/opener.js` 顶部的 `FALLBACK_APP`，重新运行 `zsh install.sh`。
- **卸载：** 运行 `zsh uninstall.sh`，移除打开器、默认程序绑定与右键操作。经 `register-vaults.sh` 登记的库仍保留在 Obsidian 中，可自行在库列表移除。

### 工作原理

打开器是以 `osacompile` 编译的轻量 JXA 应用。接收到文件后，读取 `~/Library/Application Support/obsidian/obsidian.json` 获取全部库路径，按长度降序进行最长前缀匹配（确保 `~/Documents` 等大范围库不会截获更深层库中的文件）；匹配成功则调用 `obsidian://open?path=<URL 编码的绝对路径>`（正确处理中文、空格与括号），否则交由 `open -a <编辑器>`。出错时仅发送通知，而不执行裸 `open`——因其自身即为默认程序，否则会陷入循环调用。

---

## English

### Problem

Managing multiple Obsidian vaults involves two recurring frictions:

1. **No direct open.** When you find a `.md` file inside a vault in Finder, you cannot use it directly: you must launch Obsidian, open the *switch vault* screen, select the vault, and navigate to the file. Double-clicking the file instead hands it to another editor and never reaches Obsidian.
2. **Unreadable preview.** Pressing Space to preview a `.md` shows Markdown source (`#`, `**`, `|`) rather than rendered headings, bold text, and tables.

Multi-device users face a third issue: **iCloud vaults are invisible across devices.** A vault created on an iPhone or iPad is routed to the wrong app on the Mac, because Obsidian's vault registry (`obsidian.json`) is maintained per device and is not synced through iCloud.

### Solution

Three components built on native macOS mechanisms (`obsidian://` URL scheme, LaunchServices, Automator, Quick Look extensions), none of which modify Obsidian itself:

| Component | Function |
|-----------|----------|
| Smart opener `Obsidian Opener.app` | Opens a `.md` / `.canvas` / `.base` inside a vault in its owning vault; a `.md` outside any vault goes to a designated editor (Typora by default). The vault list is read live, so new vaults need no configuration. |
| Right-click action “Open in Obsidian” | Opens any folder as a complete vault. |
| Vault registrar `register-vaults.sh` | Registers, in one command, any iCloud or local folder that is a vault but is not yet known to this Mac, resolving the cross-device visibility issue. |

Rendered previews are provided by the open-source [QLMarkdown](https://github.com/sbarex/QLMarkdown) Quick Look extension (see *Rendered Preview*).

### Value

The tool brings Obsidian vaults into the native macOS file workflow: whether in Finder or a search result, `.md` files can be double-clicked like any other file, removing the repeated “launch app → select vault → locate file” steps required each time you open a note. The improvement is most pronounced for users syncing across a Mac and an iPhone or iPad.

### Installation

```bash
git clone https://github.com/Shaowen-Ye/obsidian-quick-open.git
cd obsidian-quick-open
zsh install.sh
```

`install.sh` builds the opener, sets it as the default handler for `.md` (installing [`duti`](https://github.com/moretension/duti) via Homebrew, or printing manual steps if unavailable), and installs the right-click action. The script is idempotent.

**Requirements:** macOS 11 or later, with Obsidian installed. The default fallback editor is Typora (configurable; see *Customization & Uninstall*).

### Usage

- **Double-click** a `.md` / `.canvas` / `.base` inside a vault to open it in the owning vault.
- **A `.md` outside any vault** opens in the fallback editor, leaving non-note files such as repository READMEs undisturbed.
- **Right-click a folder** → Services / Quick Actions → **Open in Obsidian** to open it as a complete vault.
- **A vault created on your phone is routed to the wrong app:** run `zsh register-vaults.sh` once.

The first time you open a new iCloud vault on the Mac, Obsidian may show a one-time “trust author / enable community plugins” prompt.

### Rendered Preview (Optional)

```bash
brew install --cask qlmarkdown
open -a QLMarkdown        # launch once to register the extension
```

Then enable QLMarkdown under **System Settings → General → Login Items & Extensions → Quick Look**. QLMarkdown supports custom CSS, letting you match the preview to your Obsidian theme.

### Customization & Uninstall

- **Change the fallback editor:** edit `FALLBACK_APP` at the top of `src/opener.js`, then re-run `zsh install.sh`.
- **Uninstall:** run `zsh uninstall.sh` to remove the opener, its default-handler bindings, and the right-click action. Vaults registered by `register-vaults.sh` remain in Obsidian and can be removed from the vault list manually.

### How It Works

The opener is a lightweight JXA application compiled with `osacompile`. On receiving a file, it reads all vault paths from `~/Library/Application Support/obsidian/obsidian.json` and performs a longest-prefix match in descending order of path length, so a broad vault such as `~/Documents` never captures files belonging to a deeper vault. On a match it calls `obsidian://open?path=<url-encoded absolute path>`; otherwise it defers to `open -a <editor>`. On error it posts a notification only, never a bare `open`, which would loop back into itself as the default handler.

---

## License

[MIT](LICENSE) © 2026 Shaowen-Ye
