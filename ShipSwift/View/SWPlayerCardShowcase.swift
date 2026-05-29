//
//  SWPlayerCardShowcase.swift
//  ShipSwift
//
//  A "trading-card" showcase for the ShaderKit-derived foil family
//  (SWFoil / SWGlitter / SWIntenseBling / SWChromaticGlass /
//  SWPolishedAluminum). Each card pages through a poker-card-proportioned
//  player portrait with one holographic finish applied. Dragging a card
//  feeds a normalized tilt into the shader and a matching 3D rotation, so
//  the highlight sweeps across the surface like a real holographic card.
//
//  Demo / showcase only — not a reusable SWPackage component. It exists to
//  demonstrate the foil shaders on real artwork inside the component gallery.
//
//  Requires iOS 17+ / macOS 14+.
//

import SwiftUI

// MARK: - Effect Catalog

/// The five holographic finishes shown in the carousel.
private enum CardEffect: Int, CaseIterable, Identifiable {
    case foil
    case glitter
    case intenseBling
    case chromaticGlass
    case polishedAluminum

    var id: Int { rawValue }

    /// Display name shown under the carousel.
    var title: String {
        switch self {
        case .foil:             return "Foil"
        case .glitter:          return "Glitter"
        case .intenseBling:     return "Intense Bling"
        case .chromaticGlass:   return "Chromatic Glass"
        case .polishedAluminum: return "Polished Aluminum"
        }
    }

    /// Asset name for the portrait — Messi / Ronaldo alternate across effects.
    var imageName: String {
        rawValue.isMultiple(of: 2) ? "messi" : "ronaldo"
    }

    /// Player name printed on the card.
    var playerName: String {
        rawValue.isMultiple(of: 2) ? "LIONEL MESSI" : "CRISTIANO RONALDO"
    }

    /// Position line printed under the player name.
    var position: String {
        rawValue.isMultiple(of: 2) ? "FORWARD · #10" : "FORWARD · #7"
    }
}

// MARK: - Showcase Root

struct SWPlayerCardShowcase: View {
    @State private var selection: CardEffect = .foil

    var body: some View {
        ZStack {
            // Light stage keeps the segmented control and labels legible.
            LinearGradient(
                colors: [Color(red: 0.95, green: 0.96, blue: 0.98), Color(red: 0.85, green: 0.87, blue: 0.92)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer(minLength: 0)

                // Paged carousel — one card per effect.
                TabView(selection: $selection) {
                    ForEach(CardEffect.allCases) { effect in
                        SWPlayerCard(effect: effect)
                            .tag(effect)
                            .padding(.horizontal, 36)
                    }
                }
                #if os(iOS)
                .tabViewStyle(.page(indexDisplayMode: .never))
                #endif
                .frame(height: 480)

                // Effect name.
                Text(selection.title)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText())
                    .animation(.snappy, value: selection)

                // Effect picker — keeps the carousel and label in sync.
                Picker("Effect", selection: $selection) {
                    ForEach(CardEffect.allCases) { effect in
                        Text(effect.title).tag(effect)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                Text("Drag a card to tilt its holographic finish")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Spacer(minLength: 0)
            }
            .padding(.vertical, 24)
        }
        .navigationTitle("Player Cards")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .preferredColorScheme(.light)
    }
}

// MARK: - Single Card

private struct SWPlayerCard: View {
    let effect: CardEffect

    /// Live drag translation, reset to zero on release.
    @GestureState private var drag: CGSize = .zero

    /// Poker-card proportion (2.5 : 3.5).
    private let cardWidth: CGFloat = 280
    private var cardHeight: CGFloat { cardWidth * 3.5 / 2.5 }

    /// Normalized tilt in roughly -1...1 per axis, fed to the shader.
    private var tilt: CGSize {
        CGSize(
            width: max(-1, min(1, drag.width / 120)),
            height: max(-1, min(1, drag.height / 120))
        )
    }

    var body: some View {
        cardFace
            .frame(width: cardWidth, height: cardHeight)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                // Glossy rim that sells the laminated-card edge.
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [.white.opacity(0.7), .white.opacity(0.05), .white.opacity(0.4)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
            )
            .shadow(color: .black.opacity(0.5), radius: 24, x: 0, y: 18)
            // Tilt the whole card in 3D toward the drag direction.
            .rotation3DEffect(
                .degrees(Double(tilt.width) * 14),
                axis: (x: 0, y: 1, z: 0),
                perspective: 0.5
            )
            .rotation3DEffect(
                .degrees(Double(-tilt.height) * 14),
                axis: (x: 1, y: 0, z: 0),
                perspective: 0.5
            )
            .gesture(
                DragGesture()
                    .updating($drag) { value, state, _ in
                        state = value.translation
                    }
            )
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: drag)
    }

    /// The artwork + text composited, then run through the chosen shader.
    @ViewBuilder
    private var cardFace: some View {
        let content = artwork

        switch effect {
        case .foil:
            SWFoil(tilt: tilt, intensity: 1.0) { content }
        case .glitter:
            SWGlitter(tilt: tilt, density: 70) { content }
        case .intenseBling:
            SWIntenseBling(tilt: tilt) { content }
        case .chromaticGlass:
            SWChromaticGlass(tilt: tilt, intensity: 0.7, separation: 0.5) { content }
        case .polishedAluminum:
            SWPolishedAluminum(tilt: tilt, intensity: 0.85) { content }
        }
    }

    /// Portrait fill + bottom name plate. Shares one layout for all effects.
    private var artwork: some View {
        ZStack(alignment: .bottomLeading) {
            // Portrait fill — uses Image(effect.imageName) directly. If the
            // asset is missing, fall back to a tinted symbol so the build
            // never breaks.
            cardImage
                .frame(width: cardWidth, height: cardHeight)
                .clipped()

            // Legibility scrim under the name plate.
            LinearGradient(
                colors: [.clear, .black.opacity(0.75)],
                startPoint: .center,
                endPoint: .bottom
            )

            // Name plate.
            VStack(alignment: .leading, spacing: 4) {
                Text(effect.playerName)
                    .font(.title3.weight(.heavy))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)

                Text(effect.position)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.8))
                    .tracking(1.5)
            }
            .padding(18)
        }
        .background(Color.black)
    }

    /// Resolves the portrait asset, with a SF Symbol placeholder fallback.
    @ViewBuilder
    private var cardImage: some View {
        #if canImport(UIKit)
        if UIImage(named: effect.imageName) != nil {
            Image(effect.imageName)
                .resizable()
                .scaledToFill()
        } else {
            placeholder
        }
        #else
        Image(effect.imageName)
            .resizable()
            .scaledToFill()
        #endif
    }

    /// Tinted placeholder used only if the portrait asset is absent.
    private var placeholder: some View {
        ZStack {
            LinearGradient(
                colors: [.indigo, .purple],
                startPoint: .top,
                endPoint: .bottom
            )
            Image(systemName: "figure.soccer")
                .font(.system(size: 120))
                .foregroundStyle(.white.opacity(0.8))
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SWPlayerCardShowcase()
    }
}
