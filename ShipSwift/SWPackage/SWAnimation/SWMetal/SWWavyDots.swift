//
//  SWWavyDots.swift
//  ShipSwift
//
//  Full-screen animated background of perspective dots on a wave-displaced
//  ground plane. Renders a 3D dot grid via a SwiftUI Metal shader — each
//  dot has soft halos, crest highlighting, vignetting, and a tunable horizon.
//  Designed as a hero / section background layer.
//
//  Requires iOS 17+ / macOS 14+ (SwiftUI `ShaderLibrary` + Metal `stitchable`).
//
//  Usage:
//    // Default — white dots on black, full-screen
//    ZStack {
//        SWWavyDots()
//            .ignoresSafeArea()
//        // Your content here
//    }
//
//    // As a section background
//    myContent
//        .background { SWWavyDots() }
//
//    // Custom tint / background and amplified waves
//    SWWavyDots(
//        tint: .cyan,
//        background: .black,
//        amplitude: 1.6,
//        gridDensity: 1.2
//    )
//
//  Parameters:
//    - tint: Color of dots and their halos (default `.white`)
//    - background: Color rendered below the horizon and behind the dots
//                  (default `.black`)
//    - speed: Time multiplier driving wave motion (default `1.0`)
//    - brightness: Multiplier applied to the tint color before mixing
//                  (default `1.0`)
//    - dotSize: Per-dot pixel radius multiplier (default `1.0`)
//    - gridDensity: Grid density multiplier — higher packs more dots
//                   into screen space (default `1.0`)
//    - patternScale: Spatial frequency multiplier for the wave pattern
//                    (default `1.0`)
//    - amplitude: Wave height multiplier (default `1.0`)
//    - depthFade: Strength of the per-dot depth attenuation, dimming
//                 farther dots (default `1.0`)
//    - vignette: Strength of the screen-edge vignette darkening
//                (default `1.0`, `0.0` disables)
//    - horizon: Vertical position of the horizon line in screen-aspect
//               units. Negative values raise the horizon (default `-0.45`)
//
//  Notes:
//    - Uses `TimelineView(.animation)` to drive the shader's time uniform.
//      Costs are paid per frame on the GPU — keep one instance per screen.
//    - The dot field extends from the horizon to the bottom of the view.
//      Place foreground content with enough opacity / contrast above the
//      horizon to stay legible against the moving pattern.
//
//  Created by Wei Zhong on 5/20/26.
//

import SwiftUI

struct SWWavyDots: View {
    /// Color of dots and their halos.
    var tint: Color = .white

    /// Color rendered below the horizon and behind the dots.
    var background: Color = .black

    /// Time multiplier driving wave motion.
    var speed: Float = 1.0

    /// Multiplier applied to the tint color before mixing.
    var brightness: Float = 1.0

    /// Per-dot pixel radius multiplier.
    var dotSize: Float = 1.0

    /// Grid density multiplier — higher packs more dots into screen space.
    var gridDensity: Float = 1.0

    /// Spatial frequency multiplier for the wave pattern.
    var patternScale: Float = 1.0

    /// Wave height multiplier.
    var amplitude: Float = 1.0

    /// Strength of the per-dot depth attenuation, dimming farther dots.
    var depthFade: Float = 1.0

    /// Strength of the screen-edge vignette darkening (0.0 disables).
    var vignette: Float = 1.0

    /// Vertical position of the horizon line in screen-aspect units.
    /// Negative values raise the horizon.
    var horizon: Float = -0.45

    @State private var start: Date = .now

    var body: some View {
        TimelineView(.animation) { ctx in
            let elapsed = Float(ctx.date.timeIntervalSince(start))

            // The base layer is solid `background` — the shader receives it
            // as `color` and blends the wave field on top per-pixel.
            background
                .colorEffect(
                    ShaderLibrary.swWavyDots(
                        .boundingRect,
                        .float(elapsed),
                        .float(speed),
                        .float(brightness),
                        .color(tint),
                        .color(background),
                        .float(dotSize),
                        .float(gridDensity),
                        .float(patternScale),
                        .float(vignette),
                        .float(horizon),
                        .float(amplitude),
                        .float(depthFade)
                    )
                )
        }
    }
}

// MARK: - Preview

#Preview("Default") {
    SWWavyDots()
        .ignoresSafeArea()
}

#Preview("Cyan / Dense") {
    SWWavyDots(
        tint: .cyan,
        gridDensity: 1.3,
        amplitude: 1.4
    )
    .ignoresSafeArea()
}

#Preview("Warm Sunset") {
    SWWavyDots(
        tint: .orange,
        background: Color(red: 0.08, green: 0.02, blue: 0.12),
        brightness: 1.1,
        amplitude: 1.6,
        horizon: -0.35
    )
    .ignoresSafeArea()
}
