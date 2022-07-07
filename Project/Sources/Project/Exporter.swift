//
//  Exporter.swift
//  Obture
//
//  Created by Roman on 07.07.2022.
//

import Foundation
import Combine
import Common

public protocol Exporter {
    func export(_ project: State) -> Future<URL, Error>
}

public final class ExporterImpl: Exporter {
    public init() {}

    let queue: DispatchQueue = .init(label: "com.andrykevych.Obture.Exporter.queue", qos: .userInitiated)
    
    public func export(_ project: State) -> Future<URL, Error> {
        @Injected var fileManager: FileManager
        return .init { [weak self] promise in
            self?.queue.async {
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
                        promise(.failure(Error.exportError))
                    }
                }
            }
        }
    }
}
