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
import Common
import Project
import Node
import os

private let logger = Logger(subsystem: "com.andrykevych.Obture",
                            category: "Dependencies")

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
        r.register(Node.Environment.self, factory: Node.Environment.init)
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

