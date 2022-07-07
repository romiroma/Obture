//
//  CapturedPhoto.swift
//  Obture
//
//  Created by Roman on 06.07.2022.
//

import Foundation
import AVFoundation
import Combine
import CoreMotion

struct CapturedPhoto: Equatable {
    static func == (lhs: CapturedPhoto, rhs: CapturedPhoto) -> Bool {
        return lhs.photo === rhs.photo
    }

    let photo: AVCapturePhoto
    let depthMapData: Data
    let gravity: CMAcceleration

    let createdAt: Date = .init()
}

protocol CapturedPhotoWriter: AnyObject {
    func write(_ photo: CapturedPhoto, to folder: URL) -> Future<Void, Error>
}

import os

private let logger = Logger(subsystem: "com.andrykevych.Obture.CapturedPhotoWriterImpl", category: "CapturedPhotoWriterImpl")

class CapturedPhotoWriterImpl: CapturedPhotoWriter {

    enum Error: Swift.Error {
        case cantWritePhotoData(Swift.Error)
        case cantWriteDepthData(Swift.Error)
        case cantWriteGravityData(Swift.Error)
        case noPhotoFileDataRepresentation
    }
    func write(_ photo: CapturedPhoto, to folder: URL) -> Future<Void, Swift.Error> {
        return .init { promise in
            guard let photoFileData = photo.photo.fileDataRepresentation() else {
                promise(.failure(Error.noPhotoFileDataRepresentation))
                return
            }
            let photoDataURL = folder.appendingPathComponent("photo", conformingTo: .data)
            do {
                try photoFileData.write(to: URL(fileURLWithPath: photoDataURL.path), options: .atomic)
            } catch {
                logger.error("Can't write image to \"\(photoDataURL.path)\" error=\(String(describing: error))")
                promise(.failure(Error.cantWritePhotoData(error)))
                return
            }

            let depthDataURL = folder.appendingPathComponent("depth", conformingTo: .data)
            do {
                try photo.depthMapData.write(to: URL(fileURLWithPath: depthDataURL.path), options: .atomic)
            } catch {
                logger.error("Can't write image to \"\(depthDataURL.path)\" error=\(String(describing: error))")
                promise(.failure(Error.cantWriteDepthData(error)))
                return
            }

            let gravityDataURL = folder.appendingPathComponent("gravity", conformingTo: .data)
            let gravityVector = photo.gravity
            let gravityString = String(format: "%lf,%lf,%lf", gravityVector.x, gravityVector.y, gravityVector.z)
            logger.log("Writing gravity metadata to: \"\(gravityDataURL.path)\"...")
            do {
                try gravityString.write(toFile: gravityDataURL.path, atomically: true,
                                        encoding: .utf8)
            } catch {
                logger.error("Can't write image to \"\(gravityDataURL.path)\" error=\(String(describing: error))")
                promise(.failure(Error.cantWriteGravityData(error)))
                return
            }

            promise(.success(()))
        }
    }
}
