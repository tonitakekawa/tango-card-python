import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct TOMLFile: FileDocument {
    static var readableContentTypes: [UTType] = [.plainText]
    var data: Data
    init(content: String) { self.data = Data(content.utf8) }
    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Word.createdAt, order: .reverse) private var words: [Word]

    @State private var selectedWord: Word?
    @State private var searchText = ""
    @State private var selectedLanguage = ""
    @State private var showingForm = false
    @State private var editingWord: Word?
    @State private var showingExporter = false
    @State private var showingImporter = false
    @State private var exportedFile: TOMLFile?

    var languages: [String] {
        Array(Set(words.map { $0.language }.filter { !$0.isEmpty })).sorted()
    }

    var filteredWords: [Word] {
        words.filter { word in
            (selectedLanguage.isEmpty || word.language == selectedLanguage) &&
            (searchText.isEmpty ||
             word.notation.localizedCaseInsensitiveContains(searchText) ||
             word.reading.localizedCaseInsensitiveContains(searchText))
        }
    }

    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                if !languages.isEmpty {
                    Picker("言語", selection: $selectedLanguage) {
                        Text("すべて").tag("")
                        ForEach(languages, id: \.self) { Text($0).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }

                List(filteredWords, selection: $selectedWord) { word in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(word.notation)
                            .font(.system(size: 17, weight: .semibold))
                        Text(word.language)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .tag(word)
                }
                .searchable(text: $searchText, prompt: "検索...")
            }
            .navigationTitle("単語カード")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        editingWord = nil
                        showingForm = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .secondaryAction) {
                    Menu {
                        Button("エクスポート", systemImage: "square.and.arrow.up") { exportWords() }
                        Button("インポート", systemImage: "square.and.arrow.down") { showingImporter = true }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        } detail: {
            if let word = selectedWord {
                WordCardView(word: word) {
                    editingWord = word
                    showingForm = true
                } onDelete: {
                    modelContext.delete(word)
                    selectedWord = nil
                }
            } else {
                ContentUnavailableView(
                    "単語を選択",
                    systemImage: "text.book.closed",
                    description: Text("リストから単語を選んでください")
                )
            }
        }
        .sheet(isPresented: $showingForm) {
            WordFormView(word: editingWord)
        }
        .fileExporter(
            isPresented: $showingExporter,
            document: exportedFile,
            contentType: .plainText,
            defaultFilename: "tango-card.toml"
        ) { _ in exportedFile = nil }
        .fileImporter(isPresented: $showingImporter, allowedContentTypes: [.plainText, .text, .data]) { result in
            importWords(result: result)
        }
    }

    private func exportWords() {
        exportedFile = TOMLFile(content: TOMLConverter.serialize(words: words))
        showingExporter = true
    }

    private func importWords(result: Result<URL, Error>) {
        guard case .success(let url) = result,
              url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }
        guard let content = try? String(contentsOf: url, encoding: .utf8) else { return }
        for w in TOMLConverter.parse(content) {
            modelContext.insert(Word(language: w.language, locale: w.locale, voice: w.voice,
                                    notation: w.notation, reading: w.reading, meaning: w.meaning))
        }
    }
}
