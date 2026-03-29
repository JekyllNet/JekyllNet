<p align="center">
  <img src="docs/assets/brand/jekyll-net-lockup.svg" alt="JekyllNet" width="360">
</p>

# JekyllNet ✨

一个用 C# 编写的 Jekyll 风格静态站点生成器，目标是逐步靠近 GitHub Pages 行为。

路线图见：

`ROADMAP.md`

变更记录见：

`CHANGELOG.md`

GitHub 头像建议使用：

`docs/assets/brand/jekyll-net-avatar.svg`

## 🤖 Agent 执行约束

为了保证仓库内自动化行为一致，所有智能体在本仓库内必须遵循以下规则：

- 仅允许使用 `C#` 与 `.NET 10` 编写和执行工具。
- 禁止使用 `PowerShell`（含 `ps` / `pwsh`）实现构建、测试、发布或辅助自动化。
- 禁止使用其他语言或方式编写工具脚本（例如 Python、Node.js、Shell）。
- 如确实需要超出以上约束，必须先在文档或 PR 中明确说明原因并获得维护者批准。

## 🚀 当前能力

- ✨ `.NET 10`
- ✨ `build` 命令
- ✨ `_config.yml`
- ✨ YAML Front Matter
- ✨ Markdown 转 HTML
- ✨ `_layouts` 与嵌套 layout
- ✨ `_includes`
- ✨ `_data`
- ✨ `_posts`
- ✨ `collections`
- ✨ `tags/categories`
- ✨ 基础 Liquid 标签与常见 filters
- ✨ `drafts / future / unpublished` 开关
- ✨ `excerpt_separator`
- ✨ static files 的 front matter / defaults
- ✨ basic pagination
- ✨ `_config.yml defaults` 基础支持
- ✨ Sass/SCSS 编译
- ✨ 静态资源复制到 `_site`
- ✨ AI 驱动的多语言内容翻译基础管线
- ✨ OpenAI / DeepSeek / Ollama 的 OpenAI-compatible 翻译接入

## ⚡ 快速开始

在仓库根目录执行：

`dotnet run --project .\JekyllNet.Cli -- build --source .\sample-site`

如需把草稿、未来文章和未发布内容一起包含进来：

`dotnet run --project .\JekyllNet.Cli -- build --source .\sample-site --drafts --future --unpublished`

生成结果位于：

`sample-site\_site`

## 🛠️ 本地开发

启动本地静态站点服务并自动监听改动：

`dotnet run --project .\JekyllNet.Cli -- serve --source .\docs`

只监听改动并持续重建：

`dotnet run --project .\JekyllNet.Cli -- watch --source .\sample-site`

常用 CLI 开关：

- 🔧 `--drafts`
- 🔧 `--future`
- 🔧 `--unpublished`
- 🔧 `--posts-per-page <number>`
- 🔧 `serve` 命令额外支持 `--host <host>`、`--port <port>`、`--no-watch`

示例：

`dotnet run --project .\JekyllNet.Cli -- serve --source .\docs --port 5000`

## ✅ 回归命令

运行完整测试与站点构建回归验证：

`dotnet test .\JekyllNet.slnx`

运行 5 主题并行构建 + 浏览器错误检查（C# 工具实现）：

`dotnet run --project .\scripts\JekyllNet.ReleaseTool -- test-theme-matrix --max-parallelism 5`

说明：

- 会并行构建 `jekyll-theme-chirpy`、`minimal-mistakes`、`al-folio`、`jekyll-TeXt-theme`、`just-the-docs`
- 会启动无头浏览器检查控制台/运行时/网络错误
- 会输出每个主题的构建耗时与总耗时

## 📦 dotnet tool

仓库已经带上 `dotnet tool` 打包元数据，命令名为：

`jekyllnet`

本地打包：

`dotnet pack .\JekyllNet.Cli\JekyllNet.Cli.csproj -c Release`

从本地包目录全局安装：

`dotnet tool install --global JekyllNet --add-source .\artifacts\nupkg`

升级：

`dotnet tool update --global JekyllNet --add-source .\artifacts\nupkg`

卸载：

`dotnet tool uninstall --global JekyllNet`

安装后可直接执行：

`jekyllnet build --source .\sample-site`

## 🤖 GitHub Actions 与分发

仓库现在同时提供：

- 📄 `action/` 子模块，承载独立的 JekyllNet GitHub Action 仓库
- 📄 `.github/workflows/ci.yml`
- 📄 `.github/workflows/github-pages.yml`
- 📄 `.github/workflows/publish-dotnet-tool.yml`
- 📄 `.github/workflows/release-artifacts.yml`

用途：

- ⚙️ `action/`：独立维护的 GitHub Action 仓库，可在任意仓库中复用
- ⚙️ `ci.yml`：测试、通过 CLI 构建 `docs` / `sample-site`、打包 dotnet tool
- ⚙️ `github-pages.yml`：当 `docs` 或站点生成器相关代码变化时，构建 `docs` 并发布到 GitHub Pages
- ⚙️ `publish-dotnet-tool.yml`：将 `JekyllNet` 作为 dotnet tool 包发布到 NuGet
- ⚙️ `release-artifacts.yml`：生成 `nupkg`、Windows portable zip、SHA256 与已填充的 `winget` manifests，并在 tag 发布时同步挂到 GitHub Release

最小 workflow 示例：

```yml
name: build-site

on:
  push:
  pull_request:
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v5

      - name: Build docs with JekyllNet
        uses: JekyllNet/action@main
        with:
          source: ./docs
          destination: ./artifacts/docs-site
          upload-artifact: "true"
          artifact-name: docs-site
```

当前仓库尚未打出专门的 action tag，因此示例先使用 `@main`；待首个 action release 发布后，建议改为固定版本 tag。

如果是在本仓库发布 `docs` 到 GitHub Pages，可直接启用：

- `.github/workflows/github-pages.yml`

该 workflow 会：

- 在 `main` 分支收到 `docs/**`、`JekyllNet.Cli/**`、`JekyllNet.Core/**`、`JekyllNet.slnx` 或工作流自身变更时自动触发
- 在 PR 中执行构建校验，但不实际部署
- 在推送到 `main` 后把 `./artifacts/docs-site` 发布到 GitHub Pages

常用输入：

- `source`
- `destination`
- `drafts`
- `future`
- `unpublished`
- `posts-per-page`
- `dotnet-configuration`
- `upload-artifact`
- `artifact-name`

发布 dotnet tool 到 NuGet 可直接使用：

- `.github/workflows/publish-dotnet-tool.yml`

该 workflow 会：

- 在推送 `v*` tag 时自动触发，并以 tag 去掉前导 `v` 后的值作为包版本
- 在手动触发时使用输入的 `version`
- 先执行 `dotnet test`
- 再执行 `dotnet pack`，并同时发布到 `https://api.nuget.org/v3/index.json` 与 GitHub Packages
- 向 NuGet.org 发布时使用仓库 secret `NUGET_API_KEY`
- 向 GitHub Packages 发布时使用 `GITHUB_TOKEN`

示例：

- 推送 tag `v0.1.1`
- workflow 会把 `JekyllNet` `0.1.1` 同时发布到 NuGet.org 和 `https://nuget.pkg.github.com/JekyllNet/index.json`

生成 GitHub Release 资产与 `winget` manifests 可直接使用：

- `.github/workflows/release-artifacts.yml`

该 workflow 会：

- 在推送 `v*` tag 时自动触发，也支持手动触发
- 统一要求 `0.1.1` 这类三段式版本号；若手动触发且未填 `version`，则回退到 `JekyllNet.Cli.csproj` 中的版本
- 先执行 `dotnet test`
- 再生成 `nupkg`、`JekyllNet-win-x64.zip` 与 `SHA256SUMS.txt`
- 基于 `packaging/winget/templates/*` 自动产出可提交的 `winget` manifests
- 在 tag 触发时，把 zip、checksum、NuGet 包和 `winget` manifests 一并挂到 GitHub Release

示例：

- 推送 tag `v0.1.0`
- workflow 会创建或更新对应 GitHub Release
- Release 会附带 `JekyllNet-win-x64.zip`
- Release 会附带 `SHA256SUMS.txt`
- Release 会附带 `artifacts/winget/JekyllNet.JekyllNet/0.1.0/*.yaml`

## 🪄 winget

仓库已补上 `winget` 模板与提交流程说明：

- 📄 `packaging/winget/README.md`
- 📄 `scripts/JekyllNet.ReleaseTool/`

当前状态：

- 📦 仓库已经具备 `winget` 清单模板、Windows portable 发布物流程，以及自动填充 manifest 的脚本
- 📝 真正提交社区源前，还需要把生成出的 manifests 送去 `winget validate` / `wingetcreate validate`，然后提交到社区源

## 🌍 AI 翻译配置

在 `_config.yml` 中配置 `ai.translate.targets` 后，构建时会为 Markdown 内容自动生成目标语言页面。

```yml
lang: zh-CN
ai:
  provider: openai
  model: gpt-5-mini
  api_key_env: OPENAI_API_KEY
  translate:
    targets:
      - en
      - fr
    front_matter_keys:
      - title
      - description
    glossary: _i18n/glossary.yml
    cache_path: .jekyllnet/translation-cache.json
```

内置快捷 provider：

- 🤖 `openai`
- 🤖 `deepseek`
- 🤖 `ollama`

也支持任意 OpenAI-compatible 第三方服务商，只要配置：

```yml
ai:
  provider: siliconflow
  base_url: https://api.example.com
  model: your-model
  api_key_env: THIRD_PARTY_API_KEY
  translate:
    targets: [fr, ja]
```

默认行为：

- 🌐 只自动翻译 Markdown 内容文件
- 🌐 自动翻译 `title`，可通过 `ai.translate.front_matter_keys` 扩展
- 🌐 输出 URL 会自动按目标语言前缀生成，例如 `/fr/.../`
- 🌐 页脚法务标签会按页面语言切换；对非中英文目标语言，会优先尝试用 AI 自动翻译标签
- 🌐 会自动为同一路径的多语言页面生成 `translation_links`
- 🌐 默认启用翻译缓存，未变化的文本会直接复用，避免每次 build 全量请求模型
- 🌐 `ai.translate.cache_path` 可覆盖缓存文件位置，`ai.translate.cache: false` 可关闭缓存
- 🌐 `ai.translate.glossary` 可提供术语表，保证品牌词、专有名词、多语言固定译法更稳定

glossary 文件示例：

```yml
terms:
  JekyllNet: JekyllNet
  GitHub Pages:
    fr: Pages GitHub
    ja: GitHub Pages
```

## 🧭 当前限制

当前还是增强中的兼容层，暂未完整支持：

- ⏳ 更完整的 pagination 兼容行为
- ⏳ 更完整 Liquid 语法与 filters 全覆盖
- ⏳ `assign` 作用域 / include 渲染顺序等更完整 Liquid 语义
- ⏳ data JSON 结构化解析增强
- ⏳ Sass 管道与 Jekyll 细节完全对齐
- ⏳ GitHub Pages 固定版本与插件行为 1:1 兼容

## 🎨 Sass/SCSS 编译

JekyllNet 支持 Sass/SCSS 文件自动编译为 CSS。**重要：Sass 入口文件必须包含 YAML Front Matter 头**，以启用编译。

示例 Sass 文件结构：

```scss
---
---
// 此处开始编写 Sass/SCSS
$primary-color: #333;

body {
  color: $primary-color;
}
```

- 📄 Front Matter 可以为空（`---\n---`）
- 📄 支持 `@import` 引入其他 Sass 文件
- 📄 编译输出会放在 `_site/` 对应路径下，扩展名改为 `.css`

示例：

- 输入：`assets/scss/style.scss`
- 输出：`_site/assets/css/style.css`

## 📋 CLI 日志输出

JekyllNet CLI 提供结构化、易读的输出格式，包括 emoji 状态指示和智能时间格式化。

### 构建完成示例

```
✅ Build complete: D:\projects\my-site (elapsed 00:00:02.542)
```

### 监听模式示例

```
👀 Watching for changes in D:\projects\my-site
📝 Change detected: _posts\2024-01-01-post.md
✅ Build complete (elapsed 00:00:01.234)
📝 Change detected: _config.yml
✅ Build complete (elapsed 00:00:03.456)
```

### 服务模式示例

```
🚀 Starting server at http://localhost:4000
👀 Watching for changes
📝 Change detected: index.md
✅ Rebuild complete (elapsed 00:00:00.789)
```

### 日志标记含义

- ✅ 成功完成
- ❌ 失败或错误
- 🚀 启动或开始
- 👀 监听或观察
- 📝 文件变更

### 时间格式化

- 小于 1 秒：`123 ms`
- 1 秒到 59 秒：`2.5 s`
- 1 分钟及以上：`01:23` (分:秒)

## 🔧 安装与使用

### 系统要求

- `.NET 10` SDK 或更高版本
- Windows / macOS / Linux

### 从源代码本地安装

```bash
# 克隆仓库
git clone https://github.com/JekyllNet/JekyllNet.git
cd JekyllNet

# 本地打包
dotnet pack .\JekyllNet.Cli\JekyllNet.Cli.csproj -c Release

# 从本地源安装为全局工具
dotnet tool install --global JekyllNet --add-source .\artifacts\nupkg

# 或升级现有版本
dotnet tool update --global JekyllNet --add-source .\artifacts\nupkg
```

### 使用全局 dotnet tool

```bash
# 构建站点
jekyllnet build --source ./my-site

# 启动本地服务
jekyllnet serve --source ./my-site --port 4000

# 监听改动
jekyllnet watch --source ./my-site --drafts
```

### 从本仓库运行

```bash
# 构建
dotnet run --project .\JekyllNet.Cli -- build --source .\sample-site

# 服务
dotnet run --project .\JekyllNet.Cli -- serve --source .\docs

# 监听
dotnet run --project .\JekyllNet.Cli -- watch --source .\sample-site --drafts
```

## 🐛 故障排除

### Sass 编译失败：文件未生成

**症状**：`_site/` 中看不到 `.css` 文件

**解决方案**：确保 Sass 入口文件包含 YAML Front Matter：

```scss
---
---
$color: red;
body { color: $color; }
```

### 构建卡住或缓慢

**可能原因**：
- 大量 AI 翻译请求
- 网络连接问题
- 大型 Markdown 文件集合

**解决方案**：
- 使用 `--no-ai` 或关闭 `_config.yml` 中的 AI 翻译
- 检查网络连接
- 考虑使用 `--drafts false` 排除草稿

### 404 或路由错误

**可能原因**：
- Permalink 配置不正确
- URL 首位缺少 `/`

**检查**：
- 验证 `_config.yml` 中的 `url` 和 `baseurl`
- 检查 front matter 中的 `permalink` 配置

### 模板渲染错误

**症状**：Liquid 变量未取值或条件语句失效

**检查清单**：
1. 验证变量拼写与作用域（全局 vs 页面 vs 循环）
2. 检查 `includes` 路径是否正确
3. 测试 Liquid `debug` filter：`{{ variable | debug }}`

## 📝 贡献指南

欢迎提交 Issue 和 Pull Request！

### 开发流程

1. **Fork** 此仓库
2. **创建特性分支**：`git checkout -b feature/your-feature`
3. **在本地验证**：
   ```bash
   dotnet test .\JekyllNet.slnx
   dotnet run --project .\scripts\JekyllNet.ReleaseTool -- test-theme-matrix
   ```
4. **提交 PR**，描述改动内容和测试验证方式

### 代码风格

- 遵循 [C# 编码标准](https://docs.microsoft.com/en-us/dotnet/csharp/fundamentals/coding-style/coding-conventions)
- 使用 `.NET 10` 特性（records、pattern matching 等）
- 添加单元测试覆盖新功能

### 测试要求

- 所有新功能必须包含单元测试
- 运行 `dotnet test .\JekyllNet.slnx` 确保无失败
- 如涉及主题兼容性，运行 5 主题矩阵测试

### 文档更新

- 更新 `CHANGELOG.md`：在合并前添加条目
- 更新 `ROADMAP.md`：如涉及阶段进展
- 更新 `README.md`：如新增功能或改变行为

### 提交信息格式

推荐使用清晰的提交信息：

```
feat: add Sass compilation support
fix: resolve pagination edge case
docs: update README with CLI examples
```

## 📄 许可证

此项目采用 [MIT License](LICENSE)。

## 🔗 链接

- 📚 文档：https://jekyllnet.help
- 🐛 Issue 追踪：https://github.com/JekyllNet/JekyllNet/issues
- 📢 Discussions：https://github.com/JekyllNet/JekyllNet/discussions
