//
//  Project.ExporterImpl.swift
//  Obture
//
//  Created by Roman on 07.07.2022.
//

import Foundation
import Combine
import Common
import Project
import ZIPFoundation

final class ExporterImpl: Exporter {
    init() {}

    let queue: DispatchQueue = .init(label: "com.andrykevych.Obture.Exporter.queue", qos: .userInitiated)

    func export(_ project: State) -> Future<URL, Error> {
        @Injected var fileManager: FileManager
        return .init { [weak self] promise in
            self?.queue.async {
                let fileManager = FileManager.default
                let destinationURL = project.directory.deletingLastPathComponent().appendingPathComponent("export", conformingTo: .zip)
                do {
                    if fileManager.fileExists(atPath: destinationURL.path) {
                        try fileManager.removeItem(at: destinationURL)
                    }
                    try fileManager.zipItem(at: project.directory,
                                            to: destinationURL)
                } catch {
                    promise(.failure(.exportError))
                    return
                }
                promise(.success(destinationURL))
            }
        }
    }
}
