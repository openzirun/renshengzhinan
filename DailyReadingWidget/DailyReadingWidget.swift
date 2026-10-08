import SwiftUI
import WidgetKit

struct ReadingEntry: TimelineEntry {
    let date: Date
    let language: GuideLanguage
    let article: Article?
}

struct ReadingProvider: TimelineProvider {
    private var language: GuideLanguage {
        UserDefaults(suiteName: DailyReading.appGroup)?.string(forKey: "guideLanguage")
            .flatMap(GuideLanguage.init(rawValue:)) ?? GuideLanguage.preferred(Locale.preferredLanguages)
    }

    private func articles(for language: GuideLanguage) -> [Article] {
        guard let url = Bundle.main.url(forResource: language.resource, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let guide = try? JSONDecoder().decode(Guide.self, from: data) else { return [] }
        return guide.articles
    }

    func placeholder(in context: Context) -> ReadingEntry {
        let language = language
        return ReadingEntry(date: .now, language: language, article: DailyReading.article(in: articles(for: language), at: .now))
    }

    func getSnapshot(in context: Context, completion: @escaping (ReadingEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ReadingEntry>) -> Void) {
        let language = language
        let articles = articles(for: language)
        let entries = DailyReading.entryDates(from: .now).map {
            ReadingEntry(date: $0, language: language, article: DailyReading.article(in: articles, at: $0))
        }
        completion(Timeline(entries: entries, policy: .atEnd))
    }
}

struct ReadingWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: ReadingEntry
    private let green = Color(red: 0.14, green: 0.31, blue: 0.25)

    var body: some View {
        VStack(alignment: .leading, spacing: family == .systemSmall ? 10 : 14) {
            HStack {
                Label(entry.language.text("daily"), systemImage: "sparkle")
                    .font(.caption.weight(.medium))
                Spacer(minLength: 4)
                if family != .systemSmall {
                    Text(entry.date, format: .dateTime.month().day()).font(.caption2)
                }
            }.foregroundStyle(.white.opacity(0.75))
            if let article = entry.article {
                Text(article.title)
                    .font(family == .systemSmall ? .headline : .title3.weight(.semibold))
                    .lineLimit(family == .systemSmall ? 3 : 2)
                if family != .systemSmall {
                    Text(article.summary).font(.subheadline)
                        .lineSpacing(3).lineLimit(family == .systemLarge ? 8 : 2)
                        .foregroundStyle(.white.opacity(0.85))
                }
                Spacer(minLength: 0)
                HStack {
                    Text(entry.language.text("evidenceValue", article.evidenceCode)).font(.caption2)
                    Spacer(minLength: 4)
                    Image(systemName: "arrow.up.right").font(.caption)
                }.foregroundStyle(.white.opacity(0.75))
            } else {
                Text(entry.language.text("loadTitle")).font(.headline)
                Text(entry.language.text("loadError")).font(.caption).lineLimit(3)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .foregroundStyle(.white)
        .containerBackground(for: .widget) { Rectangle().fill(green.gradient) }
        .widgetURL(entry.article.map { DailyReading.url(articleID: $0.id, language: entry.language) })
        .environment(\.locale, Locale(identifier: entry.language.rawValue))
        .environment(\.layoutDirection, entry.language == .arabic ? .rightToLeft : .leftToRight)
    }
}

@main struct DailyReadingWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: DailyReading.widgetKind, provider: ReadingProvider()) { entry in
            ReadingWidgetView(entry: entry)
        }
        .configurationDisplayName(GuideLanguage.preferred(Locale.preferredLanguages).text("daily"))
        .description(GuideLanguage.preferred(Locale.preferredLanguages).text("tagline"))
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
