//
//  Node.swift
//  Obture
//
//  Created by Roman on 04.07.2022.
//

import ComposableArchitecture
import Combine

import os

fileprivate let logger: Logger = .init(subsystem: "com.andrykevych.Obture", category: "ProjectEdit")

extension ProjectEdit {
    enum SubNode {

        enum Error: Equatable, Swift.Error {
            case writeFailure
        }

        struct State: Node {
            let directory: URL
            var id: String
            var createdAt: Date
            var updatedAt: Date
        }

        enum Action: Equatable {
            case write(CapturedPhoto)
            case didWrite(CapturedPhoto)
            case failure(CapturedPhoto, Error)
        }

        struct Environment {
            @Injected var writer: CapturedPhotoWriter
        }

        static let reducer: Reducer<State, Action, Environment> = .init { state, action, environment in
            switch action {
            case .write(let photo):
                return environment.writer.write(photo, to: state.directory)
                    .receive(on: DispatchQueue.main.eraseToAnyScheduler())
                    .catchToEffect { result in
                        switch result {
                        case .success:
                            return .didWrite(photo)
                        case .failure:
                            return .failure(photo, .writeFailure)

                    }
                }
            case .didWrite(_):
                break
            case .failure(_, _):
                break
            }
            return .none
        }
    }
}

extension ProjectEdit.SubNode.State {

    init(parentDirectory: URL, createdAt: Date) throws {
        let id = UUID().uuidString
        @Injected var fileManager: FileManager
        let directoryURL = parentDirectory.appending(path: id, directoryHint: .isDirectory)
        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: false)
        self.init(directory: directoryURL, id: id, createdAt: createdAt, updatedAt: createdAt)
    }
}
