import SwiftUI
import SwiftData
import AVFoundation

struct WordFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Word.createdAt) private var allWords: [Word]

    let word: Word?

    @State private var language = ""
    @State private var locale = ""
    @State private var voice = ""
    @State private var notation = ""
    @State private var reading = ""
    @State private var meaning = ""
    @State private var availableVoices: [AVSpeechSynthesisVoice] = []
    @State private var localeTask: Task<Void, Never>?

    var existingLanguages: [String] {
        Array(Set(allWords.compactMap { w in w.language.isEmpty ? nil : w.language })).sorted()
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("言語情報") {
                    // 言語名：既存言語をタップで選択 or 自由入力
                    LabeledContent("言語名") {
                        TextField("中国語", text: $language)
                            .multilineTextAlignment(.trailing)
                    }

                    if !existingLanguages.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(existingLanguages, id: \.self) { lang in
                                    Button(lang) { selectLanguage(lang) }
                                        .buttonStyle(.bordered)
                                        .tint(language == lang ? .purple : .secondary)
                                        .font(.caption)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }

                    LabeledContent("ロケール") {
                        TextField("zh-CN", text: $locale)
                            .multilineTextAlignment(.trailing)
                            .autocorrectionDisabled()
                            .onChange(of: locale) { onLocaleChange() }
                    }

                    if !availableVoices.isEmpty {
                        Picker("話者", selection: $voice) {
                            ForEach(availableVoices, id: \.identifier) { v in
                                Text(voiceLabel(v)).tag(v.identifier)
                            }
                        }
                    }
                }

                Section("単語") {
                    LabeledContent("記述") {
                        TextField("泡沫", text: $notation)
                            .multilineTextAlignment(.trailing)
                            .onChange(of: notation) { _, new in
                                if language == "中国語" && reading.isEmpty && !new.isEmpty {
                                    reading = toPinyin(new)
                                }
                            }
                    }
                    LabeledContent("読み方") {
                        TextField("pào mò", text: $reading)
                            .multilineTextAlignment(.trailing)
                    }
                    LabeledContent("意味") {
                        TextField("泡", text: $meaning)
                            .multilineTextAlignment(.trailing)
                    }
                }
            }
            .navigationTitle(word == nil ? "単語を追加" : "単語を編集")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル", action: { dismiss() })
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存", action: save)
                        .disabled(notation.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear(perform: loadInitial)
        }
    }

    private func loadInitial() {
        guard let w = word else { return }
        language = w.language
        locale = w.locale
        voice = w.voice
        notation = w.notation
        reading = w.reading
        meaning = w.meaning
        if !locale.isEmpty { loadVoices() }
    }

    private func selectLanguage(_ lang: String) {
        language = lang
        guard let matched = allWords.first(where: { $0.language == lang }) else { return }
        locale = matched.locale
        loadVoices()
        voice = matched.voice
    }

    private func onLocaleChange() {
        localeTask?.cancel()
        localeTask = Task {
            try? await Task.sleep(for: .milliseconds(400))
            guard !Task.isCancelled else { return }
            loadVoices()
        }
    }

    private func loadVoices() {
        availableVoices = TTSService.shared.voices(for: locale)
        if !availableVoices.contains(where: { $0.identifier == voice }) {
            voice = availableVoices.first?.identifier ?? ""
        }
    }

    private func voiceLabel(_ v: AVSpeechSynthesisVoice) -> String {
        switch v.quality {
        case .premium:  return "\(v.name) ★★★"
        case .enhanced: return "\(v.name) ★★"
        default:        return v.name
        }
    }

    private func toPinyin(_ text: String) -> String {
        let mutable = NSMutableString(string: text)
        CFStringTransform(mutable, nil, kCFStringTransformMandarinLatin, false)
        return mutable as String
    }

    private func save() {
        let notation = notation.trimmingCharacters(in: .whitespaces)
        if let w = word {
            w.language = language; w.locale = locale; w.voice = voice
            w.notation = notation; w.reading = reading; w.meaning = meaning
        } else {
            modelContext.insert(Word(
                language: language, locale: locale, voice: voice,
                notation: notation, reading: reading, meaning: meaning
            ))
        }
        dismiss()
    }
}
