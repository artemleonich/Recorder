import SwiftUI
import UniformTypeIdentifiers

struct NotesListView: View {
    @ObservedObject var viewModel: NotesListViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.locale) private var locale

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: backgroundGradient,
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Sticky header
                    VStack(spacing: 16) {
                        HStack {
                            Text("notes.title")
                                .font(.largeTitle)
                                .fontWeight(.bold)

                            Spacer()

                            // Import button
                            Button(action: {
                                viewModel.showImportPicker = true
                            }) {
                                Image(systemName: "square.and.arrow.down")
                                    .font(.title3)
                                    .foregroundColor(.accentColor)
                                    .frame(width: 44, height: 44)
                                    .background(buttonBackground)
                            }
                            .accessibilityLabel(LocalizationHelper.string("accessibility.import.button", locale: locale))
                        }

                        // Search bar
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.secondary)

                            TextField(LocalizedStringKey("notes.search.placeholder"), text: $viewModel.searchQuery)
                                .foregroundColor(.primary)
                                .autocorrectionDisabled()
                                .accessibilityLabel(LocalizationHelper.string("accessibility.search.field", locale: locale))
                                .accessibilityHint(LocalizationHelper.string("accessibility.search.hint", locale: locale))
                        }
                        .padding()
                        .background(searchBackground)
                    }
                    .padding()
                    .background(headerBackground)

                    // Notes list
                    if viewModel.isLoading {
                        Spacer()
                        ProgressView()
                            .tint(Color.accentColor)
                        Spacer()
                    } else if viewModel.filteredNotes.isEmpty {
                        Spacer()
                        VStack(spacing: 16) {
                            Image(systemName: "mic.slash")
                                .font(.system(size: 60))
                                .foregroundColor(.secondary)

                            Text(viewModel.searchQuery.isEmpty ? LocalizedStringKey("notes.empty") : LocalizedStringKey("notes.search.empty"))
                                .font(.title3)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(viewModel.filteredNotes) { note in
                                    NavigationLink(destination: viewModel.createNoteDetailView(for: note)) {
                                        NoteRowView(note: note)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .accessibilityLabel(noteAccessibilityLabel(for: note))
                                    .accessibilityHint(LocalizationHelper.string("accessibility.note.hint", locale: locale))
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(role: .destructive) {
                                            Task {
                                                await viewModel.deleteNote(note)
                                            }
                                        } label: {
                                            Label("notes.delete", systemImage: "trash")
                                        }
                                        .accessibilityLabel(LocalizationHelper.formattedString("accessibility.delete.note", locale: locale, note.title))
                                    }
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            Task {
                await viewModel.loadNotes()
            }
        }
        .alert(
            isPresented: Binding(
                get: { viewModel.error != nil },
                set: { if !$0 { viewModel.error = nil } }
            ),
            error: viewModel.error
        ) { error in
            Button("button.ok") {
                viewModel.error = nil
            }
        } message: { error in
            if let suggestion = error.recoverySuggestion {
                Text(suggestion)
            }
        }
        .fileImporter(
            isPresented: $viewModel.showImportPicker,
            allowedContentTypes: [.audio],
            allowsMultipleSelection: false
        ) { result in
            Task {
                switch result {
                case .success(let urls):
                    if let url = urls.first {
                        await viewModel.importAudioFile(url)
                    }
                case .failure(let error):
                    viewModel.error = .importFailed(error)
                }
            }
        }
    }

    private func noteAccessibilityLabel(for note: AudioNote) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM, HH:mm"
        formatter.locale = locale
        let dateString = formatter.string(from: note.createdAt)

        let minutes = Int(note.duration) / 60
        let seconds = Int(note.duration) % 60
        let durationString = String(format: "%02d:%02d", minutes, seconds)

        let statusKey = note.isTranscriptionCompleted ? "note.status.completed" : "note.status.processing"
        let statusString = LocalizationHelper.string(statusKey, locale: locale)

        return LocalizationHelper.formattedString(
            "accessibility.note.label",
            locale: locale,
            note.title,
            dateString,
            durationString,
            statusString
        )
    }

    private var backgroundGradient: [Color] {
        switch colorScheme {
        case .dark:
            return [
                Color(hex: "1E1A4D"),
                Color(hex: "111921"),
                Color(hex: "1C0F3A")
            ]
        default:
            return [
                Color(.systemBackground),
                Color(.systemGroupedBackground)
            ]
        }
    }

    private var headerBackground: some View {
        Color(.systemGroupedBackground).opacity(colorScheme == .dark ? 0.6 : 0.9)
    }

    private var searchBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color(.secondarySystemGroupedBackground))
    }

    private var buttonBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color(.secondarySystemGroupedBackground))
    }
}
