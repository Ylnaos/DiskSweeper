# 磁盘清道夫 · DiskSweeper

> 一个简单、安全、原生的 macOS 磁盘清理小工具。
> A simple, safe, native macOS disk‑cleanup utility built with SwiftUI.

扫描大文件、一键清理可安全回收的缓存——**只动该动的，绝不碰你的数据**。

## ✨ 功能

- **安全清理**：内置一份精心挑选的「可安全清理」清单（用户缓存、Xcode 派生数据、用户日志、废纸篓、npm / Gradle 缓存等）。复选框勾选 + 全选，一键清理。
- **大文件扫描**：按阈值（100 MB / 500 MB / 1 GB / 5 GB）扫描主目录下的大文件，列表展示，可在 Finder 中定位或移到废纸篓。
- **两种删除方式**：默认「移到废纸篓」（可恢复），可一键切换为「永久删除」。
- **删除前确认**：每次清理都会列出清单与合计大小，二次确认；永久删除会额外警示。

## 🔒 安全设计

清理工具最怕误删，所以它的安全边界是写死的：

- 只删除清单里那些**目录的内容**，从不删除目录本身，也从不触碰清单以外的任何路径。
- `CleanEngine.isSafe` 在删除前会解析符号链接并强制校验：**任何目标都必须位于你的主目录（`$HOME`）之内**，否则直接拒绝。
- 默认走废纸篓，可恢复。
- **故意排除** `~/.cache/uv`（常被运行中的命令行工具占用）以及「应用程序支持 / 下载 / 文稿」等一切用户数据目录——它们永远不会出现在清理列表里。

## 🖥 系统要求

- macOS 14 (Sonoma) 及以上
- 非沙盒运行（清理工具需要读取其它 App 的缓存目录）

## 🚀 下载使用

前往 [Releases](../../releases) 下载最新的 `DiskSweeper.app.zip`，解压后拖到「应用程序」。

> 这是一个未做苹果公证的开源应用，首次打开会被 Gatekeeper 拦截。请 **右键点按 App → 打开**，或在终端执行：
> ```bash
> xattr -dr com.apple.quarantine /Applications/DiskSweeper.app
> ```

## 🛠 从源码构建

本项目用 [XcodeGen](https://github.com/yonaskolb/XcodeGen) 管理工程，`project.yml` 是唯一事实来源。

```bash
git clone https://github.com/Ylnaos/DiskSweeper.git
cd DiskSweeper

# 方式一：直接打开已生成的工程，在 Xcode 里按 ⌘R 运行
open DiskSweeper.xcodeproj

# 方式二：用 XcodeGen 重新生成工程
brew install xcodegen
xcodegen generate
```

命令行编译（若 `xcode-select` 指向的是 Command Line Tools 而非 Xcode.app）：

```bash
env DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcodebuild -project DiskSweeper.xcodeproj -scheme DiskSweeper -configuration Release build
```

## ⚠️ 注意事项

- **首次扫描大文件**时，macOS 可能弹窗请求访问「文稿 / 桌面 / 下载」等目录，点允许即可。
- **移到废纸篓不会立刻释放空间**——需清空废纸篓后才真正释放（或在 App 内改用「永久删除」）。

## 📦 项目结构

```
Sources/
  Models.swift        # 安全清理清单（数据驱动）+ 数据模型
  Shell.swift         # 子进程封装（du 计算体积）
  ScanEngine.swift    # 体积扫描 + 大文件枚举（FileManager）
  CleanEngine.swift   # 删除逻辑 + 越界防护
  AppModel.swift      # 状态与动作（ObservableObject）
  *View.swift         # SwiftUI 界面
project.yml           # XcodeGen 工程定义
```

## 📄 许可证

[MIT](LICENSE) © 2026 Ylnaos
