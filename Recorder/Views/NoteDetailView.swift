import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct NoteDetailView: View {
    @ObservedObject var viewModel: NoteDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showShareSheet = false
    @State private var showMenu = false
    @State private var editedTitle: String
    @State private var editedTranscript: String
    
    init(viewModel: NoteDetailViewModel) {
        self.viewModel = viewModel
        _editedTitle = State(initialValue: viewModel.note.title)
        _editedTranscript = State(initialValue: viewModel.note.transcript)
    }
    
    var body: some View {
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
            
            VStack(spacing: 0) {
                // Custom navigation bar
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.title3)
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel(NSLocalizedString("accessibility.back.button", comment: "Back button"))
                    
                    Text(NSLocalizedString("note.detail.title", comment: "Note details title"))
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Menu {
                        Button(action: {
                            showShareSheet = true
                        }) {
                            Label(NSLocalizedString("note.menu.share", comment: "Share"), systemImage: "square.and.arrow.up")
                        }
                        
                        Button(role: .destructive, action: {
                            // Delete action would go here
                        }) {
                            Label(NSLocalizedString("notes.delete", comment: "Delete"), systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.title3)
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel(NSLocalizedString("accessibility.menu.button", comment: "Menu button"))
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Title field
                        VStack(alignment: .leading, spacing: 8) {
                            Text(NSLocalizedString("note.field.title", comment: "Title field"))
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                            
                            TextField(NSLocalizedString("note.field.title.placeholder", comment: "Title placeholder"), text: $editedTitle)
                                .foregroundColor(.white)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(.ultraThinMaterial)
                                )
                                .onSubmit {
                                    Task {
                                        await viewModel.updateTitle(editedTitle)
                                    }
                                }
                                .accessibilityLabel(NSLocalizedString("accessibility.title.field", comment: "Title field"))
                                .accessibilityHint(NSLocalizedString("accessibility.title.hint", comment: "Title hint"))
                        }
                        .padding(.horizontal)
                        .padding(.top)
                        
                        // Date info
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(.white.opacity(0.6))
                            
                            Text(formatDate(viewModel.note.createdAt))
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                            
                            Spacer()
                            
                            Image(systemName: "waveform")
                                .foregroundColor(.white.opacity(0.6))
                            
                            Text(formatDuration(viewModel.note.duration))
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .padding(.horizontal)
                        
                        // Transcript editor
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(NSLocalizedString("note.field.transcript", comment: "Transcript field"))
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.6))
                                
                                Spacer()
                                
                                // Transcription status indicator
                                if !viewModel.note.isTranscriptionCompleted {
                                    HStack(spacing: 4) {
                                        ProgressView()
                                            .scaleEffect(0.7)
                                            .tint(.yellow)
                                        Text(NSLocalizedString("note.status.processing", comment: "Processing status"))
                                            .font(.caption)
                                            .foregroundColor(.yellow)
                                    }
                                }
                            }
                            
                            if viewModel.note.isTranscriptionCompleted || !editedTranscript.isEmpty {
                                TextEditor(text: $editedTranscript)
                                    .foregroundColor(.white)
                                    .scrollContentBackground(.hidden)
                                    .frame(minHeight: 200)
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(.ultraThinMaterial)
                                    )
                                    .accessibilityLabel(NSLocalizedString("accessibility.transcript.field", comment: "Transcript field"))
                                    .accessibilityHint(NSLocalizedString("accessibility.transcript.hint", comment: "Transcript hint"))
                            } else {
                                // Placeholder while transcription is in progress
                                VStack(spacing: 12) {
                                    ProgressView()
                                        .tint(.white)
                                    Text(NSLocalizedString("note.transcription.inprogress", comment: "Transcription in progress"))
                                        .font(.body)
                                        .foregroundColor(.white.opacity(0.6))
                                }
                                .frame(minHeight: 200)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(.ultraThinMaterial)
                                )
                            }
                        }
                        .padding(.horizontal)
                        
                        // Share button
                        Button(action: {
                            showShareSheet = true
                        }) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text(NSLocalizedString("note.share.button", comment: "Share button"))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(hex: "3b82f6"))
                            )
                        }
                        .accessibilityLabel(NSLocalizedString("accessibility.share.button", comment: "Share button"))
                        .accessibilityHint(NSLocalizedString("accessibility.share.hint", comment: "Share hint"))
                        .padding(.horizontal)
                        
                        // Spacer for audio player
                        Spacer()
                            .frame(height: 120)
                    }
                }
                
                // Sticky audio player footer
                VStack(spacing: 12) {
                    // Progress slider
                    VStack(spacing: 4) {
                        Slider(
                            value: Binding(
                                get: { viewModel.currentTime },
                                set: { viewModel.seek(to: $0) }
                            ),
                            in: 0...max(viewModel.duration, 1)
                        )
                        .tint(Color(hex: "3b82f6"))
                        .accessibilityLabel(NSLocalizedString("accessibility.playback.slider", comment: "Playback slider"))
                        .accessibilityValue(String(format: NSLocalizedString("accessibility.playback.value", comment: "Playback value"), formatDuration(viewModel.currentTime), formatDuration(viewModel.duration)))
                        
                        HStack {
                            Text(formatDuration(viewModel.currentTime))
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                            
                            Spacer()
                            
                            Text(formatDuration(viewModel.duration))
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                    .padding(.horizontal)
                    
                    // Playback controls
                    HStack(spacing: 40) {
                        Button(action: {
                            viewModel.skipBackward()
                        }) {
                            Image(systemName: "gobackward.10")
                                .font(.title2)
                                .foregroundColor(.white)
                        }
                        .accessibilityLabel(NSLocalizedString("accessibility.skip.backward", comment: "Skip backward"))
                        .accessibilityHint(NSLocalizedString("accessibility.skip.backward.hint", comment: "Skip backward hint"))
                        
                        Button(action: {
                            Task {
                                await viewModel.togglePlayPause()
                            }
                        }) {
                            Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(Color(hex: "3b82f6"))
                        }
                        .accessibilityLabel(viewModel.isPlaying ? 
                            NSLocalizedString("accessibility.pause.button", comment: "Pause button") : 
                            NSLocalizedString("accessibility.play.button", comment: "Play button"))
                        .accessibilityHint(viewModel.isPlaying ? 
                            NSLocalizedString("accessibility.pause.hint", comment: "Pause hint") : 
                            NSLocalizedString("accessibility.play.hint", comment: "Play hint"))
                        
                        Button(action: {
                            viewModel.skipForward()
                        }) {
                            Image(systemName: "goforward.10")
                                .font(.title2)
                                .foregroundColor(.white)
                        }
                        .accessibilityLabel(NSLocalizedString("accessibility.skip.forward", comment: "Skip forward"))
                        .accessibilityHint(NSLocalizedString("accessibility.skip.forward.hint", comment: "Skip forward hint"))
                    }
                    .padding(.bottom, 8)
                }
                .padding(.vertical)
                .background(.ultraThinMaterial)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            Task {
                await viewModel.loadAudio()
            }
        }
        .onChange(of: viewModel.note.transcript) { oldValue, newValue in
            // Update editedTranscript when transcript changes (e.g., transcription completes)
            if editedTranscript == oldValue || editedTranscript.isEmpty {
                editedTranscript = newValue
            }
        }
        .onChange(of: viewModel.note.title) { oldValue, newValue in
            // Update editedTitle when title changes
            if editedTitle == oldValue {
                editedTitle = newValue
            }
        }
        .onDisappear {
            Task {
                if editedTranscript != viewModel.note.transcript {
                    await viewModel.updateTranscript(editedTranscript)
                }
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
        #if canImport(UIKit)
        .sheet(isPresented: $showShareSheet) {
            ActivityViewController(activityItems: [viewModel.shareTranscript()])
        }
        #endif
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy, HH:mm"
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// UIActivityViewController wrapper for SwiftUI
#if canImport(UIKit)
struct ActivityViewController: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#endif
