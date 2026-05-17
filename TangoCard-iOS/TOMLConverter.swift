import Foundation

enum TOMLConverter {
    static func serialize(words: [Word]) -> String {
        var lines: [String] = []
        for w in words {
            lines.append("[[\"概念\"]]")
            lines.append("\"圏\" = \"\(esc(w.language))\"")
            lines.append("\"tts対象\" = \"\(esc(w.voice))\"")
            lines.append("\"記述\" = \"\(esc(w.notation))\"")
            lines.append("\"読み方\" = \"\(esc(w.reading))\"")
            lines.append("\"意味\" = \"\(esc(w.meaning))\"")
            lines.append("")
        }
        return lines.joined(separator: "\n")
    }

    static func parse(_ content: String) -> [(language: String, locale: String, voice: String, notation: String, reading: String, meaning: String)] {
        var result: [(language: String, locale: String, voice: String, notation: String, reading: String, meaning: String)] = []
        var current: [String: String] = [:]

        for line in content.components(separatedBy: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed == "[[\"概念\"]]" {
                if !current.isEmpty { result.append(makeEntry(current)); current = [:] }
            } else if let (k, v) = parseKV(trimmed) {
                current[k] = v
            }
        }
        if !current.isEmpty { result.append(makeEntry(current)) }
        return result
    }

    private static func makeEntry(_ d: [String: String]) -> (language: String, locale: String, voice: String, notation: String, reading: String, meaning: String) {
        let voice = d["tts対象"] ?? ""
        let locale = voice.split(separator: "-").prefix(2).joined(separator: "-")
        return (language: d["圏"] ?? "", locale: locale, voice: voice,
                notation: d["記述"] ?? "", reading: d["読み方"] ?? "", meaning: d["意味"] ?? "")
    }

    private static func parseKV(_ line: String) -> (String, String)? {
        guard let sepRange = line.range(of: "\" = \"") else { return nil }
        let keyStart = line.hasPrefix("\"") ? line.index(after: line.startIndex) : line.startIndex
        let key = String(line[keyStart..<sepRange.lowerBound])
        var value = String(line[sepRange.upperBound...])
        if value.hasSuffix("\"") { value = String(value.dropLast()) }
        value = value.replacingOccurrences(of: "\\\"", with: "\"")
                     .replacingOccurrences(of: "\\\\", with: "\\")
        return (key, value)
    }

    private static func esc(_ s: String) -> String {
        s.replacingOccurrences(of: "\\", with: "\\\\")
         .replacingOccurrences(of: "\"", with: "\\\"")
    }
}
