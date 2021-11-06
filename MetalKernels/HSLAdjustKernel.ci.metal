//
//  HSLAdjustKernel.metal
//  MetalKernels
//
//  Created by Владимир on 05.11.2021.
//

#include <metal_stdlib>

using namespace metal;

#include <CoreImage/CoreImage.h>

extern "C" {
    namespace coreimage {
        
        float4 hslFilterKernel(sample_t s, float center, float hueOffset, float satOffset, float lumOffset) {
            // 1: Convert pixel color from RGB to HSLw
            
            float maxComp = (s.r > s.g && s.r > s.b) ? s.r : (s.g > s.b) ? s.g : s.b ;
            float minComp = (s.r < s.g && s.r < s.b) ? s.r : (s.g < s.b) ? s.g : s.b ;

            float inputHue = (maxComp + minComp) / 2.0 ;
            float inputSat = (maxComp + minComp) / 2.0 ;
            float inputLum = (maxComp + minComp) / 2.0 ;

            if (maxComp == minComp) {
                inputHue = 0.0 ;
                inputSat = 0.0 ;
            }
            else {
                float delta = maxComp - minComp ;

                inputSat = inputLum > 0.5 ? delta/(2.0 - maxComp - minComp) : delta/(maxComp + minComp);

                if (s.r > s.g && s.r > s.b) {
                    inputHue = (s.g - s.b)/delta + (s.g < s.b ? 6.0 : 0.0);
                } else if (s.g > s.b) {
                    inputHue = (s.b - s.r)/delta + 2.0;
                }
                else {
                    inputHue = (s.r - s.g)/delta + 4.0;
                }
                inputHue = inputHue / 6.0 ;
            }

            float minHue = center - 22.5 / 360.0;
            float maxHue = center + 22.5 / 360.0;

            // Apply offsets to Hue, Saturation, Luminance

            float adjustedHue = inputHue + ((inputHue > minHue && inputHue < maxHue) ? hueOffset : 0.0 );
            float adjustedSat = inputSat + ((inputHue > minHue && inputHue < maxHue) ? satOffset : 0.0 );
            float adjustedLum = inputLum + ((inputHue > minHue && inputHue < maxHue) ? lumOffset : 0.0 );

            // Convert pixel color from HSL to RGB

            float red = 0.0;
            float green = 0.0;
            float blue = 0.0;

            if (adjustedSat == 0.0) {
                red = adjustedLum;
                green = adjustedLum;
                blue = adjustedLum;
            } else {
                float q = adjustedLum < 0.5 ? adjustedLum*(1.0 + adjustedSat) : adjustedLum + adjustedSat - (adjustedLum*adjustedSat);
                float p = 2.0 * adjustedLum - q;

                // Calculate Red color
                float t = adjustedHue + 1.0/3.0;
                if (t < 0.0) { t += 1.0; }
                if (t > 1.0) { t -= 1.0; }

                if (t < 1.0/6.0) { red = p + (q - p) * 6.0 * t; }
                else if (t < 1.0/2.0) { red = q; }
                else if (t < 2.0/3.0) { red = p + (q - p)*(2.0/3.0 - t) * 6.0; }
                else { red = p; }

                // Calculate Green color
                t = adjustedHue;
                if (t < 0.0) { t += 1.0; }
                if (t > 1.0) { t -= 1.0; }

                if (t < 1.0/6.0) { green = p + (q - p) * 6.0 * t; }
                else if (t < 1.0/2.0) { green = q ;}
                else if (t < 2.0/3.0) { green = p + (q - p)*(2.0/3.0 - t) * 6.0; }
                else { green = p; }

                // Calculate Blue color

                t = adjustedHue - 1.0/3.0;
                if (t < 0.0) { t += 1.0; }
                if (t > 1.0) { t -= 1.0; }

                if (t < 1.0/6.0) { blue = p + (q - p) * 6.0 * t; }
                else if (t < 1.0/2.0) { blue = q; }
                else if (t < 2.0/3.0) { blue = p + (q - p)*(2.0/3.0 - t) * 6.0;}
                else { blue = p; }

            }

            float4 outColor;
            outColor.r = red;
            outColor.g = green;
            outColor.b = blue;
            outColor.a = s.a;
            
            return outColor;
            
        }
    }
}
