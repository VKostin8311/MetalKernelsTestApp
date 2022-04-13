//
//  LUT_64.ci.metal
//  MetalKernels
//
//  Created by Владимир Костин on 12.04.2022.
//

#include <metal_stdlib>

using namespace metal;

#include <CoreImage/CoreImage.h>

extern "C" {
    namespace coreimage {
        
        float4 commitLUT64(sampler image, sampler lut, float intensity) {
            float4 color = image.sample(image.coord());
            color = clamp(color, float4(0.0f), float4(1.0f));
            
            float red   = color.r * 63.0f;
            float green = color.g * 63.0f;
            float blue  = color.b * 63.0f;
            
            float x = red / 512.0f;
            float y = green / 512.0f;
            
            float blueY = floor(blue / 8.0f) * 0.125f;
            float blueX = 0.125f * ceil(blue - 8.0f * floor(blue / 8.0f)) / 512.0f;
            
            float4 newColor = lut.sample(float2(x + blueX, y + blueY));
            
            
            return mix(color, float4(newColor.r, newColor.g, newColor.b, color.a), intensity);
        }
    }
}
