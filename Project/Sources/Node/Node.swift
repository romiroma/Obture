//
//  Node.swift
//  Obture
//
//  Created by Roman on 04.07.2022.
//

import ComposableArchitecture
import Combine
import Common
import os

fileprivate let logger: Logger = .init(subsystem: "com.andrykevych.Obture", category: "Node")
    
public enum Error: Equatable, Swift.Error {
    case writeFailure
}

public struct State: Identifiable, Equatable, Codable {
    public var id: String
    public var createdAt: Date
    public var updatedAt: Date
    public var photo: String = "photo"
    public var depth: String = "depth"
    public var gravity: String = "gravity"

    public init(id: String,
                createdAt: Date,
                updatedAt: Date,
                directory: URL) {
        self.id = id
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}


public enum Action {
    case write(CapturedPhoto)
    case didWrite(CapturedPhoto)
    case failure(CapturedPhoto, Error)
}

public class Environment {
    @Injected var writer: CapturedPhotoWriter

    public var projectDirectory: URL?

    public init() {}
}

public let reducer: Reducer<State, Action, Environment> = .init { state, action, environment in
    switch action {
    case .write(let photo):
        guard let directory = environment.projectDirectory?.appendingPathComponent(state.id, conformingTo: .folder) else {
            return .none
        }
        return environment.writer.write(photo, to: directory)
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

public extension State {

//    init(parentDirectory: URL, id: Int, createdAt: Date) throws {
//        let id = UUID().uuidString
//        @Injected var fileManager: FileManager
//        let directoryURL = parentDirectory.appending(path: id, directoryHint: .isDirectory)
//        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: false)
//        self.init(directory: directoryURL, id: id, createdAt: createdAt, updatedAt: createdAt)
//    }
}
