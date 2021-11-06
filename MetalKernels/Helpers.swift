//
//  Helpers.swift
//  PHLow
//
//  Created by Владимир Костин on 07.09.2021.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers

extension UIScreen{
    static let sWidth = UIScreen.main.bounds.size.width
    static let sHeight = UIScreen.main.bounds.size.height
}

struct Doc: FileDocument {
    static var readableContentTypes: [UTType] {[.data]}
    var url: URL
    
    init(url: URL) {
        self.url = url
    }
    
    init(configuration: FileDocumentReadConfiguration) throws  {
        url = URL(string: "")!
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let file = try! FileWrapper(url: url, options: .immediate)
        return file
    }
}


struct CubeDataModel: Codable, Identifiable {
    public let id: UUID
    public let title: String
    public let dimension: Int
    public let data: Data
}

extension UIImage {
  func resizeImage(targetSize: CGSize) -> UIImage {
    let size = self.size
    let widthRatio  = targetSize.width  / size.width
    let heightRatio = targetSize.height / size.height
    let newSize = widthRatio > heightRatio ?  CGSize(width: size.width * heightRatio, height: size.height * heightRatio) : CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
    let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)

    UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
    self.draw(in: rect)
    let newImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()

    return newImage!
  }
}
