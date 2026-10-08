import SwiftUI

struct SavedView: View {
    @EnvironmentObject private var library: Library
    var body: some View {
        List {
            if library.saved.isEmpty {
                ContentUnavailableView(library.text("savedEmpty"), systemImage: "bookmark", description: Text(library.text("savedHint")))
            } else {
                Section(library.text("savedCount", library.saved.count)) {
                    ForEach(library.articles.filter { library.saved.contains($0.id) }) { article in
                        NavigationLink { ArticleView(article: article) } label: { ArticleRow(article: article) }
                            .swipeActions { Button(library.text("unsave"), role: .destructive) { library.toggleSaved(article.id) } }
                    }
                }
            }
        }.navigationTitle(library.text("savedTitle")).scrollContentBackground(.hidden).background(Theme.paper)
    }
}
struct ActionView: View {
    @EnvironmentObject private var library: Library
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text(library.text("actionIntro")).font(.title2.bold())
                    Text(library.text("progress", library.read.count, library.completed.count, library.planned.count))
                        .font(.subheadline).foregroundStyle(.secondary)
                    if !library.planned.isEmpty { ProgressView(value: Double(library.completed.count), total: Double(library.planned.count)).tint(Theme.accent) }
                }.padding(.vertical, 10)
            }
            if library.planned.isEmpty {
                ContentUnavailableView(library.text("actionsEmpty"), systemImage: "leaf", description: Text(library.text("actionsHint")))
            } else {
                actionSection(library.text("todo"), done: false)
                actionSection(library.text("completed"), done: true)
            }
        }.navigationTitle(library.text("actionsTitle")).scrollContentBackground(.hidden).background(Theme.paper)
    }
    private func actionSection(_ title: String, done: Bool) -> some View {
        Section(title) {
            ForEach(library.articles.filter { library.planned.contains($0.id) && library.completed.contains($0.id) == done }) { article in
                HStack(spacing: 14) {
                    Button { library.toggleDone(article.id) } label: {
                        Image(systemName: done ? "checkmark.circle.fill" : "circle").font(.title2)
                    }.buttonStyle(.borderless).accessibilityLabel(done ? library.text("markUndone") : library.text("markDone")).accessibilityIdentifier("complete-\(article.id)")
                    NavigationLink { ArticleView(article: article) } label: {
                        Text(article.title).font(.subheadline).strikethrough(done).foregroundStyle(done ? .secondary : .primary)
                    }
                }.padding(.vertical, 8)
                    .swipeActions { Button(library.text("remove"), role: .destructive) { library.togglePlan(article.id) } }
            }
        }
    }
}
struct LanguagePickerView: View {
    @EnvironmentObject private var library: Library
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(GuideLanguage.allCases) { language in
                        Button {
                            library.changeLanguage(language)
                            dismiss()
                        } label: {
                            HStack {
                                Text(language.name).foregroundStyle(.primary)
                                Spacer()
                                if library.language == language { Image(systemName: "checkmark").foregroundStyle(Theme.accent) }
                            }
                        }.accessibilityIdentifier("language-\(language.rawValue)")
                    }
                } footer: { Text(library.text("languageHint")) }
            }.navigationTitle(library.text("language"))
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button(library.text("done")) { dismiss() } } }
        }
    }
}
struct AboutView: View {
    @EnvironmentObject private var library: Library
    @State private var showLanguages = false
    var body: some View {
        List {
            Section {
                Label(library.text("appName"), systemImage: "leaf.fill").font(.title2.bold()).foregroundStyle(Theme.accent)
                Text(library.text("gentle"))
                Button { showLanguages = true } label: {
                    HStack { Label(library.text("language"), systemImage: "globe"); Spacer(); Text(library.language.name) }
                }.accessibilityIdentifier("languagePicker")
            }
            Section(library.text("contentVersion")) {
                Text(library.text("counts", library.articles.count, library.guide?.chapters.count ?? 0))
                Text(library.text("version", library.guide?.version ?? ""))
                Text(library.text("attribution"))
                if let url = URL(string: library.guide?.sourceURL ?? "") {
                    Link(library.text("editionSource"), destination: url)
                }
                Link(library.text("originalSource"), destination: URL(string: "https://github.com/eternity4719/HowToLiveBetter")!)
                Link("CC BY 4.0", destination: URL(string: "https://creativecommons.org/licenses/by/4.0/")!)
                Text(library.text("adaptation"))
                if library.language != .chinese { Text(library.text("translationHint")) }
            }
            Section(library.text("usage")) {
                Text(library.text("contentNotice"))
                if let intro = library.guide?.extras.first {
                    NavigationLink(library.text("intro")) { SupplementView(supplement: intro) }
                }
            }
            Section(library.text("privacy")) { Text(library.text("privacyText")) }
        }.navigationTitle(library.text("about")).navigationBarTitleDisplayMode(.inline)
            .scrollContentBackground(.hidden).background(Theme.paper)
            .sheet(isPresented: $showLanguages) { LanguagePickerView() }
    }
}
