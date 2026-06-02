import SwiftUI
import mvMathelloUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 28) {
                VStack(spacing: 6) {
                    Text("Mathello")
                        .font(.system(size: 44, weight: .heavy, design: .rounded))
                    Text("pentominoes · Collatz · Pascal · φ")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: 14) {
                    NavigationLink {
                        HailstormGameView(rows: 12, duration: 90)
                    } label: {
                        modeLabel("Hailstorm", "arcade · score the hailstones")
                    }
                    NavigationLink {
                        ParityGameView(rows: 10)
                    } label: {
                        modeLabel("Parity", "2-player · claim the territory")
                    }
                    NavigationLink {
                        FractalGameView(rows: 12)
                    } label: {
                        modeLabel("Fractal", "solo · blanket the Sierpiński")
                    }
                    NavigationLink {
                        ChainsGameView(rows: 12)
                    } label: {
                        modeLabel("Chains", "solo · snake the ×φ combo")
                    }
                }
                .padding(.horizontal)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black.ignoresSafeArea())
        }
        .preferredColorScheme(.dark)
    }

    private func modeLabel(_ title: String, _ subtitle: String) -> some View {
        VStack(spacing: 3) {
            Text(title).font(.title2.bold())
            Text(subtitle).font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
        .foregroundStyle(.white)
    }
}

#Preview {
    ContentView()
        .mathelloTheme(.neonFractal)
}
