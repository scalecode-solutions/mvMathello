#include <metal_stdlib>
using namespace metal;

// Radial sunburst played over a freshly-placed pentomino. Drives a transparent
// overlay via SwiftUI `.colorEffect`. `progress` is 0...1 across the burst;
// `intensity` (0...1) scales the reach with the score banked; `seed` varies the
// ray pattern per placement.

[[ stitchable ]]
half4 hailstoneBurst(float2 position, half4 color, float2 size, float progress, float intensity, float seed) {
    float2 c = size * 0.5;
    float minDim = min(size.x, size.y);
    float2 d = (position - c) / (minDim * 0.5);
    float r = length(d);
    float theta = atan2(d.y, d.x);

    float reach = mix(0.6h, 1.5h, half(intensity));
    float wave = 1.0 - smoothstep(progress * reach, progress * reach + 0.18, r);
    float ring = smoothstep(0.0, 0.06, progress) * smoothstep(reach + 0.4, 0.2, r);

    float spokes = abs(sin(theta * 9.0 + seed * 6.28));
    spokes = smoothstep(0.5, 1.0, spokes);

    float sparkleR = 0.55 + 0.3 * sin((floor(theta * 6.0) + seed * 13.0) * 12.9898);
    float sparkle = exp(-26.0 * pow(r - progress * sparkleR, 2.0));

    half3 hot = half3(1.0, 0.5, 0.78);
    half3 gold = half3(1.0, 0.86, 0.4);

    half rays = half(wave * ring * spokes);
    half spk = half(sparkle * wave);
    half alpha = clamp(rays * 0.65h + spk, 0.0h, 1.0h) * (1.0h - half(smoothstep(0.85, 1.0, progress)));

    half3 rgb = mix(hot, gold, spk);
    return half4(rgb, alpha);
}
