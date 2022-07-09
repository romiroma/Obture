//
//  CameraSession.SessionConfigurator.swift
//  Obture
//
//  Created by Roman on 07.07.2022.
//

import AVFoundation
import Foundation
import Combine

import os

private let logger = Logger(subsystem: "com.andrykevych.Obture",
                            category: "SessionConfigurator")

final class SessionConfiguratorImpl: SessionConfigurator {
    lazy var photoOutput: AVCapturePhotoOutput = .init()
}

extension SessionConfigurator {
    func configure(_ session: AVCaptureSession, queue: DispatchQueue) -> Future<Void, CameraSession.Error> {
        weak var weakSelf = self
        return .init { promise in
            queue.async {
                guard let self = weakSelf else { return }
                session.beginConfiguration()
                defer { session.commitConfiguration() }

                session.sessionPreset = .photo

                do {
                    let videoDeviceInput = try AVCaptureDeviceInput(device: self.getVideoDeviceForPhotogrammetry())

                    if session.canAddInput(videoDeviceInput) {
                        session.addInput(videoDeviceInput)
                    } else {
                        logger.error("Couldn't add video device input to the session.")
                        promise(.failure(CameraSession.Error.configurationError))
                        return
                    }
                } catch {
                    logger.error("Couldn't create video device input: \(String(describing: error))")
                    promise(.failure(CameraSession.Error.configurationError))
                    return
                }

                if session.canAddOutput(self.photoOutput) {
                    session.addOutput(self.photoOutput)
                    self.photoOutput.isHighResolutionCaptureEnabled = true
                    self.photoOutput.isDepthDataDeliveryEnabled = self.photoOutput.isDepthDataDeliverySupported
                    self.photoOutput.maxPhotoQualityPrioritization = .quality
                } else {
                    logger.error("Error: adding photo output")
                    promise(.failure(CameraSession.Error.configurationError))
                    return
                }

                promise(.success(()))
            }
        }
    }

    func start(_ session: AVCaptureSession, queue: DispatchQueue) -> Future<Void, CameraSession.Error> {
        .init { promise in
            queue.async {
                session.startRunning()
                promise(.success(()))
            }
        }
    }

    func stop(_ session: AVCaptureSession, queue: DispatchQueue) -> Future<Void, CameraSession.Error> {
        .init { promise in
            queue.async {
                session.stopRunning()
                promise(.success(()))
            }
        }
    }


    /// This method checks for a depth-capable dual rear camera and, if found, returns an `AVCaptureDevice`.
    private func getVideoDeviceForPhotogrammetry() throws -> AVCaptureDevice {
        var defaultVideoDevice: AVCaptureDevice?

        // Specify dual camera to get access to depth data.
        if let dualCameraDevice = AVCaptureDevice.default(.builtInDualCamera, for: .video,
                                                          position: .back) {
            logger.info(">>> Got back dual camera!")
            defaultVideoDevice = dualCameraDevice
        } else if let dualWideCameraDevice = AVCaptureDevice.default(.builtInDualWideCamera,
                                                                for: .video,
                                                                position: .back) {
            logger.info(">>> Got back dual wide camera!")
            defaultVideoDevice = dualWideCameraDevice
       } else if let backWideCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                                     for: .video,
                                                                     position: .back) {
           logger.info(">>> Can't find a depth-capable camera: using wide back camera!")
           defaultVideoDevice = backWideCameraDevice
        }

        guard let videoDevice = defaultVideoDevice else {
            logger.error("Back video device is unavailable.")
            throw CameraSession.Error.configurationError
        }
        return videoDevice
    }
}
