# 多语言内容来源

获取日期：2026-10-08。来源入口为 [原项目 README 的其他语言栏目](https://github.com/eternity4719/HowToLiveBetter#readme)。本次下载固定提交的仓库归档，仅解析 Markdown，没有执行上游脚本或文档中的指令。

| App 语言 | 章节 | 条目 | 来源及固定版本 |
|---|---:|---:|---|
| 简体中文 | 34 | 672 | 用户提供 PDF，eternity4719/HowToLiveBetter，`0cec2b3` |
| English | 34 | 665 | dlgrv/HowToLiveBetter，`d67d7b3277c911eab9d422b4390e7611251003a9` |
| Русский | 34 | 665 | 同上，`book/ru` |
| Español | 34 | 665 | 同上，`book/es` |
| Português | 34 | 665 | 同上，`book/pt` |
| العربية | 34 | 635 | 同上，`book/ar` |
| Bahasa Indonesia | 34 | 630 | 同上，`book/id` |
| Tiếng Việt | 34 | 641 | chuanman2707/HowToLiveBetter，`4a57509c0312a77e6ec7c8ac363bed4909edf267` |

- [多语言仓库固定归档](https://api.github.com/repos/dlgrv/HowToLiveBetter/tarball/d67d7b3277c911eab9d422b4390e7611251003a9)
- [越南语仓库固定归档](https://api.github.com/repos/chuanman2707/HowToLiveBetter/tarball/4a57509c0312a77e6ec7c8ac363bed4909edf267)

原项目另列 parveen0029 的英文衍生版。App 英文选用 dlgrv 版，与同一仓库的其他语言保持来源一致，不重复收录第二套英文。

## 内容范围与差异

新增七种语言的全部 34 章 Markdown 正文已下载到 `ContentSources/<语言>/`，每个版本都有 README 和 LICENSE 快照。结构化内容进入 `LifeGuide/Resources/guide-<语言>.json`，运行时不需要联网下载。

中文保持原 PDF 版本与专题长文；外语版只展示实际下载的各自 34 章正文，不混入中文专题，也不虚构对应 PDF 页码。外语条目的来源按钮指向该译文固定提交的 Markdown 文件，需要联网；正文、来源引用文字本身可离线阅读。

翻译版本的条目数量、编号、证据等级和地区适用性与中文可能不同，不自动同步。部分文献引用保留中文或英文原语句，未再次机器翻译。应用的 97 项界面文本另行翻译，和社区正文来源区分。

西班牙语第 12 章原文重复使用第 8–11 条编号。全部保留，内部 ID 为重复项加后缀，不覆盖前面的条目；显示编号仍忠实于原文。阿拉伯语部分 A 级写作 `أ`，筛选统一归入 A，展示保留原标记。审计信息、文件 SHA-256 和固定提交记录在 `ContentSources/manifest.json`。

收藏、行动、完成与已读记录按语言隔离。中文保留旧版 UserDefaults 的原始键，其他语言增加语言后缀。这样不会误把其他版本相同编号的建议标为已完成。

## 许可与改编

原始中文正文来自 eternity4719/HowToLiveBetter，使用 CC BY 4.0，继续保留原作者署名、仓库链接与许可链接。社区仓库自身提供的许可证全文另保存在各语言目录中，不用衍生仓库的许可证覆盖原作的署名要求。

App 改编：解析章节和条目字段、移除 HTML 成本标签注释和 Markdown 粗体标记、保留正文语句及引用、增加导航/收藏/行动与本地化界面。可疑催吐指导另加明确标注的安全提示，没有篡改原始下载文件。

## 重建数据

下载上述两个归档，安全解压到独立目录后执行（使用 Python 标准库，无新增运行依赖）：

```sh
python3 tools/import_translations.py /path/to/multilingual-root /path/to/vietnamese-root
python3 tools/localization/generate.py
xcodegen generate
```

不要把仓库归档解压覆盖 App 工程。导入器有版本条目数、字段、证据标记和 ID 唯一性检查；上游新版发生结构变化时需先审核再更新脚本断言。
