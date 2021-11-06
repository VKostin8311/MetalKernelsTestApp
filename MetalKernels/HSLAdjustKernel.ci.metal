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
        
        half4 hslFilterKernel(sample_h s, half center, half hueOffset, half satOffset, half lumOffset) {
            // 1: Convert pixel color from RGB to HSLw
            
            half maxComp = (s.r > s.g && s.r > s.b) ? s.r : (s.g > s.b) ? s.g : s.b ;
            half minComp = (s.r < s.g && s.r < s.b) ? s.r : (s.g < s.b) ? s.g : s.b ;

            half inputHue = (maxComp + minComp) / 2.0h ;
            half inputSat = (maxComp + minComp) / 2.0h ;
            half inputLum = (maxComp + minComp) / 2.0h ;

            if (maxComp == minComp) {
                inputHue = 0.0h ;
                inputSat = 0.0h ;
            }
            else {
                half delta = maxComp - minComp ;

                inputSat = inputLum > 0.5h ? delta/(2.0h - maxComp - minComp) : delta/(maxComp + minComp);

                if (s.r > s.g && s.r > s.b) {
                    inputHue = (s.g - s.b)/delta + (s.g < s.b ? 6.0h : 0.0h);
                } else if (s.g > s.b) {
                    inputHue = (s.b - s.r)/delta + 2.0h;
                }
                else {
                    inputHue = (s.r - s.g)/delta + 4.0h;
                }
                inputHue = inputHue / 6.0h ;
            }

            half minHue = center - 22.5h / 360.0h;
            half maxHue = center + 22.5h / 360.0h;

            // Apply offsets to Hue, Saturation, Luminance

            half adjustedHue = inputHue + ((inputHue > minHue && inputHue < maxHue) ? hueOffset : 0.0h );
            half adjustedSat = inputSat + ((inputHue > minHue && inputHue < maxHue) ? satOffset : 0.0h );
            half adjustedLum = inputLum + ((inputHue > minHue && inputHue < maxHue) ? lumOffset : 0.0h );

            // Convert pixel color from HSL to RGB

            half red = 0.0h;
            half green = 0.0h;
            half blue = 0.0h;

            if (adjustedSat == 0.0h) {
                red = adjustedLum;
                green = adjustedLum;
                blue = adjustedLum;
            } else {
                half q = adjustedLum < 0.5h ? adjustedLum*(1.0h + adjustedSat) : adjustedLum + adjustedSat - (adjustedLum*adjustedSat);
                half p = 2.0h * adjustedLum - q;

                // Calculate Red color
                half t = adjustedHue + 1.0h/3.0h;
                if (t < 0.0h) { t += 1.0h; }
                if (t > 1.0h) { t -= 1.0h; }

                if (t < 1.0h/6.0h) { red = p + (q - p) * 6.0h * t; }
                else if (t < 1.0h/2.0h) { red = q; }
                else if (t < 2.0h/3.0h) { red = p + (q - p)*(2.0h/3.0h - t) * 6.0h; }
                else { red = p; }

                // Calculate Green color
                t = adjustedHue;
                if (t < 0.0h) { t += 1.0h; }
                if (t > 1.0h) { t -= 1.0h; }

                if (t < 1.0h/6.0h) { green = p + (q - p) * 6.0h * t; }
                else if (t < 1.0h/2.0h) { green = q ;}
                else if (t < 2.0h/3.0h) { green = p + (q - p)*(2.0h/3.0h - t) * 6.0h; }
                else { green = p; }

                // Calculate Blue color

                t = adjustedHue - 1.0h/3.0h;
                if (t < 0.0h) { t += 1.0h; }
                if (t > 1.0h) { t -= 1.0h; }

                if (t < 1.0h/6.0h) { blue = p + (q - p) * 6.0h * t; }
                else if (t < 1.0h/2.0h) { blue = q; }
                else if (t < 2.0h/3.0h) { blue = p + (q - p)*(2.0h/3.0h - t) * 6.0h;}
                else { blue = p; }

            }

            half4 outColor;
            outColor.r = red;
            outColor.g = green;
            outColor.b = blue;
            outColor.a = s.a;
            
            return outColor;
            
        }
    }
}
