import SwiftUI
import mvMathelloUI

@main
struct mvMathelloDemoApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .mathelloTheme(.neonFractal)
                .preferredColorScheme(.dark)
        }
    }
}
