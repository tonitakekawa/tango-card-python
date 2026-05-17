import AVFoundation
import Combine

@preconcurrency class TTSService: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    static let shared = TTSService()

    private let synthesizer = AVSpeechSynthesizer()
    @Published var isPlaying = false

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func voices(for locale: String) -> [AVSpeechSynthesisVoice] {
        let components = locale.split(separator: "-")
        return AVSpeechSynthesisVoice.speechVoices()
            .filter {
                if components.count >= 2 {
                    return $0.language.hasPrefix(locale)
                } else if let lang = components.first {
                    return $0.language.hasPrefix(lang)
                }
                return false
            }
            .sorted { $0.quality.rawValue > $1.quality.rawValue }
    }

    func speak(text: String, voiceIdentifier: String) {
        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = voiceIdentifier.isEmpty
            ? nil
            : AVSpeechSynthesisVoice(identifier: voiceIdentifier)
        utterance.rate = 0.5
        synthesizer.speak(utterance)
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { self.isPlaying = true }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { self.isPlaying = false }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { self.isPlaying = false }
    }
}
