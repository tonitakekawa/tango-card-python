import SwiftData
import Foundation

@Model
class Word {
    var language: String
    var locale: String
    var voice: String
    var notation: String
    var reading: String
    var meaning: String
    var createdAt: Date

    init(
        language: String = "",
        locale: String = "",
        voice: String = "",
        notation: String = "",
        reading: String = "",
        meaning: String = ""
    ) {
        self.language = language
        self.locale = locale
        self.voice = voice
        self.notation = notation
        self.reading = reading
        self.meaning = meaning
        self.createdAt = Date()
    }
}
