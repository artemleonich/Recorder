import SwiftUI

struct NoteRowView: View {
    let note: AudioNote
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.locale) private var locale

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title and date
            HStack {
                Text(note.title)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Spacer()

                Text(formatDate(note.createdAt))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Duration and status
            HStack {
                // Duration
                HStack(spacing: 4) {
                    Image(systemName: "waveform")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(formatDuration(note.duration))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Transcription status
                HStack(spacing: 4) {
                    if note.isTranscriptionCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)

                        Text("note.status.completed")
                            .font(.caption)
                            .foregroundColor(.green)
                    } else {
                        Image(systemName: "hourglass")
                            .font(.caption)
                            .foregroundColor(.yellow)

                        Text("note.status.processing")
                            .font(.caption)
                            .foregroundColor(.yellow)
                    }
                }
            }
        }
        .padding()
        .background(
            Group {
                if colorScheme == .dark {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                } else {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.secondarySystemGroupedBackground))
                }
            }
        )
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM, HH:mm"
        formatter.locale = locale
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

}
