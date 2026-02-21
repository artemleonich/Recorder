//
//  NoteDetailView.swift
//  Recorder
//
//  Created by Артём Леонов on 11/10/25.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct NoteDetailView: View {
    @ObservedObject var viewModel: NoteDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.locale) private var locale
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
            LinearGradient(
                colors: backgroundGradient,
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.title3)
                            .foregroundColor(.accentColor)
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel(LocalizationHelper.string("accessibility.back.button", locale: locale))

                    Text("note.detail.title")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Spacer()

                    Menu {
                        Button(action: {
                            showShareSheet = true
                        }) {
                            Label("note.menu.share", systemImage: "square.and.arrow.up")
                        }

                        Button(role: .destructive, action: {
                        }) {
                            Label("notes.delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.title3)
                            .foregroundColor(.accentColor)
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel(LocalizationHelper.string("accessibility.menu.button", locale: locale))
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color(.systemGroupedBackground).opacity(colorScheme == .dark ? 0.6 : 0.9))

                ScrollView {
                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("note.field.title")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            TextField(LocalizedStringKey("note.field.title.placeholder"), text: $editedTitle)
                                .foregroundColor(.primary)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.secondarySystemGroupedBackground))
                                )
                                .onSubmit {
                                    Task {
                                        await viewModel.updateTitle(editedTitle)
                                    }
                                }
                                .accessibilityLabel(LocalizationHelper.string("accessibility.title.field", locale: locale))
                                .accessibilityHint(LocalizationHelper.string("accessibility.title.hint", locale: locale))
                        }
                        .padding(.horizontal)
                        .padding(.top)

                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(.secondary)

                            Text(formatDate(viewModel.note.createdAt))
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Spacer()

                            Image(systemName: "waveform")
                                .foregroundColor(.secondary)

                            Text(formatDuration(viewModel.note.duration))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)

                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("note.field.transcript")
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                Spacer()

                                if !viewModel.note.isTranscriptionCompleted {
                                    HStack(spacing: 4) {
                                        ProgressView()
                                            .scaleEffect(0.7)
                                            .tint(Color.accentColor)
                                        Text("note.status.processing")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }

                            if viewModel.note.isTranscriptionCompleted || !editedTranscript.isEmpty {
                                TextEditor(text: $editedTranscript)
                                    .foregroundColor(.primary)
                                    .scrollContentBackground(.hidden)
                                    .frame(minHeight: 200)
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color(.secondarySystemGroupedBackground))
                                    )
                                    .accessibilityLabel(LocalizationHelper.string("accessibility.transcript.field", locale: locale))
                                    .accessibilityHint(LocalizationHelper.string("accessibility.transcript.hint", locale: locale))
                            } else {
                                VStack(spacing: 12) {
                                    ProgressView()
                                        .tint(Color.accentColor)
                                    Text("note.transcription.inprogress")
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                }
                                .frame(minHeight: 200)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.secondarySystemGroupedBackground))
                                )
                            }
                        }
                        .padding(.horizontal)

                        Button(action: {
                            showShareSheet = true
                        }) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("note.share.button")
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(hex: "3b82f6"))
                            )
                        }
                        .accessibilityLabel(LocalizationHelper.string("accessibility.share.button", locale: locale))
                        .accessibilityHint(LocalizationHelper.string("accessibility.share.hint", locale: locale))
                        .padding(.horizontal)

                        Spacer()
                            .frame(height: 120)
                    }
                }

                VStack(spacing: 12) {
                    VStack(spacing: 4) {
                        Slider(
                            value: Binding(
                                get: { viewModel.currentTime },
                                set: { viewModel.seek(to: $0) }
                            ),
                            in: 0...max(viewModel.duration, 1)
                        )
                        .tint(Color(hex: "3b82f6"))
                        .accessibilityLabel(LocalizationHelper.string("accessibility.playback.slider", locale: locale))
                        .accessibilityValue(
                            LocalizationHelper.formattedString(
                                "accessibility.playback.value",
                                locale: locale,
                                formatDuration(viewModel.currentTime),
                                formatDuration(viewModel.duration)
                            )
                        )

                        HStack {
                            Text(formatDuration(viewModel.currentTime))
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Spacer()

                            Text(formatDuration(viewModel.duration))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal)

                    HStack(spacing: 40) {
                        Button(action: {
                            viewModel.skipBackward()
                        }) {
                            Image(systemName: "gobackward.10")
                                .font(.title2)
                                .foregroundColor(.accentColor)
                        }
                        .accessibilityLabel(LocalizationHelper.string("accessibility.skip.backward", locale: locale))
                        .accessibilityHint(LocalizationHelper.string("accessibility.skip.backward.hint", locale: locale))

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
                            LocalizationHelper.string("accessibility.pause.button", locale: locale) :
                            LocalizationHelper.string("accessibility.play.button", locale: locale))
                        .accessibilityHint(viewModel.isPlaying ?
                            LocalizationHelper.string("accessibility.pause.hint", locale: locale) :
                            LocalizationHelper.string("accessibility.play.hint", locale: locale))

                        Button(action: {
                            viewModel.skipForward()
                        }) {
                            Image(systemName: "goforward.10")
                                .font(.title2)
                                .foregroundColor(.accentColor)
                        }
                        .accessibilityLabel(LocalizationHelper.string("accessibility.skip.forward", locale: locale))
                        .accessibilityHint(LocalizationHelper.string("accessibility.skip.forward.hint", locale: locale))
                    }
                    .padding(.bottom, 8)
                }
                .padding(.vertical)
                .background(Color(.systemGroupedBackground).opacity(colorScheme == .dark ? 0.6 : 0.95))
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            Task {
                await viewModel.loadAudio()
            }
        }
        .onChange(of: viewModel.note.transcript) { oldValue, newValue in
            // Sync local edit state only if user hasn't made diverging edits
            if editedTranscript == oldValue || editedTranscript.isEmpty {
                editedTranscript = newValue
            }
        }
        .onChange(of: viewModel.note.title) { oldValue, newValue in
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
            Button("button.ok") {
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
        formatter.locale = locale
        return formatter.string(from: date)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
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
}

#if canImport(UIKit)
struct ActivityViewController: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#endif
