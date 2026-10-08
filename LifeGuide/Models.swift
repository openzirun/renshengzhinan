import SwiftUI
import WidgetKit

@MainActor final class Library: ObservableObject {
    @Published private(set) var guide: Guide?
    @Published private(set) var language: GuideLanguage
    @Published var error: String?
    @Published var saved: Set<String> { didSet { persist(saved, key: "saved") } }
    @Published var planned: Set<String> { didSet { persist(planned, key: "planned") } }
    @Published var completed: Set<String> { didSet { persist(completed, key: "completed") } }
    @Published var read: Set<String> { didSet { persist(read, key: "read") } }
    private let defaults: UserDefaults
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let requested = ProcessInfo.processInfo.environment["GUIDE_LANGUAGE"] ?? defaults.string(forKey: "guideLanguage")
        let selected = requested.flatMap(GuideLanguage.init(rawValue:)) ?? GuideLanguage.preferred(Locale.preferredLanguages)
        language = selected
        saved = Set(defaults.stringArray(forKey: "saved" + selected.storageSuffix) ?? [])
        planned = Set(defaults.stringArray(forKey: "planned" + selected.storageSuffix) ?? [])
        completed = Set(defaults.stringArray(forKey: "completed" + selected.storageSuffix) ?? [])
        read = Set(defaults.stringArray(forKey: "read" + selected.storageSuffix) ?? [])
        do { guide = try Self.load(selected) }
        catch { self.error = selected.text("loadError") }
    }
    static func load(_ language: GuideLanguage) throws -> Guide {
        guard let url = Bundle.main.url(forResource: language.resource, withExtension: "json") else { throw CocoaError(.fileNoSuchFile) }
        return try JSONDecoder().decode(Guide.self, from: Data(contentsOf: url))
    }
    func changeLanguage(_ selected: GuideLanguage) {
        guard selected != language else { return }
        do {
            let newGuide = try Self.load(selected)
            // Load each language's records before changing the active persistence namespace.
            let newSaved = Set(defaults.stringArray(forKey: "saved" + selected.storageSuffix) ?? [])
            let newPlanned = Set(defaults.stringArray(forKey: "planned" + selected.storageSuffix) ?? [])
            let newCompleted = Set(defaults.stringArray(forKey: "completed" + selected.storageSuffix) ?? [])
            let newRead = Set(defaults.stringArray(forKey: "read" + selected.storageSuffix) ?? [])
            language = selected
            guide = newGuide
            saved = newSaved; planned = newPlanned; completed = newCompleted; read = newRead
            defaults.set(selected.rawValue, forKey: "guideLanguage")
            error = nil
        } catch { self.error = language.text("loadError") }
    }
    func text(_ key: String, _ arguments: CVarArg...) -> String {
        let bundle = Bundle.main.path(forResource: language.rawValue, ofType: "lproj").flatMap(Bundle.init(path:)) ?? .main
        let format = bundle.localizedString(forKey: key, value: key, table: "UI")
        return String(format: format, locale: Locale(identifier: language.rawValue), arguments: arguments)
    }
    private func persist(_ values: Set<String>, key: String) { defaults.set(values.sorted(), forKey: key + language.storageSuffix) }
    func toggleSaved(_ id: String) { if !saved.insert(id).inserted { saved.remove(id) } }
    func togglePlan(_ id: String) {
        if !planned.insert(id).inserted { planned.remove(id); completed.remove(id) }
    }
    func toggleDone(_ id: String) { if !completed.insert(id).inserted { completed.remove(id) } }
    func chapter(_ id: Int) -> Chapter? { guide?.chapters.first { $0.id == id } }
    var articles: [Article] { guide?.articles ?? [] }
    var daily: Article? { daily(at: Date()) }
    func daily(at date: Date) -> Article? {
        DailyReading.article(in: articles, at: date)
    }

}

enum Theme {
    static let green = Color(red: 0.14, green: 0.31, blue: 0.25)
    static let paper = Color(uiColor: UIColor { $0.userInterfaceStyle == .dark ? UIColor(red: 0.08, green: 0.11, blue: 0.10, alpha: 1) : UIColor(red: 0.97, green: 0.96, blue: 0.93, alpha: 1) })
    static let card = Color(uiColor: .secondarySystemGroupedBackground)
    static let accent = Color(uiColor: UIColor { $0.userInterfaceStyle == .dark ? UIColor(red: 0.60, green: 0.80, blue: 0.67, alpha: 1) : UIColor(red: 0.14, green: 0.31, blue: 0.25, alpha: 1) })
}

@main struct LifeGuideApp: App {
    @StateObject private var library = Library()
    @State private var linkedArticle: Article?
    @Environment(\.scenePhase) private var scenePhase
    var body: some Scene {
        WindowGroup { RootView().id(library.language).environmentObject(library)
                .task {
                    syncWidgetLanguage()
                }
                .onChange(of: library.language) { _, _ in syncWidgetLanguage() }
                .onOpenURL { url in
                    guard let link = DailyReading.destination(for: url) else { return }
                    library.changeLanguage(link.language)
                    guard library.language == link.language else { return }
                    linkedArticle = library.articles.first { $0.id == link.articleID }
                }
                .sheet(item: $linkedArticle) { article in
                    NavigationStack {
                        ArticleView(article: article)
                            .toolbar {
                                ToolbarItem(placement: .confirmationAction) {
                                    Button { linkedArticle = nil } label: { Image(systemName: "xmark") }
                                        .accessibilityLabel(Text(library.text("done")))
                                }
                            }
                    }
                    .environmentObject(library)
                }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active { syncWidgetLanguage() }
                }
                .environment(\.locale, Locale(identifier: library.language.rawValue))
                .environment(\.layoutDirection, library.language == .arabic ? .rightToLeft : .leftToRight)
                .tint(Theme.accent) }
    }
    private func syncWidgetLanguage() {
        guard let defaults = UserDefaults(suiteName: DailyReading.appGroup),
              defaults.string(forKey: "guideLanguage") != library.language.rawValue else { return }
        defaults.set(library.language.rawValue, forKey: "guideLanguage")
        WidgetCenter.shared.reloadTimelines(ofKind: DailyReading.widgetKind)
    }

}
