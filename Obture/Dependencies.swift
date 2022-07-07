//
//  Dependencies.swift
//  Obture
//
//  Created by Roman on 29.06.2022.
//

import ComposableArchitecture
import AVFoundation
import UIKit
import Combine
import CoreMotion

import os

private let logger = Logger(subsystem: "com.andrykevych.Obture",
                            category: "SessionConfigurator/PhotoTaker/Dependencies")

final class SessionConfiguratorImpl: SessionConfigurator {
    lazy var photoOutput: AVCapturePhotoOutput = .init()
}

final class PhotoTakerImpl: PhotoTaker {
    var inProgressPhotoCaptureDelegates: [UUID: PhotoCaptureDelegate] = [:]
}

extension Resolver {

    static func obtureAppDependencies() -> Resolver {
        let r = Resolver.main
        r.register(GetStarted.Environment.self, factory: GetStarted.Environment.init)
        r.register(FileManager.self, factory: { FileManager.default })
        r.register(URL.self, name: "projectsDirectory") {
            let fileManager: FileManager = r.resolve()
            guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
                return nil
            }
            let projectsDirectoryURL = documentsDirectory.appending(path: "Projects", directoryHint: .isDirectory)
            do {
                try fileManager.createDirectory(at: projectsDirectoryURL, withIntermediateDirectories: false)
            } catch {
                logger.warning("\(error.localizedDescription)")
            }
            guard fileManager.fileExists(atPath: projectsDirectoryURL.path) else {
                logger.error("folder \(projectsDirectoryURL) doesnt exists")
                return nil
            }
            return projectsDirectoryURL
        }
        r.register(Obture.Environment.self, factory: Obture.Environment.init)
        r.register(Permissions.Environment.self) {
            .init {
                AVCaptureDevice.authorizationStatus(for: .video)
            } requestAccess: {
                await AVCaptureDevice.requestAccess(for: .video)
            } openSettings: {
                URL(string: UIApplication.openSettingsURLString).map {
                    UIApplication.shared.open($0)
                }
            }
        }
        r.register(AVCaptureSession.self, name: "CaptureSession", factory: AVCaptureSession.init)
            .scope(.application)
        r.register(DispatchQueue.self, name: "SessionQueue", factory: {
            let queue: DispatchQueue = .init(label: "SessionQueue", qos: .utility)
            return queue
        }).scope(.application)
        r.register(((URL, String) -> URL?).self, name: "createProjectDirectoryClosure") {
            let fileManager: FileManager = r.resolve()
            return {
                let projectURL = $0.appendingPathComponent($1)
                do {
                    try fileManager.createDirectory(at: projectURL, withIntermediateDirectories: false)
                } catch {
                    return nil
                }
                var isDirectory: ObjCBool = false
                guard fileManager.fileExists(atPath: projectURL.path, isDirectory: &isDirectory), isDirectory.boolValue else {
                    return nil
                }
                return projectURL
            }
        }
        r.register(PhotoTaker.self, factory: PhotoTakerImpl.init)
        r.register(CMMotionManager.self, factory: CMMotionManager.init).scope(.application)
        r.register(Motion.Environment.self, factory: Motion.Environment.init)
        r.register(CameraSession.Environment.self, factory: CameraSession.Environment.init)
        r.register(Camera.Environment.self, factory: Camera.Environment.init)
        r.register(Project.Environment.self, factory: Project.Environment.init)
        r.register(Project.SubNode.Environment.self, factory: Project.SubNode.Environment.init)
        r.register(Capture.Environment.self, factory: Capture.Environment.init)
        r.register(SessionConfigurator.self, factory: SessionConfiguratorImpl.init)
        r.register(Exporter.self, factory: ExporterImpl.init)
        r.register(CapturedPhotoWriter.self, factory: CapturedPhotoWriterImpl.init)
        r.register(((URL) -> Void).self, name: "shareURL") {
            return { url in
                guard let source = UIApplication.shared.windows.last?.rootViewController else { return }
                let vc = UIActivityViewController(
                    activityItems: [url],
                    applicationActivities: nil
                )
                vc.popoverPresentationController?.sourceView = source.view
                source.present(vc, animated: true)
            }
        }
        return r
    }
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

extension PhotoTaker {

    func takePhoto(_ session: AVCaptureSession,
                   queue: DispatchQueue,
                   from photoOutput: AVCapturePhotoOutput,
                   motionManager: CMMotionManager) -> Future<CapturedPhoto, Error> {
        let videoPreviewLayerOrientation = session.connections[0].videoOrientation
        weak var weakSelf = self
        return .init { promise in
            queue.async {
                guard let self = weakSelf else { return }
                if let photoOutputConnection = photoOutput.connection(with: .video) {
                    photoOutputConnection.videoOrientation = videoPreviewLayerOrientation
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
    //            photoSettings.photoQualityPrioritization = self.photoQualityPrioritizationMode

                // Request that the camera embed a depth map into the HEIC output file.
                photoSettings.embedsDepthDataInPhoto = true

                // Specify a preview image.
                if !photoSettings.__availablePreviewPhotoPixelFormatTypes.isEmpty {
                    photoSettings.previewPhotoFormat =
                        [kCVPixelBufferPixelFormatTypeKey as String: photoSettings.__availablePreviewPhotoPixelFormatTypes.first!]
                    logger.log("Found available previewPhotoFormat: \(String(describing: photoSettings.previewPhotoFormat))")
                } else {
                    logger.warning("Can't find preview photo formats!  Not setting...")
                }

                // Tell the camera to embed a preview image in the output file.
                photoSettings.embeddedThumbnailPhotoFormat = [
                    AVVideoCodecKey: AVVideoCodecType.jpeg,
    //                AVVideoWidthKey: self.thumbnailWidth,
    //                AVVideoHeightKey: self.thumbnailHeight
                ]

    //            DispatchQueue.main.async {
    //                self.isHighQualityMode = photoSettings.isHighResolutionPhotoEnabled
    //                    && photoSettings.photoQualityPrioritization == .quality
    //            }

    //            self.photoId += 1
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
