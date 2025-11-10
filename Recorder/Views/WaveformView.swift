//
//  WaveformView.swift
//  Recorder
//
//  Visual representation of audio waveform during recording
//

import SwiftUI

/// A view that displays an animated waveform visualization based on audio level
struct WaveformView: View {
    
    // MARK: - Properties
    
    /// Audio level in decibels (-160.0 to 0.0)
    let audioLevel: Float
    
    /// Environment variable for reduce motion accessibility setting
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    /// Number of bars to display in the waveform
    /// Optimized for 30+ FPS performance
    private let barCount: Int = 40
    
    /// Spacing between bars
    private let barSpacing: CGFloat = 4
    
    /// Minimum bar height
    private let minBarHeight: CGFloat = 4
    
    /// Maximum bar height multiplier
    private let maxBarHeightMultiplier: CGFloat = 1.0
    
    /// Animation duration optimized for smooth updates
    private let animationDuration: Double = 0.05
    
    // MARK: - Body
    
    var body: some View {
        GeometryReader { geometry in
            HStack(alignment: .center, spacing: barSpacing) {
                ForEach(0..<barCount, id: \.self) { index in
                    BarView(
                        height: barHeight(for: index, in: geometry),
                        color: barColor,
                        reduceMotion: reduceMotion
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    // MARK: - Private Methods
    
    /// Calculates the height for a bar at the given index
    private func barHeight(for index: Int, in geometry: GeometryProxy) -> CGFloat {
        let maxHeight = geometry.size.height * maxBarHeightMultiplier
        
        // Normalize audio level from -160...0 to 0...1
        let normalizedLevel = normalizeAudioLevel(audioLevel)
        
        // Create a wave pattern with variation across bars
        let phase = Double(index) / Double(barCount) * .pi * 2
        let waveOffset = sin(phase) * 0.3 + 0.7 // 0.4 to 1.0
        
        // Calculate bar height based on audio level and wave pattern
        let heightMultiplier = normalizedLevel * waveOffset
        let calculatedHeight = maxHeight * heightMultiplier
        
        return max(minBarHeight, calculatedHeight)
    }
    
    /// Normalizes audio level from decibels to 0...1 range
    private func normalizeAudioLevel(_ level: Float) -> CGFloat {
        // Audio level ranges from -160 (silence) to 0 (max)
        // We'll use -60 to 0 as the practical range
        let minDB: Float = -60.0
        let maxDB: Float = 0.0
        
        let clampedLevel = max(minDB, min(maxDB, level))
        let normalized = (clampedLevel - minDB) / (maxDB - minDB)
        
        return CGFloat(normalized)
    }
    
    /// Gradient color for active recording (red gradient)
    private var barColor: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 1.0, green: 0.23, blue: 0.19), // #FF3B30
                Color(red: 0.9, green: 0.1, blue: 0.1)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

// MARK: - Bar View

/// Individual bar in the waveform
private struct BarView: View {
    let height: CGFloat
    let color: LinearGradient
    let reduceMotion: Bool
    
    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(color)
            .frame(width: 3, height: height)
            .animation(reduceMotion ? .none : .easeInOut(duration: 0.05), value: height)
            .drawingGroup() // Optimize rendering by flattening into single layer
    }
}

// MARK: - Preview

#Preview("Idle") {
    WaveformView(audioLevel: -160)
        .frame(height: 100)
        .padding()
        .background(Color.black)
}

#Preview("Low Level") {
    WaveformView(audioLevel: -40)
        .frame(height: 100)
        .padding()
        .background(Color.black)
}

#Preview("Medium Level") {
    WaveformView(audioLevel: -20)
        .frame(height: 100)
        .padding()
        .background(Color.black)
}

#Preview("High Level") {
    WaveformView(audioLevel: -5)
        .frame(height: 100)
        .padding()
        .background(Color.black)
}
