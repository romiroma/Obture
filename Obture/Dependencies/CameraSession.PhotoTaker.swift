//
//  CameraSession.PhotoTaker.swift
//  Obture
//
//  Created by Roman on 07.07.2022.
//

import AVFoundation
import Foundation
import Combine
import Node
import CoreMotion
import os

private let logger = Logger(subsystem: "com.andrykevych.Obture",
                            category: "Dependencies")

final class PhotoTakerImpl: PhotoTaker {
    var inProgressPhotoCaptureDelegates: [UUID: PhotoCaptureDelegate] = [:]
}

extension PhotoTaker {

    func takePhoto(_ session: AVCaptureSession,
                   queue: DispatchQueue,
                   from photoOutput: AVCapturePhotoOutput,
                   motionManager: CMMotionManager) -> Future<CapturedPhoto, Swift.Error> {
        let videoPreviewLayerOrientation = session.connections[0].videoOrientation
        weak var weakSelf = self
        return .init { promise in
            queue.async {
                guard let self = weakSelf else { return }
                if let photoOutputConnection = photoOutput.connection(with: .video) {
//                    photoOutputConnection.videoOrientation = videoPreviewLayerOrientation
                    photoOutputConnection.videoOrientation = .landscapeRight
                }
                var photoSettings = AVCapturePhotoSettings()

                // Request HEIF photos if supported and enable high-resolution photos.
                if  photoOutput.availablePhotoCodecTypes.contains(.hevc) {
                    photoSettings = AVCapturePhotoSettings(
                        format: [AVVideoCodecKey: AVVideoCodecType.hevc])
                }

                // Turn off the flash. The app relies on ambient lighting to avoid specular highlights.
                if let videoDeviceInput = session.inputs.first(where: { $0 is AVCaptureDeviceInput }) as? AVCaptureDeviceInput,
                   videoDeviceInput.device.isFlashAvailable {
                    photoSettings.flashMode = .off
                }

                // Turn on high-resolution, depth data, and quality prioritzation mode.
                photoSettings.isHighResolutionPhotoEnabled = true
                photoSettings.isDepthDataDeliveryEnabled = photoOutput.isDepthDataDeliveryEnabled
                photoSettings.photoQualityPrioritization = .quality
                // Request that the camera not embed a depth map into the HEIC output file.
                photoSettings.embedsDepthDataInPhoto = true

                let photoId = UUID()
                let photoCaptureProcessor = PhotoCaptureDelegate(
                    with: photoSettings,
                    photoId: photoId,
                    motionManager: motionManager,
                    willCapturePhotoAnimation: {
                        logger.info("animation")
                    },
                    completionHandler: { result in
                        // When the capture is complete, remove the reference to the
                        // completed photo capture delegate.
                        switch result {
                        case .success((let photo, let depthMapData?, let gravity?)):
                            promise(.success(.init(photo: photo, depthMapData: depthMapData, gravity: gravity)))
                        case .success:
                            promise(.failure(NSError()))
                        case .failure(let error):
                            promise(.failure(error))
                        }

                        queue.async {
                            guard let self = weakSelf else { return }
                            self.inProgressPhotoCaptureDelegates.removeValue(
                                forKey: photoId)
                            logger.log("inProgressCaptures=\(self.inProgressPhotoCaptureDelegates.count)")
                        }
                    },
                    photoProcessingHandler: { _ in
                    }
                )

                // The photo output holds a weak reference to the photo capture
                // delegate, so it also stores it in an array, which maintains a
                // strong reference so the system won't deallocate it.
                self.inProgressPhotoCaptureDelegates[photoId] = photoCaptureProcessor
                logger.log("inProgressCaptures=\(self.inProgressPhotoCaptureDelegates.count)")
                photoOutput.capturePhoto(with: photoSettings, delegate: photoCaptureProcessor)
            }
        }
    }
}
