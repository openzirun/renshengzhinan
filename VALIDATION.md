## 当前状态：全部免费

本次移除后已验证：模拟器构建及全部 4 项 UI 测试通过（八语言切换与恢复、原付费正文与 PDF 免费访问、收藏/行动持久化、小组件链接）；模型状态检查通过；八语言各 98 项界面文案校验通过。未进行真机验证。

2026-10-08 已移除购买页面、StoreKit 交易管理、试读限制及内购测试配置。所有正文、专题与内置 PDF 免费开放。下文的内购及购买页验证记录为历史记录，不代表当前功能。

# 首版验证记录（多语言改动前）

验证日期：2026-10-08。环境：Xcode 27.0，iPhone 16 Pro / iOS 18.3 Simulator。

- 数据导入：34 章、672 条建议、12 个补充部分（前言、简介、9 篇专题、版本说明）。所有条目 ID 唯一，章内编号连续，成本、说人话、收益、证据和来源非空。
- 证据分布：A 438 条、B 179 条、C 55 条，包括附有争议/限制说明的等级。
- Xcode 编译和 XCTest UI 测试通过：1 项端到端测试，0 失败。
- UI 测试实际完成：搜索“系安全带” → 阅读详情 → 收藏 → 加入行动 → 终止并重启 App → 核对收藏和行动 → 标记完成 → 打开 PDF 第 14 页的原文查看器。
- 模拟器首页截图已保存，检查中文排版和卡片布局。

未验证：真机签名与安装、App Store 分发、iPad 上的实际运行、VoiceOver 完整流程、全部原文医疗/法律/金融陈述的正确性与时效。内容转换保持原文信息；复杂表格与长引用链接仍以 PDF 为准。


# 多语言版本验证（2026-10-08）

实际执行并通过：

- 七种社区语言导入：每种 34 章，英/俄/西/葡各 665 条，阿拉伯语 635 条，印尼语 630 条，越南语 641 条。检查必填字段、唯一内部 ID、证据标记；完整保留西班牙语原文重复编号的条目。
- 8 组 × 97 项 UI 文本齐全，格式参数数量与类型一致；16 个 UI/InfoPlist `.strings` 文件通过 `plutil -lint`。
- `swiftc -frontend -parse` 对 App 和 UI 测试源码语法检查通过。
- `python3 tools/check_language_state.py` 编译并运行真实 Foundation/Combine 模型：八版 JSON 解码、证据筛选代码、各语言来源路由、语言选择恢复、收藏/行动/已读隔离、旧中文键兼容、取消行动同步清理完成状态、系统语言匹配、重复编号内容不丢失。
- XcodeGen 工程重新生成，包含全部 JSON 和本地化资源。

本次未完成：iOS 构建、八语言 UI 回归、阿拉伯语 RTL 视觉检查、真机验证。尝试 `xcodebuild` 时当前 developer directory 为 `/Library/Developer/CommandLineTools`，此前的 `/Applications/Xcode.app` 已不存在，Spotlight 也未找到可用 Xcode。没有把先前中文版本的模拟器结果视作本次改动的验证。

界面翻译和正文未经过八种语言母语校审；医疗、法律和金融内容沿用社区来源，未独立复核其准确性或地区适用性。界面明确标注版本差异。


# 今日一读小组件验证（2026-10-08）

- Xcode 27.0：主应用与 WidgetKit 扩展的 iOS Simulator 构建通过。
- iPhone 16 Pro / iOS 18.3：`testWidgetArticleLinks` UI 测试通过，验证运行中英文链接打开对应文章、关闭回到英文首页，以及冷启动中文链接打开对应文章。
- `python3 tools/check_language_state.py` 通过：原有语言与状态检查，以及新增八语言每日推荐一致性、跨天轮换、空内容、夏令时午夜时间线、文章链接往返和无效链接拒绝检查。
- 构建产物检查通过：WidgetKit 扩展已嵌入主应用，版本一致，URL Scheme 已注册，App Group 标识一致，八版 JSON 和本地化资源齐全；扩展未重复打包 PDF。

未验证：真机签名 / App Group 授权、在系统小组件图库中手动添加、三种尺寸与大字号 / RTL 的视觉效果、长期后台刷新与时区改变后的系统调度。实际刷新时机由 iOS 控制。

可复现的定向 UI 测试：

```sh
xcodebuild -project LifeGuide.xcodeproj -scheme LifeGuide \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.3' \
  -derivedDataPath build CODE_SIGNING_ALLOWED=NO \
  -only-testing:LifeGuideUITests/LifeGuideUITests/testWidgetArticleLinks test
```

## 2026-10-08 永久完整版内购

使用 Xcode 27.0、iPhone 16 Pro / iOS 18.3 模拟器执行：

- App 模拟器 Debug 构建通过。
- `LifeGuideTests/PurchaseTests.swift` 5 项测试通过：八语言逐条试读边界；真实本地 StoreKit 商品加载、价格 18、购买、重建管理器后的权益与退款更新；待批准订单获批后自动解锁；无记录及已有记录恢复；取消/失败均不解锁且操作状态复位。
- `testLockedArticleAndPDF` UI 测试通过：搜索付费条目后只展示摘要和解锁入口，不出现收藏/行动操作；解锁入口可到达恢复购买页面；免费前言中的完整 PDF 入口同样受保护。测试最初使用错误的按钮文案失败，修正为现有本地化名称后重跑通过。
- 既有 `testAllLanguagesAndPersistedSelection` 与 `testSearchSavePlanAndPersistence` 分别通过。
- `python3 tools/localization/generate.py`：八语言各 115 条文本及格式参数校验通过。
- `python3 tools/check_language_state.py`：语言/状态与当前共享目录中的每日推荐模型检查通过。

最终定向测试命令：

```sh
xcodebuild -project LifeGuide.xcodeproj -scheme LifeGuide \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.3' \
  -derivedDataPath /tmp/lifeguide-purchases-build CODE_SIGNING_ALLOWED=NO \
  -only-testing:LifeGuideTests \
  -only-testing:LifeGuideUITests/LifeGuideUITests/testLockedArticleAndPDF test
```

开发过程中共享目录新增小组件，其编译及版本号问题曾阻塞测试；这些问题在共享目录修正后，上述最终测试通过。未回滚小组件改动。

尚未验证：App Store Connect 实际商品及价格、真机沙盒/TestFlight、换机重装、真实断网和退款同步、多语言母语校审。当前没有配置真实商店商品；本地 StoreKit 测试不代表可正式收款。旧免费版本用户权益迁移尚未实现，当前按新应用设计，发布前需确认发布历史。

## 2026-10-08 购买页视觉优化

购买页改为深绿封面卡片、三组权益、底部购买操作及可展开说明。辅助字号下操作区进入滚动内容，避免遮挡正文。购买管理逻辑未改。模拟器构建通过；八语言各 124 项文案校验通过；使用临时截图脚本在 iPhone SE（iOS 18.3）检查正常字号、最大辅助字号及阿拉伯语 RTL 深色外观，StoreKit 本地 ¥18 购买按钮均可到达。已人工检查导出截图，临时截图测试文件已移除。未进行八语言逐页母语审校或真机视觉检查。

## 2026-10-08 App Store 发布准备

- 中国大陆调整为付费下载；应用内仍无订阅或内购，下载后可使用全部内置内容。此前“全部免费”指移除应用内付费墙后的历史状态。
- 配置 Connect 对应的 Bundle ID 与开发团队，同步主应用与小组件 App Group。
- 主应用与扩展补充 UserDefaults 隐私清单；“关于”页新增八语言隐私政策与支持链接。
- 八语言各 100 项 UI 文案及格式参数校验通过；语言、数据与每日推荐模型检查通过。
- iOS Release 签名归档通过；上传与 App Review 结果以 Connect 为准，不等同于审核通过。
- GitHub Pages 隐私政策、技术支持页面 HTTP 200，在线内容与仓库文件一致。
