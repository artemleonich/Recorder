import SwiftUI
import UniformTypeIdentifiers

struct NotesListView: View {
    @ObservedObject var viewModel: NotesListViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    var body: some View {
        NavigationView {
            ZStack {
                // Gradient background
                LinearGradient(
                    colors: [
                        Color(hex: "1E1A4D"),
                        Color(hex: "111921"),
                        Color(hex: "1C0F3A")
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                // Blurred circles background
                ZStack {
                    Circle()
                        .fill(Color.purple.opacity(0.3))
                        .frame(width: 300, height: 300)
                        .blur(radius: 100)
                        .offset(x: -100, y: -200)
                    
                    Circle()
                        .fill(Color.blue.opacity(0.3))
                        .frame(width: 300, height: 300)
                        .blur(radius: 100)
                        .offset(x: 100, y: 200)
                }
                
                VStack(spacing: 0) {
                    // Sticky header
                    VStack(spacing: 16) {
                        HStack {
                            Text(NSLocalizedString("notes.title", comment: "Notes title"))
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            // Import button
                            Button(action: {
                                viewModel.showImportPicker = true
                            }) {
                                Image(systemName: "square.and.arrow.down")
                                    .font(.title3)
                                    .foregroundColor(.white)
                                    .frame(width: 44, height: 44)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(.ultraThinMaterial)
                                    )
                            }
                            .accessibilityLabel(NSLocalizedString("accessibility.import.button", comment: "Import audio"))
                        }
                        
                        // Search bar
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.white.opacity(0.5))
                            
                            TextField(NSLocalizedString("notes.search.placeholder", comment: "Search placeholder"), text: $viewModel.searchQuery)
                                .foregroundColor(.white)
                                .autocorrectionDisabled()
                                .accessibilityLabel(NSLocalizedString("accessibility.search.field", comment: "Search field"))
                                .accessibilityHint(NSLocalizedString("accessibility.search.hint", comment: "Search hint"))
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.ultraThinMaterial)
                        )
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    
                    // Notes list
                    if viewModel.isLoading {
                        Spacer()
                        ProgressView()
                            .tint(.white)
                        Spacer()
                    } else if viewModel.filteredNotes.isEmpty {
                        Spacer()
                        VStack(spacing: 16) {
                            Image(systemName: "mic.slash")
                                .font(.system(size: 60))
                                .foregroundColor(.white.opacity(0.3))
                            
                            Text(viewModel.searchQuery.isEmpty ? NSLocalizedString("notes.empty", comment: "No notes") : NSLocalizedString("notes.search.empty", comment: "Nothing found"))
                                .font(.title3)
                                .foregroundColor(.white.opacity(0.5))
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
                                    .accessibilityHint(NSLocalizedString("accessibility.note.hint", comment: "Note hint"))
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(role: .destructive) {
                                            Task {
                                                await viewModel.deleteNote(note)
                                            }
                                        } label: {
                                            Label(NSLocalizedString("notes.delete", comment: "Delete"), systemImage: "trash")
                                        }
                                        .accessibilityLabel(String(format: NSLocalizedString("accessibility.delete.note", comment: "Delete note"), note.title))
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
            Button(NSLocalizedString("button.ok", comment: "OK button")) {
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
        let dateString = formatter.string(from: note.createdAt)
        
        let minutes = Int(note.duration) / 60
        let seconds = Int(note.duration) % 60
        let durationString = String(format: "%02d:%02d", minutes, seconds)
        
        let statusString = note.isTranscriptionCompleted ? 
            NSLocalizedString("note.status.completed", comment: "Completed status") : 
            NSLocalizedString("note.status.processing", comment: "Processing status")
        
        return String(format: NSLocalizedString("accessibility.note.label", comment: "Note label"), 
                     note.title, dateString, durationString, statusString)
    }
}
