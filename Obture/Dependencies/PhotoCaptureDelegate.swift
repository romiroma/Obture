//
//  PhotoCaptureDelegate.swift
//  Obture
//
//  Created by Roman on 04.07.2022.
//

import AVFoundation
import CoreImage
import CoreMotion
import os

private let logger = Logger(subsystem: "com.andrykevych.Obture",
                            category: "PhotoCaptureDelegate")

/// This class stores state and acts as a delegate for all callbacks during the capture process. It pushes the
/// capture objects containing images and metadata back to the specified `CameraViewModel`.
class PhotoCaptureDelegate: NSObject {
    private(set) var requestedPhotoSettings: AVCapturePhotoSettings
    private(set) var photoId: UUID
    private let willCapturePhotoAnimation: () -> Void

    lazy var context = CIContext()

    private let photoProcessingHandler: (Bool) -> Void
    private let completionHandler: (Result<(AVCapturePhoto, Data?, CMAcceleration?), Error>) -> Void
    private var maxPhotoProcessingTime: CMTime?

    private let motionManager: CMMotionManager

    private var photoData: AVCapturePhoto?
    private var depthMapData: Data?
    private var depthData: AVDepthData?
    private var gravity: CMAcceleration?

    init(with requestedPhotoSettings: AVCapturePhotoSettings,
         photoId: UUID,
         motionManager: CMMotionManager,
         willCapturePhotoAnimation: @escaping () -> Void,
         completionHandler: @escaping (Result<(AVCapturePhoto, Data?, CMAcceleration?), Error>) -> Void,
         photoProcessingHandler: @escaping (Bool) -> Void) {
        self.photoId = photoId
        self.motionManager = motionManager
        self.requestedPhotoSettings = requestedPhotoSettings
        self.willCapturePhotoAnimation = willCapturePhotoAnimation
        self.completionHandler = completionHandler
        self.photoProcessingHandler = photoProcessingHandler
    }
}

/// This extension adopts all of the `AVCapturePhotoCaptureDelegate` protocol methods.
extension PhotoCaptureDelegate: AVCapturePhotoCaptureDelegate {

    /// - Tag: WillBeginCapture
    func photoOutput(_ output: AVCapturePhotoOutput,
                     willBeginCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        maxPhotoProcessingTime = resolvedSettings.photoProcessingTimeRange.start
            + resolvedSettings.photoProcessingTimeRange.duration
    }

    /// - Tag: WillCapturePhoto
    func photoOutput(_ output: AVCapturePhotoOutput,
                     willCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        willCapturePhotoAnimation()

        // Retrieve the gravity vector at capture time.
        if motionManager.isDeviceMotionActive {
            gravity = motionManager.deviceMotion?.gravity
            logger.log("Captured gravity vector: \(String(describing: self.gravity))")
        }

        guard let maxPhotoProcessingTime = maxPhotoProcessingTime else {
            return
        }

        // Show a spinner if processing time exceeds one second.
        let oneSecond = CMTime(seconds: 1, preferredTimescale: 1)
        if maxPhotoProcessingTime > oneSecond {
            photoProcessingHandler(true)
        }
    }

    /// - Tag: DidFinishProcessingPhoto
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        photoProcessingHandler(false)

        if let error = error {
            print("Error capturing photo: \(error)")
            photoData = nil
        } else {
            // Cache the HEIF representation of the data.
            photoData = photo
        }

        if let depthData = photo.depthData?.converting(toDepthDataType: kCVPixelFormatType_DisparityFloat32),
           let colorSpace = CGColorSpace(name: CGColorSpace.linearGray) {
            let depthImage = CIImage(cvImageBuffer: depthData.depthDataMap,
                                      options: [ .auxiliaryDisparity: true ] )
            let depthMapData = context.tiffRepresentation(of: depthImage,
                                                      format: .Lf,
                                                      colorSpace: colorSpace,
                                                      options: [.disparityImage: depthImage])
            self.depthMapData = depthMapData
        } else {
            logger.error("colorSpace .linearGray not available... can't save depth data!")
            depthMapData = nil
        }
    }

    /// - Tag: DidFinishCapture
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings,
                     error: Error?) {

        if let error = error {
            logger.error("Error capturing photo: \(error)")
            completionHandler(.failure(error))
            return
        }

        guard let photoData = photoData else {
            logger.error("No photo data resource")
            completionHandler(.failure(NSError()))
            return
        }

        logger.log("Making capture and adding to model...")
        completionHandler(.success((photoData, depthMapData, gravity)))
    }
}
