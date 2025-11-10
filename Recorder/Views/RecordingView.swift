import SwiftUI

struct RecordingView: View {
    @ObservedObject var viewModel: RecordingViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [
                    Color(hex: "2a0a1e"),
                    Color(hex: "0d0d0d"),
                    Color(hex: "111827")
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Blurred circles background
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.3))
                    .frame(width: 300, height: 300)
                    .blur(radius: 100)
                    .offset(x: -100, y: -200)
                
                Circle()
                    .fill(Color.blue.opacity(0.3))
                    .frame(width: 300, height: 300)
                    .blur(radius: 100)
                    .offset(x: 100, y: 200)
            }
            
            VStack(spacing: 40) {
                // Header
                HStack {
                    Text(NSLocalizedString("app.title", comment: "App title"))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .shadow(color: .white.opacity(0.5), radius: 10)
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 20)
                
                Spacer()
                
                // Timer
                Text(formatDuration(viewModel.duration))
                    .font(.system(size: 72, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: .white.opacity(0.5), radius: 20)
                    .monospacedDigit()
                
                // Waveform
                WaveformView(audioLevel: viewModel.audioLevel)
                    .frame(height: 100)
                    .padding(.horizontal, 40)
                
                // Record button
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
                    NSLocalizedString("accessibility.recording.stop", comment: "Stop recording") : 
                    NSLocalizedString("accessibility.recording.start", comment: "Start recording"))
                .accessibilityHint(viewModel.isRecording ? 
                    NSLocalizedString("accessibility.recording.stop.hint", comment: "Stop recording hint") : 
                    NSLocalizedString("accessibility.recording.start.hint", comment: "Start recording hint"))
                
                // Status text
                Text(statusText)
                    .font(.body)
                    .foregroundColor(.white.opacity(0.7))
                
                // Transcription progress
                if viewModel.isTranscribing {
                    VStack(spacing: 8) {
                        ProgressView(value: viewModel.transcriptionProgress)
                            .tint(.white)
                            .frame(width: 200)
                            .accessibilityValue(String(format: NSLocalizedString("accessibility.transcription.progress.value", comment: "Transcription progress value"), Int(viewModel.transcriptionProgress * 100)))
                        
                        Text(String(format: NSLocalizedString("recording.transcription.progress", comment: "Transcription progress"), Int(viewModel.transcriptionProgress * 100)))
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
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
            Button(NSLocalizedString("button.ok", comment: "OK button")) {
                viewModel.error = nil
            }
        } message: { error in
            if let suggestion = error.recoverySuggestion {
                Text(suggestion)
            }
        }
    }
    
    private var statusText: String {
        if viewModel.isTranscribing {
            return NSLocalizedString("recording.status.processing", comment: "Processing status")
        } else if viewModel.isRecording {
            return NSLocalizedString("recording.status.recording", comment: "Recording status")
        } else {
            return NSLocalizedString("recording.status.idle", comment: "Idle status")
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
