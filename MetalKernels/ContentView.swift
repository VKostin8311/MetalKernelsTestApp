//
//  ContentView.swift
//  MetalKernels
//
//  Created by Владимир on 05.11.2021.
//

import CoreImage
import SwiftUI


struct ContentView: View {
    let context = CIContext()
    
    @State var showImporter = false
    @State var showInitial = false
    
    @State var initialImage = CIImage.empty()
    @State var processedImage = CIImage.empty()
    
    @State var initImage: CGImage?
    @State var presentedImage: CGImage?

    @State var center: HSLColors = .red
   
    @State var hue: Float = 0
    @State var saturation: Float = 0
    @State var luminance: Float = 0
    

    var body: some View {
        VStack(alignment: .center, spacing: 0){
            ToolBarView(showImporter: $showImporter)
            HStack(alignment: .top, spacing: 0){
                if presentedImage != nil {
                    Image(showInitial ? initImage! : presentedImage!, scale: 1.0, label: Text(""))
                        .resizable()
                        .frame(width: 3*(UIScreen.sHeight-64)/4, height: UIScreen.sHeight-64, alignment: .center)
                        .onLongPressGesture(minimumDuration: 300, maximumDistance: 32) {
                            
                        } onPressingChanged: { value in
                            showInitial = value
                        }

                } else {
                    Spacer()
                }
                VStack(alignment: .center, spacing: 8) {
                    
                    VStack(alignment: .center, spacing: 0) {
                        
                        Text("Hue: \(Int(hue))")
                        Slider(value: $hue, in: -100...100, step: 1)
                        Text("Saturation: \(Int(saturation))")
                        Slider(value: $saturation, in: -100...100, step: 1)
                        Text("Brightness: \(Int(luminance))")
                        Slider(value: $luminance, in: -100...100, step: 1)
                    }
                    
                }
                .frame(width: 2*UIScreen.sWidth/5)
            }
            .padding(.horizontal, 24)
            Spacer()
        }
        
        .onChange(of: hue, perform: { newValue in
            processedImage = imageProcessing(initialImage)
        })
        .onChange(of: saturation, perform: { newValue in
            processedImage = imageProcessing(initialImage)
        })
        .onChange(of: luminance, perform: { newValue in
            processedImage = imageProcessing(initialImage)
        })
        
        .onChange(of: initialImage, perform: { value in
            processedImage = imageProcessing(value)
        })
        
        .onChange(of: processedImage, perform: { newValue in
            presentedImage = context.createCGImage(newValue, from: newValue.extent)
        })
        
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
        .fileImporter(isPresented: $showImporter, allowedContentTypes: [.data]) { (res) in
            
            do {
                let fileURL = try res.get()
                guard fileURL.startAccessingSecurityScopedResource() else {return}
                
                if let data = try? Data(contentsOf: fileURL) {
                    
                    if let image = CIImage(data: data, options: [CIImageOption.applyOrientationProperty : true]) {
                        initialImage = image
                        presentedImage = context.createCGImage(image, from: image.extent)
                        initImage = presentedImage
                    }
                }
                fileURL.stopAccessingSecurityScopedResource()
            } catch {
                print(error.localizedDescription)
            }
        }
        
    }
    
    
    func imageProcessing(_ inputImage: CIImage) -> CIImage {

        let filter = HSLAdjustFilter()
        
        filter.inputImage = inputImage
        filter.center = 180/360
        filter.hueOffset = CGFloat(hue/100)
        filter.satOffset = CGFloat(saturation/100)
        filter.lumOffset = CGFloat(luminance/100)
        
        if let outputImage = filter.outputImage {
            return outputImage
        } else {
            return inputImage
        }
    }
    
    
}


class HSLAdjustFilter: CIFilter {
    
    var inputImage: CIImage?
    var center: CGFloat?
    var hueOffset: CGFloat?
    var satOffset: CGFloat?
    var lumOffset: CGFloat?
   
    static var kernel: CIColorKernel = {
        guard let url = Bundle.main.url(forResource: "HSLAdjustKernel.ci", withExtension: "metallib"),
              let data = try? Data(contentsOf: url)
        else { fatalError("Unable to load metallib") }
        
        guard let kernel = try? CIColorKernel(functionName: "hslFilterKernel", fromMetalLibraryData: data)
        else { fatalError("Unable to create color kernel") }
        
        return kernel
    }()
    
    
    override var outputImage: CIImage? {
        guard let inputImage = self.inputImage else { return nil }
        
        
        return HSLAdjustFilter.kernel.apply(extent: inputImage.extent, arguments: [inputImage, self.center ?? 0, self.hueOffset ?? 0, self.satOffset ?? 0, self.lumOffset ?? 0])
    }
    
}

enum HSLColors: Float {
    
    case red = 0
    case orange = 45
    case yellow = 90
    case green = 135
    case cyan = 180
    case blue = 225
    case violet = 270
    case magenta = 315
    
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
