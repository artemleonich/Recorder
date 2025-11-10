import SwiftUI

extension Color {
    /// Initialize a Color from a hex string
    /// - Parameter hex: Hex color string (e.g., "FF3B30", "#FF3B30", "3b82f6")
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    // MARK: - App Colors
    
    /// Primary app color - blue (#3b82f6)
    static var primary: Color {
        Color(hex: "3b82f6")
    }
    
    /// Alternative primary color - lighter blue (#197fe6)
    static var primaryAlt: Color {
        Color(hex: "197fe6")
    }
    
    /// Recording button red color (#FF3B30)
    static var recordRed: Color {
        Color(hex: "FF3B30")
    }
    
    /// Liquid glass effect color - semi-transparent white
    static var liquidGlass: Color {
        Color.white.opacity(0.05)
    }
    
    // MARK: - Background Gradients
    
    /// Recording screen gradient: from #2a0a1e via #0d0d0d to #111827
    static var recordingGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(hex: "2a0a1e"),
                Color(hex: "0d0d0d"),
                Color(hex: "111827")
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    /// Notes list screen gradient: from #1E1A4D via #111921 to #1C0F3A
    static var notesListGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(hex: "1E1A4D"),
                Color(hex: "111921"),
                Color(hex: "1C0F3A")
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    /// Note detail screen gradient: similar to notes list
    static var noteDetailGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(hex: "1E1A4D"),
                Color(hex: "111921"),
                Color(hex: "1C0F3A")
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    /// Settings screen gradient: dark gradient
    static var settingsGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.black,
                Color(hex: "0d0d0d"),
                Color(hex: "111827")
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    // MARK: - Blur Circle Colors
    
    /// Red blur circle for recording screen
    static var blurCircleRed: Color {
        Color(hex: "FF3B30").opacity(0.3)
    }
    
    /// Blue blur circle for recording screen
    static var blurCircleBlue: Color {
        Color(hex: "3b82f6").opacity(0.3)
    }
    
    /// Purple blur circle for notes screens
    static var blurCirclePurple: Color {
        Color(hex: "8B5CF6").opacity(0.3)
    }
    
    /// Cyan blur circle for notes screens
    static var blurCircleCyan: Color {
        Color(hex: "06B6D4").opacity(0.3)
    }
}
