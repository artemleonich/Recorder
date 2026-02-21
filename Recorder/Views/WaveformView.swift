//
//  WaveformView.swift
//  Recorder
//
//  Created by Артём Леонов on 11/10/25.
//

import SwiftUI

struct WaveformView: View {
    let audioLevel: Float

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let barCount: Int = 40
    private let barSpacing: CGFloat = 4
    private let minBarHeight: CGFloat = 4
    private let maxBarHeightMultiplier: CGFloat = 1.0
    private let animationDuration: Double = 0.05

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

    private func barHeight(for index: Int, in geometry: GeometryProxy) -> CGFloat {
        let maxHeight = geometry.size.height * maxBarHeightMultiplier
        let normalizedLevel = normalizeAudioLevel(audioLevel)

        let phase = Double(index) / Double(barCount) * .pi * 2
        let waveOffset = sin(phase) * 0.3 + 0.7

        let heightMultiplier = normalizedLevel * waveOffset
        let calculatedHeight = maxHeight * heightMultiplier

        return max(minBarHeight, calculatedHeight)
    }

    // Maps dB level (-160...0) to 0...1, using -60...0 as the practical range
    private func normalizeAudioLevel(_ level: Float) -> CGFloat {
        let minDB: Float = -60.0
        let maxDB: Float = 0.0

        let clampedLevel = max(minDB, min(maxDB, level))
        let normalized = (clampedLevel - minDB) / (maxDB - minDB)

        return CGFloat(normalized)
    }

    private var barColor: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 1.0, green: 0.23, blue: 0.19),
                Color(red: 0.9, green: 0.1, blue: 0.1)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

// MARK: - Extracted Subviews

private struct BarView: View {
    let height: CGFloat
    let color: LinearGradient
    let reduceMotion: Bool

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(color)
            .frame(width: 3, height: height)
            .animation(reduceMotion ? .none : .easeInOut(duration: 0.05), value: height)
            .drawingGroup()
    }
}

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
