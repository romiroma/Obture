//
//  Dependencies.swift
//  Obture
//
//  Created by Roman on 29.06.2022.
//

import ComposableArchitecture
import Combine
import Common
import AppKit
import ZIPFoundation
import RealityKit
import Files
import os
import AppKit
import ImageIO

private let logger = Logger(subsystem: "com.andrykevych.Obture",
                            category: "SessionConfigurator/PhotoTaker/Dependencies")

extension Resolver {

    static func obtureAppDependencies() -> Resolver {
        let r = Resolver.main

        r.register((() -> URL?).self, name: "fileOpen") {
            {
                let openPanel = NSOpenPanel()
                openPanel.allowedContentTypes = [.zip, .usdz]
                openPanel.allowsMultipleSelection = false
                openPanel.canChooseDirectories = false
                openPanel.canChooseFiles = true
                let response = openPanel.runModal()
                return response == .OK ? openPanel.url : nil
            }
        }
        r.register(((URL) -> Future<URL, Swift.Error>).self, name: "unpackProject") {
            return { url in
                    .init { promise in
                        DispatchQueue.global(qos: .userInitiated).async {
                            let fileManager = FileManager.default
                            let destinationFolder = fileManager.temporaryDirectory.appendingPathComponent(url.lastPathComponent, conformingTo: .folder)
                            do {
                                if fileManager.fileExists(atPath: destinationFolder.path) {
                                    try fileManager.removeItem(at: destinationFolder)
                                }
                                try fileManager.unzipItem(at: url, to: destinationFolder)
                            } catch {
                                promise(.failure(error))
                                return
                            }
                            promise(.success(destinationFolder))
                        }
                    }
            }
        }
        r.register(SessionHolder.self, factory: SessionHolderImpl.init)
        r.register(
            ( (URL) -> any Sequence<PhotogrammetrySample>).self,
            name: "samplesFromDirectory"
        ) {
            
            return { url in
                let folder: Folder
                do {
                    folder = try Folder(path: url.path)
                } catch {
                    return [PhotogrammetrySample]().map { $0 }.lazy
                }
                guard let firstSubfolder = folder.subfolders.first else { return [PhotogrammetrySample]().lazy }
                let samples = firstSubfolder.subfolders.lazy.enumerated().compactMap({ oe -> PhotogrammetrySample? in
                    let id = oe.offset
                    let files = oe.element.files

                    var photo: File?
                    var depth: File?
                    var gravity: File?

                    for file in files {
                        switch file.name {
                        case "photo":
                            photo = file
                        case "depth":
                            depth = file
                        case "gravity":
                            gravity = file
                        default:
                            break
                        }
                    }
                    guard let photo = photo,
                          let photoData = try? photo.read(),
                          let depthData = try? depth?.read(),
                          let gravityString = try? gravity?.readAsString(encodedAs: .utf8) else { return nil }
                    

                    if let colorPixelBuffer = NSImage(data: photoData)?.colorPixelBuffer() {
                        var sample: PhotogrammetrySample = .init(id: id, image: colorPixelBuffer)
                        sample.depthDataMap = NSImage(data: depthData)?.disparityPixelBuffer()

                        let gravityCoordinatesArray = gravityString
                            .components(separatedBy: ",")
                            .compactMap(Double.init)
                        guard gravityCoordinatesArray.count == 3 else {
                            logger.error("Gravity is nil")
                            return nil
                        }
                        sample.gravity = .init(x: gravityCoordinatesArray[0],
                                               y: gravityCoordinatesArray[1],
                                               z: gravityCoordinatesArray[2])
                        let extract = EXIFMetadataExtract(url: photo.url)
                        sample.metadata = extract()
                        return sample
                    } else {
                        return nil
                    }
                })
                return samples
            }
        }
        r.register(((URL) -> Void).self, name: "openResult") {
            { url in
                NSWorkspace.shared.activateFileViewerSelecting([url])
            }
        }
        r.register(FileSelection.Environment.self, factory: FileSelection.Environment.init)
        r.register(Unpack.Environment.self, factory: Unpack.Environment.init)
        r.register(Photogrammetry.Environment.self, factory: Photogrammetry.Environment.init)
        r.register(Setup.Environment.self, factory: Setup.Environment.init)
        r.register(Obture.Environment.self, factory: Obture.Environment.init)
        r.register(Preview.Environment.self, factory: Preview.Environment.init)
        return r
    }
}
