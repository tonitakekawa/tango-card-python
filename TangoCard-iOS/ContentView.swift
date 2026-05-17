import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Word.createdAt) private var words: [Word]

    @State private var selectedWord: Word?
    @State private var searchText = ""
    @State private var selectedLanguage = ""
    @State private var showingForm = false
    @State private var editingWord: Word?

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
    }
}
