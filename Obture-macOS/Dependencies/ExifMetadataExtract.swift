//
//  EXIFMetadataExtract.swift
//  Obture-macOS
//
//  Created by Roman on 09.07.2022.
//

import Foundation
import ImageIO

struct EXIFMetadataExtract {

    private let url: CFURL

    init(url: URL) {
        self.url = url as CFURL
    }

    func callAsFunction() -> [String: Any] {
        guard let imageSource = CGImageSourceCreateWithURL(url, nil) else {
            return [:]
        }
        guard let imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [String: Any] else {
            return [:]
        }
        return imageProperties
    }
}
