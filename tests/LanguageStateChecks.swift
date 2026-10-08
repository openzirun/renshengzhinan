import Foundation

@main struct LanguageStateChecks {
    @MainActor static func main() throws {
        let expected: [GuideLanguage: Int] = [.chinese: 672, .english: 665, .russian: 665, .spanish: 665, .portuguese: 665, .vietnamese: 641, .arabic: 635, .indonesian: 630]
        for language in GuideLanguage.allCases {
            let guide = try Library.load(language)
            precondition(guide.articles.count == expected[language])
            precondition(guide.chapters.count == 34)
            precondition(Set(guide.articles.map(\.id)).count == guide.articles.count)
            precondition(guide.articles.allSatisfy { ["A", "B", "C"].contains($0.evidenceCode) })
            precondition(language.text("counts", 12, 34).contains("12"))
            precondition(language.text("counts", 12, 34).contains("34"))
            precondition(language.text("today") != "today")
            if language != .chinese {
                precondition(guide.articles.allSatisfy { $0.page == 0 && $0.sourceURL?.hasPrefix("https://github.com/") == true })
                precondition(guide.extras.isEmpty)
            }
        }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Los_Angeles")!
        let beforeDST = calendar.date(from: DateComponents(year: 2026, month: 3, day: 7, hour: 15))!
        let dates = DailyReading.entryDates(from: beforeDST, calendar: calendar)
        precondition(dates.count == 8 && dates.first == beforeDST)
        precondition(dates.dropFirst().allSatisfy { calendar.component(.hour, from: $0) == 0 })
        precondition(dates[2].timeIntervalSince(dates[1]) == 23 * 60 * 60)
        precondition(DailyReading.article(in: [], at: beforeDST) == nil)
        for language in GuideLanguage.allCases {
            let guide = try Library.load(language)
            let first = DailyReading.article(in: guide.articles, at: beforeDST, calendar: calendar)!
            let later = DailyReading.article(in: guide.articles, at: beforeDST.addingTimeInterval(60), calendar: calendar)!
            let tomorrow = DailyReading.article(in: guide.articles, at: dates[1], calendar: calendar)!
            precondition(first.id == later.id && first.id != tomorrow.id)
            precondition(first.number <= 3) // Every recommended article is free to read.
            let link = DailyReading.destination(for: DailyReading.url(articleID: first.id, language: language))!
            precondition(link.articleID == first.id && link.language == language)
        }
        for value in ["https://article?id=1-1&language=en", "lifeguide://other?id=1-1&language=en",
                      "lifeguide://article?id=1-1&language=unknown", "lifeguide://article?language=en"] {
            precondition(DailyReading.destination(for: URL(string: value)!) == nil)
        }
        print("PASS: daily selection in 8 languages, free articles, local midnight / DST timeline, deep links and invalid routes.")
        let suite = "LifeGuide.LanguageChecks." + UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        // Existing Chinese keys must migrate without renaming or deleting records.
        defaults.set("zh-Hans", forKey: "guideLanguage")
        defaults.set(["1-1"], forKey: "saved")
        defaults.set(["1-1"], forKey: "planned")
        let library = Library(defaults: defaults)
        precondition(library.saved == ["1-1"] && library.planned == ["1-1"])
        library.toggleDone("1-1")
        library.changeLanguage(.english)
        precondition(library.saved.isEmpty && library.planned.isEmpty && library.completed.isEmpty)
        library.toggleSaved("1-2")
        library.togglePlan("1-2")
        library.toggleDone("1-2")
        library.read.insert("1-2")
        let reopened = Library(defaults: defaults)
        precondition(reopened.language == .english)
        precondition(reopened.saved == ["1-2"] && reopened.completed == ["1-2"] && reopened.read == ["1-2"])
        reopened.changeLanguage(.chinese)
        precondition(reopened.saved == ["1-1"] && reopened.completed == ["1-1"])
        reopened.changeLanguage(.english)
        reopened.togglePlan("1-2")
        precondition(reopened.planned.isEmpty && reopened.completed.isEmpty)
        precondition(defaults.stringArray(forKey: "saved") == ["1-1"])
        precondition(GuideLanguage.preferred(["pt-BR"]) == .portuguese)
        precondition(GuideLanguage.preferred(["zh-TW"]) == .chinese)
        precondition(GuideLanguage.preferred(["fr-FR", "vi-VN"]) == .vietnamese)
        precondition(GuideLanguage.preferred(["de-DE"]) == .english)
        let spanish = try Library.load(.spanish)
        precondition(spanish.articles.filter { $0.chapterID == 12 && $0.number == 8 }.count == 2)
        print("PASS: 8 editions decoded; evidence, source routes, duplicate IDs, system matching, legacy Chinese records, language isolation and restart persistence.")
    }
}
