//
//  LUT_128.ci.metal
//  MetalKernels
//
//  Created by Владимир Костин on 13.04.2022.
//

#include <metal_stdlib>

using namespace metal;

#include <CoreImage/CoreImage.h>

extern "C" {
    namespace coreimage {
        
        float4 filterKernel(sampler image, sampler lut, float intensity) {
            
            float4 textureColor = image.sample(image.coord());
            textureColor = clamp(textureColor, float4(0.0), float4(1.0));
            
            float blueColor = textureColor.b * 143.0f;
            
            float2 quad1;
            quad1.y = floor(floor(blueColor) / 12.0f);
            quad1.x = floor(blueColor) - (quad1.y * 12.0f);
            
            float2 quad2;
            quad2.y = floor(ceil(blueColor) / 12.0f);
            quad2.x = ceil(blueColor) - (quad2.y * 12.0f);
            
            float2 texPos1;
            texPos1.x = (quad1.x * (1.0f/12.0f)) + 0.5f/1728.0f + (((1.0f/12.0f) - 1.0f/1728.0f) * textureColor.r);
            texPos1.y = (quad1.y * (1.0f/12.0f)) + 0.5f/1728.0f + (((1.0f/12.0f) - 1.0f/1728.0f) * textureColor.g);
            
            float2 texPos2;
            texPos2.x = (quad2.x * (1.0f/12.0f)) + 0.5f/1728.0f + (((1.0f/12.0f) - 1.0f/1728.0f) * textureColor.r);
            texPos2.y = (quad2.y * (1.0f/12.0f)) + 0.5f/1728.0f + (((1.0f/12.0f) - 1.0f/1728.0f) * textureColor.g);
            
            texPos1.y = 1.0f - texPos1.y;
            texPos2.y = 1.0f - texPos2.y;
            
            float4 lutExtent = lut.extent();
            
            float4 newColor1 = lut.sample(lut.transform(texPos1 * float2(1728.0f) + lutExtent.xy));
            float4 newColor2 = lut.sample(lut.transform(texPos2 * float2(1728.0f) + lutExtent.xy));
            
            float4 newColor = mix(newColor1, newColor2, fract(blueColor));
            
            return mix(textureColor, float4(newColor.rgb, textureColor.a), intensity);
        }
    }
}
