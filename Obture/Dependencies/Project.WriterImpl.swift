//
//  Project.WriterImpl.swift
//  Obture
//
//  Created by Roman on 30.07.2022.
//

import Foundation
import Combine
import Common
import Project
import ZIPFoundation

final class WriterImpl: Writer {
    private let encoder: JSONEncoder

    init() {
        encoder = .init()
    }

    let queue: DispatchQueue = .init(label: "com.andrykevych.Obture.WriterImpl.queue", qos: .userInitiated)

    func write(state: Project.State, toProjectDirectory directory: URL) -> Future<URL, Project.Error> {
        return .init { [weak self] promise in
            self?.queue.async {
                guard let self = self else { return }
                let data: Data
                do {
                    data = try self.encoder.encode(state)
                } catch {
                    promise(.failure(.projectSerializationError(error)))
                    return
                }
                let projectFile = directory.appendingPathComponent("metadata", conformingTo: .json)
                do {
                    try data.write(to: projectFile)
                } catch {
                    promise(.failure(.projectSerializationError(error)))
                    return
                }
                promise(.success(projectFile))
            }
        }
    }
}
