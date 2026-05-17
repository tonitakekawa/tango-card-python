import SwiftUI
import AVFoundation

struct WordCardView: View {
    let word: Word
    let onEdit: () -> Void
    let onDelete: () -> Void

    @StateObject private var tts = TTSService.shared
    @State private var selectedVoice = ""
    @State private var availableVoices: [AVSpeechSynthesisVoice] = []
    @State private var showDeleteConfirm = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // カード本体
                VStack(alignment: .leading, spacing: 8) {
                    Text(word.language)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(word.notation)
                        .font(.system(size: 48, weight: .bold))

                    if !word.reading.isEmpty {
                        Text(word.reading)
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }

                    if !word.meaning.isEmpty {
                        Text(word.meaning)
                            .font(.title3)
                            .foregroundStyle(.tertiary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(24)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.07), radius: 12, y: 4)

                // 話者選択
                if !availableVoices.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("話者")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Picker("話者", selection: $selectedVoice) {
                            ForEach(availableVoices, id: \.identifier) { v in
                                Text(voiceLabel(v)).tag(v.identifier)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }

                // アクションボタン
                VStack(spacing: 12) {
                    Button(action: playWord) {
                        Label(tts.isPlaying ? "再生中..." : "読み上げ",
                              systemImage: tts.isPlaying ? "waveform" : "play.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    .disabled(tts.isPlaying)

                    HStack(spacing: 12) {
                        Button(action: onEdit) {
                            Label("編集", systemImage: "pencil")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)

                        Button { showDeleteConfirm = true } label: {
                            Label("削除", systemImage: "trash")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(word.notation)
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("「\(word.notation)」を削除しますか？",
                            isPresented: $showDeleteConfirm,
                            titleVisibility: .visible) {
            Button("削除", role: .destructive, action: onDelete)
        }
        .onAppear(perform: loadVoices)
        .onChange(of: word.locale) { loadVoices() }
    }

    private func loadVoices() {
        availableVoices = TTSService.shared.voices(for: word.locale)
        selectedVoice = availableVoices.contains(where: { $0.identifier == word.voice })
            ? word.voice
            : (availableVoices.first?.identifier ?? "")
    }

    private func playWord() {
        TTSService.shared.speak(text: word.notation, voiceIdentifier: selectedVoice)
    }

    private func voiceLabel(_ voice: AVSpeechSynthesisVoice) -> String {
        let quality: String
        switch voice.quality {
        case .premium:  quality = " ★★★"
        case .enhanced: quality = " ★★"
        default:        quality = ""
        }
        return "\(voice.name)\(quality)"
    }
}
