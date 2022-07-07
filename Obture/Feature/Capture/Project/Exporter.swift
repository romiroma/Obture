//
//  Exporter.swift
//  Obture
//
//  Created by Roman on 07.07.2022.
//

import Foundation
import Combine

protocol Exporter {
    func export(_ project: Project.State) -> Future<URL, Error>
}

final class ExporterImpl: Exporter {
    let queue: DispatchQueue = .init(label: "com.andrykevych.Obture.Exporter.queue", qos: .userInitiated)
    func export(_ project: Project.State) -> Future<URL, Error> {
        return .init { [weak self] promise in
            self?.queue.async {
                @Injected var fileManager: FileManager
                let coordinator = NSFileCoordinator()
                var error: NSError?
                coordinator.coordinate(readingItemAt: project.directory, options: [.forUploading], error: &error) { (zipUrl) in
                    // zipUrl points to the zip file created by the coordinator
                    // zipUrl is valid only until the end of this block, so we move the file to a temporary folder
                    do {
                        let tmpUrl = try fileManager.url(for: .itemReplacementDirectory,
                                                         in: .userDomainMask,
                                                         appropriateFor: zipUrl,
                                                         create: true).appendingPathComponent(project.id + ".zip")
                        try fileManager.moveItem(at: zipUrl, to: tmpUrl)
                        promise(.success((tmpUrl)))
                    } catch {
                        promise(.failure(error))
                    }
                }
            }
        }
    }
}
