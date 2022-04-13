//
//  ContentView.swift
//  MetalKernels
//
//  Created by Владимир on 05.11.2021.
//

import CoreImage
import SwiftUI


struct ContentView: View {
    
    let context: CIContext
    
    @State var processedImage = CIImage.empty()
    @State var presentedImage: CGImage?
    @State var intensity: Float = 0
    
    init() {
        guard let mtlDevice = MTLCreateSystemDefaultDevice() else { fatalError() }
        
        self.context = CIContext(mtlDevice: mtlDevice)
    }
    
    var body: some View {
        
        
        VStack(alignment: .center, spacing: 0){
            if let presentedImage = presentedImage {
                Image(presentedImage, scale: 1.0, label: Text(""))
            } else {
                Spacer()
            }
            VStack(alignment: .center, spacing: 8) {
                Text("Value: \(Int(intensity))")
                Slider(value: $intensity, in: 0...100, step: 1)
            }
            .frame(width: 2*UIScreen.sWidth/5)
            Spacer()
        }
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
        .onAppear{
            guard let url = Bundle.main.url(forResource: "APC_1345-2", withExtension: "dng") else {return}
            
            guard let image = CIImage(contentsOf: url) else { return }
            
            processedImage = image.oriented(forExifOrientation: 5)
            presentedImage = context.createCGImage(processedImage, from: processedImage.extent)
        }
        .onChange(of: intensity, perform: { newValue in
            let image = imageProcessing(processedImage, intensity: newValue)
            presentedImage = context.createCGImage(image, from: image.extent)
        })
        
        
        
    }
    
    func imageProcessing(_ inputImage: CIImage, intensity: Float) -> CIImage {
        
        if intensity == 0 { return inputImage }
        
        guard let url = Bundle.main.url(forResource: "Neutral_LUT_144", withExtension: "png") else { return inputImage }
        guard let cubeImage = CIImage(contentsOf: url) else { return inputImage }
        
        let filter = ColorLookUp144()
        filter.inputImage = inputImage
        filter.inputLUT = cubeImage
        filter.inputIntensity = CGFloat(abs(intensity/100))
        
        if let output = filter.outputImage { return output }
        
        return inputImage
    }

}

class ColorLookUp64: CIFilter {
    
    var inputImage: CIImage?
    var inputLUT: CIImage?
    var inputIntensity: CGFloat = 1.0
    
    static var kernel: CIKernel = {
        guard let url = Bundle.main.url(forResource: "LUT_64.ci", withExtension: "metallib"),
              let data = try? Data(contentsOf: url)
        else { fatalError("Unable to load metallib") }
        
        guard let kernel = try? CIKernel(functionName: "filterKernel", fromMetalLibraryData: data)
        else { fatalError("Unable to create color kernel") }
        
        return kernel
    }()
    
    override var outputImage: CIImage? {
        
        guard let image = inputImage, let lut = inputLUT else { return inputImage }
        
        return ColorLookUp64.kernel.apply(
            extent: image.extent,
            roiCallback: { (index, dest) -> CGRect in if index == 0 { return dest } else { return lut.extent } },
            arguments: [image, lut, inputIntensity])
    }
}

class ColorLookUp144: CIFilter {
    
    var inputImage: CIImage?
    var inputLUT: CIImage?
    var inputIntensity: CGFloat = 1.0
    
    static var kernel: CIKernel = {
        guard let url = Bundle.main.url(forResource: "LUT_144.ci", withExtension: "metallib"),
              let data = try? Data(contentsOf: url)
        else { fatalError("Unable to load metallib") }
        
        guard let kernel = try? CIKernel(functionName: "filterKernel", fromMetalLibraryData: data)
        else { fatalError("Unable to create color kernel") }
        
        return kernel
    }()
    
    override var outputImage: CIImage? {
        
        guard let image = inputImage, let lut = inputLUT else { return inputImage }
        
        return ColorLookUp144.kernel.apply(
            extent: image.extent,
            roiCallback: { (index, dest) -> CGRect in if index == 0 { return dest } else { return lut.extent } },
            arguments: [image, lut, inputIntensity])
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

