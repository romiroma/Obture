//
//  CapturedPhoto.swift
//  Obture
//
//  Created by Roman on 06.07.2022.
//

import Common
import Combine
import Foundation

public protocol CapturedPhotoWriter: AnyObject {
    func write(_ photo: CapturedPhoto, to folder: URL) -> Future<Void, Swift.Error>
}
