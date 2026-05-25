//
//  SWLiquidMetal.metal
//  ShipSwift
//
//  Stitchable SwiftUI layerEffect — port of Paper Design's liquid-metal
//  (https://shaders.paper.design/liquid-metal, original by Stephen Haney
//  for paper-design/liquid-logo). Wraps any view (typically an SF Symbol)
//  in a flowing chromatic liquid-metal effect: simplex noise drives a
//  stripe-pattern color split with refraction, edge-aware bulge, and
//  per-channel chromatic shift.
//
//  Reference Metal port:
//    https://github.com/bobek-balinek/LiquidMetalShader (MIT-style fork
//    of the original WebGL fragment shader). Function names adapted to
//    the SW prefix and layer-size sourcing switched from `layer.tex.get_*`
//    to the `boundingRect` parameter (more portable across SwiftUI shader
//    APIs).
//
//  Paired with: SWLiquidMetal.swift
//  Entry point: `swLiquidMetal` — invoked via SwiftUI `.layerEffect(...)`.
//  Requires iOS 17+ / macOS 14+.
//

#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// =============================================================================
// MARK: - Constants & shared helpers
// =============================================================================

constant float SWLM_PI = 3.14159265358979323846;
constant float4 SWLM_C = float4(0.211324865405187,
                                 0.366025403784439,
                                -0.577350269189626,
                                 0.024390243902439);

static float3 swLM_mod289v3(float3 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
static float2 swLM_mod289v2(float2 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
static float3 swLM_permute(float3 x)  { return swLM_mod289v3(((x * 34.0) + 1.0) * x); }

// 2D simplex noise (Ashima Arts / Stefan Gustavson, public domain).
static float swLM_snoise(float2 v) {
    float2 i = floor(v + dot(v, SWLM_C.yy));
    float2 x0 = v - i + dot(i, SWLM_C.xx);
    float2 i1 = (x0.x > x0.y) ? float2(1.0, 0.0) : float2(0.0, 1.0);
    float4 x12 = x0.xyxy + SWLM_C.xxzz;
    x12.xy -= i1;
    i = swLM_mod289v2(i);
    float3 p = swLM_permute(swLM_permute(i.y + float3(0.0, i1.y, 1.0))
                                       + i.x + float3(0.0, i1.x, 1.0));
    float3 m = max(0.5 - float3(dot(x0, x0),
                                 dot(x12.xy, x12.xy),
                                 dot(x12.zw, x12.zw)), 0.0);
    m = m * m;
    m = m * m;
    float3 x = 2.0 * fract(p * SWLM_C.www) - 1.0;
    float3 h = abs(x) - 0.5;
    float3 ox = floor(x + 0.5);
    float3 a0 = x - ox;
    m *= 1.79284291400159 - 0.85373472095314 * (a0 * a0 + h * h);
    float3 g;
    g.x  = a0.x  * x0.x   + h.x  * x0.y;
    g.yz = a0.yz * x12.xz + h.yz * x12.yw;
    return 130.0 * dot(m, g);
}

static float2 swLM_rotate(float2 uv, float th) {
    float2x2 m = float2x2(cos(th), sin(th), -sin(th), cos(th));
    return m * uv;
}

// Soft alpha falloff at the layer's outer 10% (per Paper original).
static float swLM_imgFrameAlpha(float2 uv, float frameWidth) {
    float f = smoothstep(0.0, frameWidth, uv.x)
            * smoothstep(1.0, 1.0 - frameWidth, uv.x);
    f *= smoothstep(0.0, frameWidth, uv.y)
       * smoothstep(1.0, 1.0 - frameWidth, uv.y);
    return f;
}

// Per-channel color resolver — Paper's `get_color_channel`. Threads the
// stripe pattern through 5 alternating smoothstep bands plus a trailing
// gradient. `c1` / `c2` are the two endpoint colors (light vs. dark),
// `stripePos` is the wrapped UV along the stripe direction, `w` packs
// the stripe widths, `extraBlur` lets the caller widen the per-channel
// band edge for chromatic split, and `bulge` modulates which bands the
// stripe enters.
static float swLM_getColorChannel(float c1, float c2,
                                  float stripePos,
                                  float3 w,
                                  float extraBlur,
                                  float bulge,
                                  float patternBlur) {
    float ch = c2;
    float blur = patternBlur + extraBlur;
    ch = mix(ch, c1, smoothstep(0.0, blur, stripePos));

    float border = w[0];
    ch = mix(ch, c2, smoothstep(border - blur, border + blur, stripePos));

    float b = smoothstep(0.2, 0.8, bulge);
    border = w[0] + 0.4 * (1.0 - b) * w[1];
    ch = mix(ch, c1, smoothstep(border - blur, border + blur, stripePos));

    border = w[0] + 0.5 * (1.0 - b) * w[1];
    ch = mix(ch, c2, smoothstep(border - blur, border + blur, stripePos));

    border = w[0] + w[1];
    ch = mix(ch, c1, smoothstep(border - blur, border + blur, stripePos));

    float gradientT = (stripePos - w[0] - w[1]) / w[2];
    float gradient  = mix(c1, c2, smoothstep(0.0, 1.0, gradientT));
    ch = mix(ch, gradient, smoothstep(border - blur, border + blur, stripePos));
    return ch;
}

// =============================================================================
// MARK: - swLiquidMetal
// =============================================================================

[[ stitchable ]] half4 swLiquidMetal(float2 position,
                                     SwiftUI::Layer layer,
                                     float4 boundingRect,
                                     float  time,
                                     float  speed,
                                     float  refraction,    // 0..0.06 reasonable
                                     float  edge,          // 0..1 edge sharpness
                                     float  liquid,        // 0..1 noise strength
                                     float  patternBlur,   // 0..0.05 band softness
                                     float  patternScale,  // 1..10 stripe density
                                     float  timeScale) {   // 0..2 animation rate
    float2 sz = boundingRect.zw;
    float2 uvRaw = position / max(sz, float2(1.0));
    float2 uv = uvRaw;

    half4 img = layer.sample(position);
    if (img.a == 0.0) {
        return img;
    }

    // Core shader (Paper / Stephen Haney algorithm, structurally
    // unchanged from the published WebGL fragment).
    float diagonal = uv.x - uv.y;
    float t = timeScale * speed * time;

    float3 color1 = float3(0.98, 0.98, 1.0);
    float3 color2 = float3(0.1, 0.1, 0.1 + 0.1 * smoothstep(0.7, 1.3, uv.x + uv.y));
    float pixelEdge = float(img.r);   // use red channel of the source as the edge mask

    float2 gradUV = uv - 0.5;
    float dist = length(gradUV + float2(0.0, 0.2 * diagonal));
    gradUV = swLM_rotate(gradUV, (0.25 - 0.2 * diagonal) * SWLM_PI);

    float bulge = pow(1.8 * dist, 1.2);
    bulge = 1.0 - bulge;
    bulge *= pow(uv.y, 0.3);

    float cycleWidth = max(patternScale, 1e-4);
    float thin1Ratio = 0.12 / cycleWidth * (1.0 - 0.4 * bulge);
    float thin2Ratio = 0.07 / cycleWidth * (1.0 + 0.4 * bulge);
    float wideRatio  = 1.0 - thin1Ratio - thin2Ratio;
    float thin1Width = cycleWidth * thin1Ratio;
    float thin2Width = cycleWidth * thin2Ratio;

    float opacity = 1.0 - smoothstep(0.9 - 0.5 * saturate(edge),
                                     1.0 - 0.5 * saturate(edge), pixelEdge);
    opacity *= swLM_imgFrameAlpha(uvRaw, 0.1);

    float noise = swLM_snoise(uv - float2(t, t));
    pixelEdge += (1.0 - pixelEdge) * saturate(liquid) * noise;

    float refr = clamp(1.0 - bulge, 0.0, 1.0);
    float dir = gradUV.x + diagonal;
    dir -= 2.0 * noise * diagonal *
           (smoothstep(0.0, 1.0, pixelEdge) * smoothstep(1.0, 0.0, pixelEdge));
    bulge *= clamp(pow(uv.y, 0.1), 0.3, 1.0);
    dir *= (0.1 + (1.1 - pixelEdge) * bulge);
    dir *= smoothstep(1.0, 0.7, pixelEdge);
    dir += 0.18 * (smoothstep(0.1, 0.2, uv.y) * smoothstep(0.4, 0.2, uv.y));
    dir += 0.03 * (smoothstep(0.1, 0.2, 1.0 - uv.y) *
                   smoothstep(0.4, 0.2, 1.0 - uv.y));
    dir *= (0.5 + 0.5 * pow(uv.y, 2.0));
    dir *= cycleWidth;
    dir -= t;

    float refr_r = refr + 0.03 * bulge * noise;
    float refr_b = 1.3 * refr;
    refr_r += 5.0 *
              (smoothstep(-0.1, 0.2, uv.y) * smoothstep(0.5, 0.1, uv.y)) *
              (smoothstep( 0.4, 0.6, bulge) * smoothstep(1.0, 0.4, bulge));
    refr_r -= diagonal;
    refr_b += (smoothstep(0.0, 0.4, uv.y) * smoothstep(0.8, 0.1, uv.y)) *
              (smoothstep(0.4, 0.6, bulge) * smoothstep(0.8, 0.4, bulge));
    refr_b -= 0.2 * pixelEdge;
    refr_r *= saturate(refraction);
    refr_b *= saturate(refraction);

    float3 w = float3(thin1Width, thin2Width, wideRatio);
    w[1] -= 0.02 * smoothstep(0.0, 1.0, pixelEdge + bulge);

    float stripe_r = fract(dir + refr_r);
    float r = swLM_getColorChannel(color1.r, color2.r, stripe_r, w,
                                   0.02 + 0.03 * saturate(refraction) * bulge,
                                   bulge, patternBlur);
    float stripe_g = fract(dir);
    float g = swLM_getColorChannel(color1.g, color2.g, stripe_g, w,
                                   0.01 / max(1.0 - diagonal, 1e-4),
                                   bulge, patternBlur);
    float stripe_b = fract(dir - refr_b);
    float b = swLM_getColorChannel(color1.b, color2.b, stripe_b, w,
                                   0.01, bulge, patternBlur);

    return half4(half(r * opacity),
                 half(g * opacity),
                 half(b * opacity),
                 half(opacity));
}
