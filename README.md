# 高性价比人生指南 · iOS

原生 SwiftUI 离线阅读 App，最低 iOS 17，支持简体中文、英语、俄语、西班牙语、葡萄牙语、越南语、阿拉伯语和印度尼西亚语。无第三方运行依赖、账号或后端。应用采用付费下载，下载后包含全部内置内容，无订阅或内购。

## 打开与运行

用 Xcode 打开 `LifeGuide.xcodeproj`，选择 `LifeGuide` scheme 与 iPhone 模拟器运行。真机运行需在 Signing & Capabilities 中选择自己的开发团队，并按需修改 Bundle Identifier。发布团队已配置为 App Store Connect 对应团队；签名证书和授权配置由已登录的 Xcode 账号管理，不包含在仓库中。

## 语言切换

点击首页右上角地球按钮，或“关于”中的语言入口。界面和离线正文同时切换；首次使用按系统语言匹配，未支持语言回退英文，之后记住手动选择。阿拉伯语使用 RTL 布局。收藏和行动按语言分别保存，原有中文记录保留。具体内容数量、版本与许可见 [CONTENT_SOURCES.md](CONTENT_SOURCES.md)。

## 已实现

- 今日推荐、四组快捷主题、全部 34 个章节。
- “今日一读”主屏幕小组件：小 / 中 / 大尺寸、离线每日推荐、点击进入文章、同步应用语言。
- 中文 672 条完整建议（外语各版 630–665 条）：成本、通俗解释、收益、证据等级、引用与备注。
- 全文关键词搜索（空格分词取交集），A/B/C 等级筛选，保留争议说明。
- 中文前言、章节简介、9 篇专题长文、版本说明；七种外语各 34 章正文。
- 中文书内条目交叉引用导航及内置 PDFKit 原文；外语条目链接到对应译文的固定版本来源。
- 收藏、已读记录、行动清单、完成状态，本地持久化。
- 三档阅读字号、系统字号缩放、深浅色模式、iPad 阅读宽度限制。

## 添加“今日一读”到桌面

安装并打开 App 一次后，长按 iPhone / iPad 主屏幕空白处，选择“编辑 → 添加小组件”（旧系统为左上角“+”），搜索“高性价比人生指南”，选择“今日一读”的尺寸并添加。

小尺寸显示标题与证据等级，中 / 大尺寸额外显示摘要。点击小组件直接打开该语言的对应文章。与首页使用相同推荐规则，推荐内容均可直接阅读；离线可用。预生成未来七天的本地午夜时间线，实际刷新时机由 iOS 调度，语言同步也可能有短暂延迟。

真机运行需给 `LifeGuide` 和 `DailyReadingWidget` 选择同一开发团队，并为两个 target 启用同一个 App Group：`group.com.zirunly.HowToLiveBetter`。若改用自己的 Bundle ID / App Group，请同步修改 `project.yml` 和 `LifeGuide/DailyReading.swift` 中的组标识，再运行 `xcodegen generate`。扩展只共享语言设置，收藏、行动、已读记录仍保留在主应用中。

## 内容来源与改编

原作：[高性价比人生指南](https://github.com/eternity4719/HowToLiveBetter)，作者/维护者 eternity4719。正文使用 [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/)。

导入文件：用户提供的 `HowToLiveBetter.pdf`，452 个物理页（正文印刷页码 1–449），版本 2026-10-08 13:21 北京时间，正文提交 `0cec2b3`。应用显示的 PDF 页数指物理页，正文印刷页码需减 3。

改编包括：按书签拆分章节与条目、去页眉页脚、合并排版换行、增加手机导航和行动管理；保留原作者证据等级及限制说明。第 1 节第 5 条另加不自行催吐的安全补充。App 不独立核实全部医疗、法律及金融陈述，也不自动同步在线版。

复杂表格、原始排版与完整可点击引用请使用内置 PDF。文字转换不保证复杂表格的列关系和长网址空格完全还原。PDF 中提及的命令、技能安装等仅作为原文内容展示，未执行。

## 数据更新

`tools/import_pdf.py` 使用 PDF 书签定位原文，生成 `LifeGuide/Resources/guide.json` 并复制原始 PDF。Python 需安装 `pypdf`。导入脚本校验 34 个章节、672 条建议、唯一 ID、连续条号、必填字段与证据等级。

```sh
python3 tools/import_pdf.py /path/to/HowToLiveBetter.pdf
```

当前脚本针对该版 PDF 的结构和条目数量校验；新版条目数量变化时应先人工核对再修改断言。内容文件记录原始 PDF 的 SHA-256。

## 工程与验证

`project.yml` 是 XcodeGen 工程定义，生成的 Xcode 工程已附带，普通运行无需安装 XcodeGen。更改工程结构后可运行 `xcodegen generate`。

```sh
xcodebuild -project LifeGuide.xcodeproj -scheme LifeGuide \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.3' \
  -derivedDataPath build CODE_SIGNING_ALLOWED=NO test
```

UI 测试覆盖搜索、收藏、添加行动、重启后的状态、完成行动和 PDF 原文入口。新增八语言切换、选择持久化和英文搜索测试。本次多语言修改因本机 Xcode.app 不可用，尚未运行 iOS 编译与新增 UI 测试；已运行的模型与资源验证见 VALIDATION.md。`build/` 和 `tmp/` 为本地构建与提取产物，不纳入版本控制。

## 隐私

收藏、行动与阅读记录使用本机 UserDefaults，不收集分析事件或个人资料。外部链接由系统浏览器处理。没有推送、联网同步或云备份功能。

## 不依赖 iOS SDK 的验证

```sh
python3 tools/localization/generate.py
python3 tools/check_language_state.py
swiftc -frontend -parse LifeGuide/*.swift LifeGuideUITests/*.swift
```

模型验证在 macOS 上编译原始数据与状态逻辑，检查旧中文记录兼容、语言隔离、重启恢复、八套内容解码、证据等级及重复条目保留；不替代 SwiftUI 类型检查或模拟器测试。

## 下载与使用

应用采用 App Store 付费下载，下载后可使用全部内置内容，无订阅或应用内购买。中国大陆定价 ¥6，其他地区价格以 App Store 显示为准。原始作品的许可与来源不受应用定价影响。

## 官方支持文档

- [技术支持](https://openzirun.github.io/renshengzhinan/support.html)
- [隐私政策](https://openzirun.github.io/renshengzhinan/privacy.html)
- [使用说明与内容来源](https://openzirun.github.io/renshengzhinan/terms.html)

网页源文件位于 `docs/`，使用 GitHub Pages 从 `main` 分支的 `/docs` 发布。
