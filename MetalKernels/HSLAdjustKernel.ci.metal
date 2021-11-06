//
//  HSLAdjustKernel.metal
//  MetalKernels
//
//  Created by Владимир on 05.11.2021.
//

#include <metal_stdlib>

using namespace metal;

#include <CoreImage/CoreImage.h>

/// Converts colors from HSL to linear RGB.
/// Based on work by Sam Hocevar and Emil Persson.
half3 hslToRGB(half3 hsl) {
    const float r = abs(hsl.x * 6.0h - 3.0h) - 1.0h;
    const float g = 2.0h - abs(hsl.x * 6.0h - 2.0h);
    const float b = 2.0h - abs(hsl.x * 6.0h - 4.0h);
    const half3 rgb = clamp(half3(r, g, b), 0.0h, 1.0h);
    const half c = (1.0h - abs(2.0h * hsl.z - 1.0h)) * hsl.y;
    return (rgb - 0.5h) * c + hsl.z;
}

/// Converts colors from linear RGB to HSL.
/// Based on work by Sam Hocevar and Emil Persson.
half3 rgbToHSL(half3 rgb) {
    const half epsilon = 1.0e-5h;

    // RGB to HCV
    const half4 p = (rgb.y < rgb.z) ? half4(rgb.z, rgb.y, -1.0h, 2.0h / 3.0h) : half4(rgb.y, rgb.z, 0.0h, -1.0h / 3.0h);
    const half4 q = (rgb.x < p.x) ? half4(p.x, p.y, p.w, rgb.x) : half4(rgb.x, p.y, p.z, p.x);
    const half c = q.x - min(q.w, q.y);
    const half h = abs((q.w - q.y) / (6.0h * c + epsilon) + q.z);
    const half3 hcv = half3(h, c, q.x);

    const half l = hcv.z - hcv.y * 0.5h;
    const half s = hcv.y / (1.0h - abs(l * 2.0h - 1.0h) + epsilon);
    return half3(hcv.x, s, l);
}

extern "C" {
    namespace coreimage {
        
        half4 hslFilterKernel(sample_h s, half center, half hueOffset, half satOffset, half lumOffset) {
            const half3 hsl = rgbToHSL(s.rgb);

            half minHue = center - (22.5h / 360.0h);
            half maxHue = center + (22.5h / 360.0h);

            // no need to apply adjustments when not in hue range
            if (hsl.x < minHue || hsl.x > maxHue) { return s; }

            const half3 adjustedHSL = hsl + half3(hueOffset, satOffset, lumOffset);

            return half4(hslToRGB(adjustedHSL), s.a);
        }
    }
}
