import Foundation

struct Guide: Decodable {
    let version: String
    let sourceURL: String
    let chapters: [Chapter]
    let articles: [Article]
    let extras: [Supplement]
}
struct Chapter: Decodable, Identifiable, Hashable {
    let id: Int
    let title: String
    let intro: String
    let page: Int
    var symbol: String {
        switch id {
        case 1, 13: return "cross.case"
        case 2, 16, 24, 28, 34: return "heart"
        case 3, 4, 22, 29: return "sun.max"
        case 5, 6, 7, 12: return "banknote"
        case 8, 9, 11, 14, 26: return "checkmark.shield"
        case 10, 17, 18, 20, 27, 30: return "person.2"
        case 15: return "house"
        case 21, 32: return "globe.asia.australia"
        default: return "leaf"
        }
    }
}
struct Article: Decodable, Identifiable, Hashable {
    let id: String
    let chapterID: Int
    let number: Int
    let title: String
    let page: Int
    let cost: String
    let summary: String
    let benefit: String
    let evidence: String
    let sources: String
    let notes: String
    let sourceURL: String?
    var evidenceCode: String { evidence.hasPrefix("أ") ? "A" : String(evidence.prefix(1)) }
    var searchableText: String { "\(title) \(summary) \(cost) \(benefit) \(notes) \(sources)" }
}
struct Supplement: Decodable, Identifiable, Hashable {
    let id: String
    let title: String
    let body: String
    let page: Int
}

