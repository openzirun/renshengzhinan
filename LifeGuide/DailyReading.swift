import Foundation

/// Shared by the app and WidgetKit so the same local day always shows the same tip.
enum DailyReading {
    static let appGroup = "group.com.zirunly.HowToLiveBetter"
    static let widgetKind = "DailyReadingWidget"

    static func article(in articles: [Article], at date: Date, calendar: Calendar = .current) -> Article? {
        let picks = articles.filter { [1, 3, 4, 5, 14, 22].contains($0.chapterID) && $0.number <= 3 }
        guard !picks.isEmpty else { return nil }
        let day = calendar.ordinality(of: .day, in: .era, for: date) ?? 0
        return picks[((day % picks.count) + picks.count) % picks.count]
    }

    static func entryDates(from date: Date, calendar: Calendar = .current) -> [Date] {
        // Queue a week of local midnights; the system controls actual refresh timing.
        [date] + (1...7).compactMap { calendar.date(byAdding: .day, value: $0, to: calendar.startOfDay(for: date)) }
    }

    static func url(articleID: String, language: GuideLanguage) -> URL {
        var components = URLComponents()
        components.scheme = "lifeguide"
        components.host = "article"
        components.queryItems = [URLQueryItem(name: "id", value: articleID), URLQueryItem(name: "language", value: language.rawValue)]
        return components.url!
    }

    static func destination(for url: URL) -> (articleID: String, language: GuideLanguage)? {
        guard url.scheme == "lifeguide", url.host == "article",
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let id = components.queryItems?.first(where: { $0.name == "id" })?.value, !id.isEmpty,
              let raw = components.queryItems?.first(where: { $0.name == "language" })?.value,
              let language = GuideLanguage(rawValue: raw) else { return nil }
        return (id, language)
    }
}
