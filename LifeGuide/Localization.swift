import Foundation

enum GuideLanguage: String, CaseIterable, Identifiable {
    case chinese = "zh-Hans", english = "en", russian = "ru", spanish = "es"
    case portuguese = "pt", vietnamese = "vi", arabic = "ar", indonesian = "id"
    var id: String { rawValue }
    var name: String {
        switch self {
        case .chinese: return "简体中文"
        case .english: return "English"
        case .russian: return "Русский"
        case .spanish: return "Español"
        case .portuguese: return "Português"
        case .vietnamese: return "Tiếng Việt"
        case .arabic: return "العربية"
        case .indonesian: return "Bahasa Indonesia"
        }
    }
    var resource: String { self == .chinese ? "guide" : "guide-\(rawValue)" }
    var storageSuffix: String { self == .chinese ? "" : ".\(rawValue)" }
    static func preferred(_ languages: [String]) -> Self {
        for language in languages {
            if language.hasPrefix("zh") { return .chinese }
            if let supported = allCases.first(where: { language == $0.rawValue || language.hasPrefix($0.rawValue + "-") }) { return supported }
        }
        return .english
    }
    func text(_ key: String, _ arguments: CVarArg...) -> String {
        let bundle = Bundle.main.path(forResource: rawValue, ofType: "lproj").flatMap(Bundle.init(path:)) ?? .main
        let format = bundle.localizedString(forKey: key, value: key, table: "UI")
        return String(format: format, locale: Locale(identifier: rawValue), arguments: arguments)
    }
}
