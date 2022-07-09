//
//  CapturedPhoto.swift
//  
//
//  Created by Roman on 07.07.2022.
//

import Foundation
import AVFoundation
import Combine
import CoreMotion

public struct CapturedPhoto: Equatable {
    public static func == (lhs: CapturedPhoto, rhs: CapturedPhoto) -> Bool {
        return lhs.photo === rhs.photo
    }

    public let photo: AVCapturePhoto
    public let depthMapData: Data
    public let gravity: CMAcceleration

    public let createdAt: Date = .init()

    public init(photo: AVCapturePhoto, depthMapData: Data, gravity: CMAcceleration) {
        self.photo = photo
        self.depthMapData = depthMapData
        self.gravity = gravity
    }
}
