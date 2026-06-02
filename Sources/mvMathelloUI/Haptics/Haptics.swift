import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Thin wrapper over the platform haptic generators. No-ops where UIKit is
/// unavailable (e.g. macOS test runs).
public enum Haptics {
    public enum Event: Sendable {
        case place
        case bigScore
        case golden
        case rotate
        case gameOver
        case illegal
    }

    public static func play(_ event: Event) {
        #if canImport(UIKit)
        switch event {
        case .place:    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case .bigScore: UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        case .golden:   UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .rotate:   UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .gameOver: UINotificationFeedbackGenerator().notificationOccurred(.error)
        case .illegal:  UINotificationFeedbackGenerator().notificationOccurred(.warning)
        }
        #endif
    }
}
