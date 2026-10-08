import SwiftUI

struct RootView: View {
    @EnvironmentObject private var library: Library
    var body: some View {
        if let error = library.error {
            ContentUnavailableView(library.text("loadTitle"), systemImage: "book.closed", description: Text(error))
        } else {
            TabView {
                NavigationStack { HomeView() }.tabItem { Label(library.text("today"), systemImage: "sun.max") }
                NavigationStack { BrowseView() }.tabItem { Label(library.text("guide"), systemImage: "books.vertical") }
                NavigationStack { SavedView() }.tabItem { Label(library.text("saved"), systemImage: "bookmark") }
                NavigationStack { ActionView() }.tabItem { Label(library.text("actions"), systemImage: "checkmark.circle") }
            }
        }
    }
}

struct HomeView: View {
    @State private var showLanguages = false
    @EnvironmentObject private var library: Library
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                HStack {
                    Label("THE BETTER LIFE GUIDE", systemImage: "leaf.fill")
                        .font(.system(size: 10, weight: .semibold, design: .monospaced)).tracking(1.3)
                    Spacer()
                    Button { showLanguages = true } label: { Image(systemName: "globe").font(.title3) }
                        .accessibilityLabel(library.text("language")).accessibilityIdentifier("languagePicker")
                    NavigationLink { AboutView() } label: { Image(systemName: "info.circle").font(.title3) }
                        .accessibilityLabel(library.text("about"))
                }.foregroundStyle(Theme.accent)
                VStack(alignment: .leading, spacing: 10) {
                    Text(library.text("hero"))
                        .font(.system(.largeTitle, design: .serif, weight: .bold)).tracking(-1)
                    Text(library.text("tagline"))
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                HStack(spacing: 0) {
                    metric("\(library.articles.count)", library.text("tips"))
                    Divider().frame(height: 30)
                    metric(String(library.guide?.chapters.count ?? 0), library.text("topics"))
                    Divider().frame(height: 30)
                    metric(library.text("offline"), library.text("available"))
                }.padding(.vertical, 16).background(Theme.card, in: RoundedRectangle(cornerRadius: 18))
                TimelineView(.periodic(from: .now, by: 60)) { context in
                    if let article = library.daily(at: context.date) {
                        NavigationLink { ArticleView(article: article) } label: {
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Label(library.text("daily"), systemImage: "sparkle").font(.subheadline.weight(.medium))
                                    Spacer()
                                    Text("\(article.chapterID.formatted(.number.precision(.integerLength(2)))) / \(article.number)")
                                        .font(.system(.caption, design: .monospaced))
                                }.foregroundStyle(.white.opacity(0.7))
                                Text(article.title).font(.title2.weight(.semibold)).multilineTextAlignment(.leading).lineLimit(3)
                                Text(article.summary).font(.subheadline).lineSpacing(5).lineLimit(3).multilineTextAlignment(.leading).foregroundStyle(.white.opacity(0.85))
                                HStack {
                                    Text(library.text("evidenceValue", article.evidenceCode)).font(.caption).padding(.horizontal, 10).padding(.vertical, 6)
                                        .background(.white.opacity(0.12), in: Capsule())
                                    Spacer()
                                    Text(library.text("read")).font(.subheadline.weight(.medium))
                                    Image(systemName: "arrow.up.right")
                                }
                            }.padding(24).foregroundStyle(.white)
                                .background(Theme.green.gradient, in: RoundedRectangle(cornerRadius: 24))
                        }.buttonStyle(.plain)
                    }
                }
                HStack {
                    Text(library.text("start")).font(.title3.bold())
                    Spacer()
                    NavigationLink(library.text("allTopics")) { BrowseView() }.font(.subheadline)
                }
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    topic(library.text("health"), subtitle: library.text("healthSub"), symbol: "heart", ids: [1, 2, 13, 16, 24, 28, 34])
                    topic(library.text("money"), subtitle: library.text("moneySub"), symbol: "banknote", ids: [5, 6, 7, 12, 15])
                    topic(library.text("time"), subtitle: library.text("timeSub"), symbol: "sun.max", ids: [3, 4, 22, 23, 29])
                    topic(library.text("relationships"), subtitle: library.text("relationshipsSub"), symbol: "person.2", ids: [10, 17, 18, 20, 27, 30, 31])
                }
                NavigationLink { ChapterView(chapter: library.chapter(13)!) } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "cross.case.fill").font(.title2)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(library.text("emergency")).font(.subheadline.bold())
                            Text(library.text("emergencySub")).font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer(); Image(systemName: "chevron.right").font(.caption)
                    }.padding(18).background(Theme.card, in: RoundedRectangle(cornerRadius: 18))
                }.buttonStyle(.plain)
                Text(library.text("gentle"))
                    .font(.footnote).foregroundStyle(.secondary).frame(maxWidth: .infinity).padding(.bottom, 8)
            }.padding(22).frame(maxWidth: 700)
                .frame(maxWidth: .infinity)
        }.background(Theme.paper).toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showLanguages) { LanguagePickerView() }
    }
    private func metric(_ value: String, _ label: String) -> some View {
        VStack(spacing: 4) { Text(value).font(.title3.bold()).foregroundStyle(Theme.accent); Text(label).font(.caption2).foregroundStyle(.secondary) }.frame(maxWidth: .infinity)
    }
    private func topic(_ title: String, subtitle: String, symbol: String, ids: [Int]) -> some View {
        NavigationLink { TopicView(title: title, ids: ids) } label: {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: symbol).font(.title2).foregroundStyle(Theme.accent)
                Text(title).font(.headline)
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }.frame(maxWidth: .infinity, alignment: .leading).padding(18)
                .background(Theme.card, in: RoundedRectangle(cornerRadius: 18))
        }.buttonStyle(.plain)
    }
}

struct TopicView: View {
    @EnvironmentObject private var library: Library
    let title: String
    let ids: [Int]
    var body: some View {
        List(library.guide?.chapters.filter { ids.contains($0.id) } ?? []) { chapter in
            NavigationLink { ChapterView(chapter: chapter) } label: { ChapterRow(chapter: chapter) }
        }.navigationTitle(title).scrollContentBackground(.hidden).background(Theme.paper)
    }
}
struct ChapterRow: View {
    @EnvironmentObject private var library: Library
    let chapter: Chapter
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: chapter.symbol).font(.title3).foregroundStyle(Theme.accent)
                .frame(width: 40, height: 44).background(Theme.accent.opacity(0.07), in: RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 5) {
                Text(chapter.title).font(.headline)
                Text(library.text("chapterCount", chapter.id, library.articles.filter { $0.chapterID == chapter.id }.count)).font(.caption).foregroundStyle(.secondary)
            }
        }.padding(.vertical, 5)
    }
}
struct ArticleRow: View {
    @EnvironmentObject private var library: Library
    let article: Article
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(library.chapter(article.chapterID)?.title ?? "") · \(article.number)").lineLimit(1)
                Spacer()
                Text(library.text("evidenceValue", article.evidenceCode)).foregroundStyle(Theme.accent)
                if library.saved.contains(article.id) { Image(systemName: "bookmark.fill").foregroundStyle(Theme.accent) }
            }.font(.caption)
            Text(article.title).font(.headline).foregroundStyle(.primary).fixedSize(horizontal: false, vertical: true)
            Text(article.summary).font(.subheadline).foregroundStyle(.secondary).lineLimit(2).lineSpacing(3)
        }.padding(.vertical, 10)
    }
}
