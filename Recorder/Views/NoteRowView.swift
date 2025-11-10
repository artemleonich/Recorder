import SwiftUI

struct NoteRowView: View {
    let note: AudioNote
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title and date
            HStack {
                Text(note.title)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .truncationMode(.tail)
                
                Spacer()
                
                Text(formatDate(note.createdAt))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            // Duration and status
            HStack {
                // Duration
                HStack(spacing: 4) {
                    Image(systemName: "waveform")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text(formatDuration(note.duration))
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                // Transcription status
                HStack(spacing: 4) {
                    if note.isTranscriptionCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                        
                        Text(NSLocalizedString("note.status.completed", comment: "Completed status"))
                            .font(.caption)
                            .foregroundColor(.green)
                    } else {
                        Image(systemName: "hourglass")
                            .font(.caption)
                            .foregroundColor(.yellow)
                        
                        Text(NSLocalizedString("note.status.processing", comment: "Processing status"))
                            .font(.caption)
                            .foregroundColor(.yellow)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM, HH:mm"
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
