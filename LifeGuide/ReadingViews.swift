import SwiftUI
import PDFKit

struct BrowseView: View {
    @EnvironmentObject private var library: Library
    @State private var query = ""
    @State private var evidence = "all"
    var results: [Article] {
        let words = query.split(whereSeparator: \.isWhitespace).map(String.init)
        return library.articles.filter { article in
            (evidence == "all" || article.evidenceCode == evidence) && words.allSatisfy { article.searchableText.localizedStandardContains($0) }
        }
    }
    var body: some View {
        List {
            Section {
                Picker(library.text("evidenceFilter"), selection: $evidence) {
                    Text(library.text("all")).tag("all")
                    ForEach(["A", "B", "C"], id: \.self) { Text($0).tag($0) }
                }.pickerStyle(.segmented)
                Text(library.text("evidenceHint")).font(.caption).foregroundStyle(.secondary)
            }
            if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && evidence == "all" {
                Section(library.text("topicCount", library.guide?.chapters.count ?? 0)) {
                    ForEach(library.guide?.chapters ?? []) { chapter in
                        NavigationLink { ChapterView(chapter: chapter) } label: { ChapterRow(chapter: chapter) }
                    }
                }
                if !(library.guide?.extras.isEmpty ?? true) {
                    Section(library.text("supplements")) {
                        ForEach(library.guide?.extras ?? []) { extra in
                            NavigationLink(extra.title) { SupplementView(supplement: extra) }
                        }
                    }
                }
            } else {
                Section(library.text("resultCount", results.count)) {
                    ForEach(results) { article in
                        NavigationLink { ArticleView(article: article) } label: { ArticleRow(article: article) }
                    }
                    if results.isEmpty { ContentUnavailableView(library.text("noResults"), systemImage: "magnifyingglass", description: Text(query)) }
                }
            }
        }.navigationTitle(library.text("guideTitle"))
            .searchable(text: $query, prompt: library.text("search"))
            .scrollContentBackground(.hidden).background(Theme.paper)
    }
}

struct ChapterView: View {
    @EnvironmentObject private var library: Library
    let chapter: Chapter
    var body: some View {
        List {
            Section {
                Label(library.text("chapterNumber", chapter.id), systemImage: chapter.symbol).foregroundStyle(Theme.accent).font(.subheadline)
                Text(chapter.title).font(.title2.bold())
                DisclosureGroup(library.text("intro")) { Text(chapter.intro).font(.subheadline).lineSpacing(5).textSelection(.enabled) }
            }
            Section(library.text("originalOrder")) {
                ForEach(library.articles.filter { $0.chapterID == chapter.id }) { article in
                    NavigationLink { ArticleView(article: article) } label: { ArticleRow(article: article) }
                }
            }
        }.navigationTitle(library.text("topicGuide")).navigationBarTitleDisplayMode(.inline)
            .scrollContentBackground(.hidden).background(Theme.paper)
    }
}

struct ArticleView: View {
    @EnvironmentObject private var library: Library
    @AppStorage("readerSize") private var readerSize = 17.0
    @ScaledMetric(relativeTo: .body) private var fontScale = 1.0
    let article: Article
    var references: [Article] {
        guard library.language == .chinese else { return [] }
        let regex = try? NSRegularExpression(pattern: "第\\s*(\\d+)\\s*节第\\s*(\\d+)\\s*条")
        let text = article.searchableText as NSString
        var ids = Set<String>()
        return (regex?.matches(in: text as String, range: NSRange(location: 0, length: text.length)) ?? []).compactMap { match in
            let id = "\(text.substring(with: match.range(at: 1)))-\(text.substring(with: match.range(at: 2)))"
            guard id != article.id, ids.insert(id).inserted else { return nil }
            return library.articles.first { $0.id == id }
        }
    }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text(library.text("articleNumber", article.chapterID, article.number))
                    .font(.system(.caption, design: .monospaced)).foregroundStyle(Theme.accent)
                Text(article.title).font(.system(.title, design: .serif, weight: .bold))
                HStack {
                    Text(library.text("evidenceValue", article.evidence)).font(.caption.bold()).padding(8).background(Theme.accent.opacity(0.09), in: Capsule())
                    if article.page > 0 { Text(library.text("pdfPage", article.page)).font(.caption).foregroundStyle(.secondary) }
                }
                VStack(alignment: .leading, spacing: 12) {
                    Label(library.text("plain"), systemImage: "text.bubble").font(.subheadline.bold()).foregroundStyle(Theme.accent)
                    Text(article.summary).font(.system(size: (readerSize + 1) * fontScale)).lineSpacing(7)
                }.padding(20).frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.accent.opacity(0.07), in: RoundedRectangle(cornerRadius: 20))
                if article.chapterID == 13 {
                    Text(library.text("emergencyNotice"))
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                block(library.text("cost"), symbol: "clock", text: article.cost)
                block(library.text("benefit"), symbol: "chart.line.uptrend.xyaxis", text: article.benefit)
                if !article.notes.isEmpty { block(library.text("notes"), symbol: "info.circle", text: article.notes) }
                if article.id == "1-5" {
                    Text(library.text("poisonNotice"))
                        .font(.system(size: readerSize * fontScale)).padding(16).background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                }
                DisclosureGroup {
                    Text(article.sources).font(.system(size: (readerSize - 2) * fontScale)).lineSpacing(5).textSelection(.enabled).padding(.top, 10)
                    if article.page == 0 {
                        Text(library.text("translationHint"))
                            .font(.caption).foregroundStyle(.secondary).padding(.top, 8)
                    }
                } label: { Label(library.text("sources"), systemImage: "doc.text.magnifyingglass").font(.headline) }
                if !references.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(library.text("references")).font(.headline)
                        ForEach(references) { related in
                            NavigationLink { ArticleView(article: related) } label: {
                                HStack { Text(related.title).font(.subheadline); Spacer(); Image(systemName: "arrow.up.right") }
                            }
                        }
                    }
                }
                if article.page == 0, let source = article.sourceURL, let url = URL(string: source) {
                    Link(destination: url) { Label(library.text("onlineSource"), systemImage: "arrow.up.right.square") }
                        .accessibilityIdentifier("translationSource")
                }
                Text(library.text("contentNotice"))
                    .font(.caption).foregroundStyle(.secondary).lineSpacing(4)
            }.textSelection(.enabled).padding(24).frame(maxWidth: 720).frame(maxWidth: .infinity)
        }.background(Theme.paper)
            .navigationTitle(library.text("readTip")).navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .tabBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button(library.text("fontNormal")) { readerSize = 17 }
                        Button(library.text("fontLarge")) { readerSize = 21 }
                        Button(library.text("fontXL")) { readerSize = 25 }
                    } label: { Image(systemName: "textformat.size") }.accessibilityLabel(library.text("fontSize"))
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { library.toggleSaved(article.id) } label: {
                        Image(systemName: library.saved.contains(article.id) ? "bookmark.fill" : "bookmark")
                    }.accessibilityLabel(library.saved.contains(article.id) ? library.text("unsave") : library.text("save")).accessibilityIdentifier("saveArticle")
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button { library.togglePlan(article.id) } label: {
                    Label(library.planned.contains(article.id) ? library.text("planned") : library.text("plan"), systemImage: library.planned.contains(article.id) ? "checkmark.circle.fill" : "plus.circle")
                        .font(.headline).frame(maxWidth: .infinity).padding(14)
                }.buttonStyle(.borderedProminent).tint(Theme.green).accessibilityIdentifier("planArticle")
                    .padding(.horizontal, 22).padding(.vertical, 10).background(.bar)
            }
            .onAppear { library.read.insert(article.id) }
    }
    private func block(_ title: String, symbol: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: symbol).font(.headline).foregroundStyle(Theme.accent)
            Text(text).font(.system(size: readerSize * fontScale)).lineSpacing(7).frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
struct SupplementView: View {
    @EnvironmentObject private var library: Library
    let supplement: Supplement
    @State private var showSource = false
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text(supplement.title).font(.title.bold())
                Text(library.text("pdfPage", supplement.page)).font(.caption).foregroundStyle(.secondary)
                Button(library.text("openPDF")) { showSource = true }.buttonStyle(.bordered)
                Text(supplement.body).font(.body).lineSpacing(7).textSelection(.enabled)
            }.padding(24).frame(maxWidth: 720).frame(maxWidth: .infinity)
        }.background(Theme.paper).navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .tabBar)
            .sheet(isPresented: $showSource) { SourceSheet(page: supplement.page) }
    }
}
struct PDFReader: UIViewRepresentable {
    let page: Int
    func makeUIView(context: Context) -> PDFView {
        let view = PDFView()
        view.accessibilityIdentifier = "sourcePDF"
        view.autoScales = true
        view.displayMode = .singlePageContinuous
        if let url = Bundle.main.url(forResource: "HowToLiveBetter", withExtension: "pdf") {
            view.document = PDFDocument(url: url)
            if let target = view.document?.page(at: page - 1) {
                view.go(to: target)
                DispatchQueue.main.async { view.go(to: target) }
            }
        }
        return view
    }
    func updateUIView(_ uiView: PDFView, context: Context) {}
}
struct SourceSheet: View {
    @EnvironmentObject private var library: Library
    @Environment(\.dismiss) private var dismiss
    let page: Int
    var body: some View {
        NavigationStack {
            PDFReader(page: page).navigationTitle(library.text("sourcePage", page)).navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button(library.text("done")) { dismiss() } } }
        }
    }
}
