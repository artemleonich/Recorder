//
//  RecordingView.swift
//  Recorder
//
//  Created by Артём Леонов on 11/10/25.
//

import SwiftUI

struct RecordingView: View {
    @ObservedObject var viewModel: RecordingViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.locale) private var locale

    var body: some View {
        ZStack {
            LinearGradient(
                colors: backgroundGradient,
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 40) {
                HStack {
                    Text("app.title")
                        .font(.title2)
                        .fontWeight(.bold)

                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 20)

                Spacer()

                Text(formatDuration(viewModel.duration))
                    .font(.system(size: 72, weight: .bold))
                    .monospacedDigit()

                WaveformView(audioLevel: viewModel.audioLevel)
                    .frame(height: 100)
                    .padding(.horizontal, 40)

                Button(action: {
                    Task {
                        if viewModel.isRecording {
                            await viewModel.stopRecording()
                        } else {
                            await viewModel.startRecording()
                        }
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: "FF3B30"))
                            .frame(width: 80, height: 80)
                            .scaleEffect(viewModel.isRecording && !reduceMotion ? 1.1 : 1.0)
                            .animation(
                                viewModel.isRecording && !reduceMotion ?
                                    .easeInOut(duration: 0.8).repeatForever(autoreverses: true) :
                                    .default,
                                value: viewModel.isRecording
                            )

                        if viewModel.isRecording {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(.white)
                                .frame(width: 24, height: 24)
                        } else {
                            Circle()
                                .fill(.white)
                                .frame(width: 24, height: 24)
                        }
                    }
                }
                .disabled(viewModel.isTranscribing)
                .accessibilityLabel(viewModel.isRecording ?
                    LocalizationHelper.string("accessibility.recording.stop", locale: locale) :
                    LocalizationHelper.string("accessibility.recording.start", locale: locale))
                .accessibilityHint(viewModel.isRecording ?
                    LocalizationHelper.string("accessibility.recording.stop.hint", locale: locale) :
                    LocalizationHelper.string("accessibility.recording.start.hint", locale: locale))

                Text(statusText)
                    .font(.body)
                    .foregroundColor(.secondary)

                if viewModel.isTranscribing {
                    VStack(spacing: 8) {
                        ProgressView(value: viewModel.transcriptionProgress)
                            .tint(Color.accentColor)
                            .frame(width: 200)
                            .accessibilityValue(
                                LocalizationHelper.formattedString(
                                    "accessibility.transcription.progress.value",
                                    locale: locale,
                                    Int(viewModel.transcriptionProgress * 100)
                                )
                            )

                        Text("recording.transcription.progress \(Int(viewModel.transcriptionProgress * 100))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()
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
    }

    private var statusText: LocalizedStringKey {
        if viewModel.isTranscribing {
            return "recording.status.processing"
        } else if viewModel.isRecording {
            return "recording.status.recording"
        } else {
            return "recording.status.idle"
        }
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
                Color(hex: "2a0a1e"),
                Color(hex: "0d0d0d"),
                Color(hex: "111827")
            ]
        default:
            return [
                Color(.systemBackground),
                Color(.systemGroupedBackground)
            ]
        }
    }
}
