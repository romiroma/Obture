//
//  CIImage+PhotogrammetrySession.swift
//  Obture-macOS
//
//  Created by Roman on 07.07.2022.
//

import CoreImage

extension CIImage {
    // function used by depthPixelBuffer and disparityPixelBuffer to actually crate the CVPixelBuffer
    func __toPixelBuffer(PixelFormatType: OSType) -> CVPixelBuffer? {

        let width = Int(extent.width)
        let height = Int(extent.height)
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
              kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary

        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault, width, height, PixelFormatType, attrs, &pixelBuffer)

        guard let resultPixelBuffer = pixelBuffer, status == kCVReturnSuccess else {
            return nil
        }

        let context = CIContext.init()
        context.render(self, to: resultPixelBuffer)

        return resultPixelBuffer
    }

    // return the NSImage as a color 32bit Color CVPixelBuffer
    func colorPixelBuffer() -> CVPixelBuffer? {
        return __toPixelBuffer(PixelFormatType: kCVPixelFormatType_32ARGB)
    }

    func maskPixelBuffer() -> CVPixelBuffer? {
        return __toPixelBuffer(PixelFormatType: kCVPixelFormatType_OneComponent8)
    }

    // return NSImage as a 32bit depthData CVPixelBuffer
    func depthPixelBuffer() -> CVPixelBuffer? {
        return __toPixelBuffer(PixelFormatType: kCVPixelFormatType_DepthFloat32)
    }

    // return NSImage as a 32bit disparityData CVPixelBuffer
    func disparityPixelBuffer() -> CVPixelBuffer? {
        return __toPixelBuffer(PixelFormatType: kCVPixelFormatType_DisparityFloat32)
    }
}
