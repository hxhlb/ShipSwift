//
//  SWIntenseBling.swift
//  ShipSwift
//
//  Adapted from ShaderKit by James Rochabrun
//  https://github.com/jamesrochabrun/ShaderKit
//  Licensed under the MIT License. Copyright (c) James Rochabrun.
//  Original copyright and license notice retained as required by MIT.
//  See ShipSwift ACKNOWLEDGEMENTS for the full license text.
//
//  Wraps any view in a maximum-intensity holographic shimmer via a
//  SwiftUI Metal `layerEffect` — a dense diamond grid, multi-hue rainbow,
//  three moving hotspots and layered sparkles, all driven by a `tilt`
//  vector (e.g. from a `DragGesture`) for a "secret-rare card" look.
//
//  Requires iOS 17+ / macOS 14+ (SwiftUI `ShaderLibrary`,
//  `Shader`/`ShaderFunction`, Metal `stitchable`).
//
//  Usage:
//    // Default — internal animation only
//    SWIntenseBling {
//        Image("messi").resizable().scaledToFill()
//    }
//
//    // Tilt-driven from a DragGesture
//    SWIntenseBling(tilt: dragTilt) { cardArtwork }
//
//    // Demo / debug — gear button + live-tuning sheet.
//    // Requires an enclosing `NavigationStack`.
//    SWIntenseBling(showsControls: true) { cardArtwork }
//
//  Parameters:
//    - tilt: Light/parallax direction in roughly `-1...1` per axis,
//            usually drag-driven (default `.zero`).
//    - speed: Multiplier on the internal animation time (default `1.0`).
//    - showsControls: Attach a gear `ToolbarItem` that opens a live-tuning
//                     sheet (default `false`).
//
//  Note: This is the most intense of the foil family — it largely paints
//  over the source artwork. Best on bold, high-contrast card art.
//

import SwiftUI

// MARK: - Main View

struct SWIntenseBling<Content: View>: View {
    /// Light/parallax direction in roughly -1...1 per axis (drag-driven).
    var tilt: CGSize = .zero

    /// Multiplier on the internal animation time.
    var speed: Float = 1.0

    /// When `true`, attaches a gear `ToolbarItem` that opens a live-tuning sheet.
    var showsControls: Bool = false

    private let content: Content

    init(
        tilt: CGSize = .zero,
        speed: Float = 1.0,
        showsControls: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.tilt = tilt
        self.speed = speed
        self.showsControls = showsControls
        self.content = content()
    }

    var body: some View {
        if showsControls {
            SWIntenseBlingControlled(initial: self, content: content)
        } else {
            SWIntenseBlingRenderer(initial: self, content: content)
        }
    }
}

// MARK: - Renderer (pure shader binding)

private struct SWIntenseBlingRenderer<Content: View>: View {
    let initial: SWIntenseBling<Content>
    let content: Content

    @State private var start: Date = .now

    var body: some View {
        TimelineView(.animation) { ctx in
            let elapsed = Float(ctx.date.timeIntervalSince(start)) * initial.speed
            content.layerEffect(
                ShaderLibrary.swIntenseBling(
                    .boundingRect,
                    .float2(Float(initial.tilt.width), Float(initial.tilt.height)),
                    .float(elapsed)
                ),
                maxSampleOffset: .zero
            )
        }
    }
}

// MARK: - Controlled Wrapper (gear toolbar item + live sheet)

private struct SWIntenseBlingControlled<Content: View>: View {
    @State private var tiltX: Float
    @State private var tiltY: Float
    @State private var speed: Float

    @State private var showSheet = false

    private let content: Content

    init(initial: SWIntenseBling<Content>, content: Content) {
        _tiltX = State(initialValue: Float(initial.tilt.width))
        _tiltY = State(initialValue: Float(initial.tilt.height))
        _speed = State(initialValue: initial.speed)
        self.content = content
    }

    var body: some View {
        SWIntenseBlingRenderer(
            initial: SWIntenseBling(
                tilt: CGSize(width: CGFloat(tiltX), height: CGFloat(tiltY)),
                speed: speed
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
                .accessibilityLabel("Intense Bling Controls")
            }
        }
        .sheet(isPresented: $showSheet) {
            SWIntenseBlingControlsSheet(
                tiltX: $tiltX,
                tiltY: $tiltY,
                speed: $speed
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - Controls Sheet

private struct SWIntenseBlingControlsSheet: View {
    @Binding var tiltX: Float
    @Binding var tiltY: Float
    @Binding var speed: Float

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Tilt") {
                    SWIntenseBlingSliderRow(label: "Tilt X", value: $tiltX, range: -1...1, step: 0.01)
                    SWIntenseBlingSliderRow(label: "Tilt Y", value: $tiltY, range: -1...1, step: 0.01)
                }
                Section("Motion") {
                    SWIntenseBlingSliderRow(label: "Speed", value: $speed, range: 0...3, step: 0.05)
                }
            }
            .navigationTitle("Intense Bling")
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

private struct SWIntenseBlingSliderRow: View {
    let label: String
    @Binding var value: Float
    let range: ClosedRange<Float>
    let step: Float

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                Spacer()
                Text(String(format: "%.2f", value))
                    .font(.callout.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Slider(value: $value, in: range, step: step)
        }
    }
}

// MARK: - Preview

#Preview("Default") {
    NavigationStack {
        SWIntenseBling(showsControls: true) {
            RoundedRectangle(cornerRadius: 16)
                .fill(.black)
                .frame(width: 250, height: 350)
        }
    }
}
