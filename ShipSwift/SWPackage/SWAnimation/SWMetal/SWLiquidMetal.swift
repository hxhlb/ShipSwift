//
//  SWLiquidMetal.swift
//  ShipSwift
//
//  Port of Paper Design's liquid-metal shader
//  (https://shaders.paper.design/liquid-metal, original by Stephen Haney
//  for paper-design/liquid-logo) as a SwiftUI Metal `layerEffect`. Wraps
//  any view in a flowing chromatic liquid-metal effect: simplex noise
//  drives a stripe-pattern color split with refraction, edge-aware
//  bulge, and per-channel chromatic shift.
//
//  Best paired with a bold, opaque silhouette (SF Symbol, logo) — the
//  effect uses the source's red channel as its edge mask, so vector
//  shapes against transparent background work cleanest.
//
//  Reference Metal port: bobek-balinek/LiquidMetalShader (MIT).
//
//  Requires iOS 17+ / macOS 14+ (SwiftUI `ShaderLibrary`,
//  `Shader`/`ShaderFunction`, Metal `stitchable`).
//
//  Usage:
//    // Default — flowing chrome over the Apple logo
//    SWLiquidMetal {
//        Image(systemName: "apple.logo")
//            .font(.system(size: 300))
//    }
//
//    // Subtler refraction, slower
//    SWLiquidMetal(
//        refraction: 0.003,
//        timeScale: 0.1
//    ) {
//        Image(systemName: "swift")
//            .font(.system(size: 300))
//    }
//
//    // Demo / debug — adds a gear button that opens a live-tuning sheet.
//    // Requires an enclosing `NavigationStack`.
//    SWLiquidMetal(showsControls: true) {
//        Image(systemName: "apple.logo")
//            .font(.system(size: 300))
//    }
//
//  Parameters:
//    - speed: Multiplier on the internal animation time (default `1.0`).
//    - refraction: Strength of the per-channel chromatic split in
//                  `0...0.06` (default `0.008`).
//    - edge: Edge mask sharpness in `0...1` — higher = tighter edge
//            opacity falloff (default `0.8`).
//    - liquid: Noise distortion strength in `0...1` (default `0.7`).
//    - patternBlur: Stripe band softness in `0...0.05` (default `0.005`).
//    - patternScale: Stripe density in `1...10` — small = wider stripes,
//                    large = denser (default `5.0`).
//    - timeScale: Base animation speed multiplier in `0...2`
//                 (default `0.2`).
//    - showsControls: Attach a gear `ToolbarItem` that opens a
//                     live-tuning sheet (default `false`).
//
//  Created by Wei Zhong on 5/25/26.
//

import SwiftUI

// MARK: - Main View

struct SWLiquidMetal<Content: View>: View {
    /// Multiplier on the internal animation time.
    var speed: Float = 1.0

    /// Strength of the per-channel chromatic split (0...0.06 reasonable).
    var refraction: Float = 0.008

    /// Edge mask sharpness in 0...1.
    var edge: Float = 0.8

    /// Noise distortion strength in 0...1.
    var liquid: Float = 0.1

    /// Stripe band softness in 0...0.05.
    var patternBlur: Float = 0.005

    /// Stripe density in 1...10.
    var patternScale: Float = 1

    /// Base animation speed multiplier in 0...2.
    var timeScale: Float = 0.2

    /// When `true`, attaches a gear `ToolbarItem` that opens a live-tuning sheet.
    var showsControls: Bool = false

    private let content: Content

    init(
        speed: Float = 1.0,
        refraction: Float = 0.008,
        edge: Float = 0.8,
        liquid: Float = 0.3,
        patternBlur: Float = 0.005,
        patternScale: Float = 2.5,
        timeScale: Float = 0.2,
        showsControls: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.speed = speed
        self.refraction = refraction
        self.edge = edge
        self.liquid = liquid
        self.patternBlur = patternBlur
        self.patternScale = patternScale
        self.timeScale = timeScale
        self.showsControls = showsControls
        self.content = content()
    }

    var body: some View {
        if showsControls {
            SWLiquidMetalControlled(initial: self, content: content)
        } else {
            SWLiquidMetalRenderer(initial: self, content: content)
        }
    }
}

// MARK: - Renderer

private struct SWLiquidMetalRenderer<Content: View>: View {
    let initial: SWLiquidMetal<Content>
    let content: Content

    @State private var start: Date = .now

    var body: some View {
        TimelineView(.animation) { ctx in
            let elapsed = Float(ctx.date.timeIntervalSince(start))
            // The shader only samples the layer at the current pixel
            // (and reads layer.r for the edge mask) — no need for any
            // sample offset budget.
            content.layerEffect(
                ShaderLibrary.swLiquidMetal(
                    .boundingRect,
                    .float(elapsed),
                    .float(initial.speed),
                    .float(initial.refraction),
                    .float(initial.edge),
                    .float(initial.liquid),
                    .float(initial.patternBlur),
                    .float(initial.patternScale),
                    .float(initial.timeScale)
                ),
                maxSampleOffset: .zero
            )
        }
    }
}

// MARK: - Controlled Wrapper (gear toolbar item + live sheet)

private struct SWLiquidMetalControlled<Content: View>: View {
    @State private var speed: Float
    @State private var refraction: Float
    @State private var edge: Float
    @State private var liquid: Float
    @State private var patternBlur: Float
    @State private var patternScale: Float
    @State private var timeScale: Float

    @State private var showSheet = false

    private let content: Content

    init(initial: SWLiquidMetal<Content>, content: Content) {
        _speed        = State(initialValue: initial.speed)
        _refraction   = State(initialValue: initial.refraction)
        _edge         = State(initialValue: initial.edge)
        _liquid       = State(initialValue: initial.liquid)
        _patternBlur  = State(initialValue: initial.patternBlur)
        _patternScale = State(initialValue: initial.patternScale)
        _timeScale    = State(initialValue: initial.timeScale)
        self.content = content
    }

    var body: some View {
        SWLiquidMetalRenderer(
            initial: SWLiquidMetal(
                speed: speed,
                refraction: refraction,
                edge: edge,
                liquid: liquid,
                patternBlur: patternBlur,
                patternScale: patternScale,
                timeScale: timeScale
            ) { content },
            content: content
        )
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showSheet = true
                } label: {
                    Image(systemName: "slider.horizontal.3")
                }
                .accessibilityLabel("Liquid Metal Controls")
            }
        }
        .sheet(isPresented: $showSheet) {
            SWLiquidMetalControlsSheet(
                speed: $speed,
                refraction: $refraction,
                edge: $edge,
                liquid: $liquid,
                patternBlur: $patternBlur,
                patternScale: $patternScale,
                timeScale: $timeScale
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - Controls Sheet

private struct SWLiquidMetalControlsSheet: View {
    @Binding var speed: Float
    @Binding var refraction: Float
    @Binding var edge: Float
    @Binding var liquid: Float
    @Binding var patternBlur: Float
    @Binding var patternScale: Float
    @Binding var timeScale: Float

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Pattern") {
                    SliderRow(label: "Refraction",    value: $refraction,   range: 0...0.06,   step: 0.001)
                    SliderRow(label: "Edge",          value: $edge,         range: 0...1,      step: 0.01)
                    SliderRow(label: "Liquid",        value: $liquid,       range: 0...1,      step: 0.01)
                    SliderRow(label: "Pattern Blur",  value: $patternBlur,  range: 0...0.05,   step: 0.001)
                    SliderRow(label: "Pattern Scale", value: $patternScale, range: 1...10,     step: 0.1)
                }

                Section("Motion") {
                    SliderRow(label: "Time Scale", value: $timeScale, range: 0...2, step: 0.01)
                    SliderRow(label: "Speed",      value: $speed,     range: 0...3, step: 0.05)
                }
            }
            .navigationTitle("Liquid Metal")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

private struct SliderRow: View {
    let label: String
    @Binding var value: Float
    let range: ClosedRange<Float>
    let step: Float

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                Spacer()
                Text(String(format: step < 0.01 ? "%.3f" : "%.2f", value))
                    .font(.callout.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Slider(value: $value, in: range, step: step)
        }
    }
}

// MARK: - Preview

#Preview("Apple logo") {
    NavigationStack {
        SWLiquidMetal(showsControls: true) {
            Image(systemName: "apple.logo")
                .font(.system(size: 300))
        }
        .shadow(radius: 10)
    }
}

#Preview("Swift logo") {
    SWLiquidMetal {
        Image(systemName: "swift")
            .font(.system(size: 300))
    }
}
