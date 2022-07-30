//
//  NewProject.swift
//  Obture
//
//  Created by Roman on 04.07.2022.
//

import ComposableArchitecture
import AVFoundation
import CoreMotion
import Combine
import Common
import os
import Node

private let logger = Logger(subsystem: "com.andrykevych.Obture",
                            category: "Project")

public enum Error: Swift.Error {
    case cantCreateSubnode
    case exportError
    case projectSerializationError(Swift.Error)
}

public struct State: Identifiable, Equatable, Codable {

    public var id: String
    public var createdAt: Date
    public var updatedAt: Date
    public var nodes: IdentifiedArrayOf<Node.State>
    public let version: Int = 0
    public var export: URL?

    public init(id: String,
                createdAt: Date,
                updatedAt: Date,
                nodes: IdentifiedArrayOf<Node.State>,
                export: URL?) {
        self.id = id
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.nodes = nodes
        self.export = export
    }

    enum CodingKeys: CodingKey {
        case id
        case createdAt
        case updatedAt
        case nodes
        case version
    }
}

public enum Action {
    case add(CapturedPhoto)
    case failure(Error)
    case node(id: Node.State.ID, action: Node.Action)
    case export
    case exported(URL)

    public static func == (lhs: Project.Action, rhs: Project.Action) -> Bool {
        false
    }
}

public class Environment {
    @Injected var node: Node.Environment
    @Injected var exporter: Exporter
    @Injected var writer: Writer
    @Injected var fileManager: FileManager
    var projectDirectory: URL? {
        didSet {
            node.projectDirectory = projectDirectory
        }
    }

    @Injected(name: "projectsDirectory") var projectsDirectory: URL

    public init() {}
}

public let reducer: Reducer<State, Action, Environment> = .combine(
    Node.reducer.forEach(state: \.nodes,
                         action: /Action.node(id:action:),
                         environment: \.node),
    .init { state, action, environment in
        let directory: URL
        if let d = environment.projectDirectory {
            directory = d
        } else {
            directory = environment.projectsDirectory.appendingPathComponent(state.id, isDirectory: true)
            environment.projectDirectory = directory
        }
        switch action {
        case let .add(captured):
            let id = String(describing: state.nodes.count)
            let nodeDirectory = directory.appendingPathComponent(id, conformingTo: .folder)
            try? environment.fileManager.createDirectory(at: nodeDirectory, withIntermediateDirectories: true)
            guard environment.fileManager.fileExists(atPath: nodeDirectory.path) else {
                return .init(value: .failure(.cantCreateSubnode))
            }
            let node: Node.State = .init(id: id,
                                         createdAt: captured.createdAt,
                                         updatedAt: captured.createdAt,
                                         directory: nodeDirectory)
            state.nodes.append(node)
            state.export = nil
            return .init(value: .node(id: node.id, action: .write(captured)))
        case let .node(id, .didWrite(captured)):
            if let dir = environment.projectDirectory, environment.fileManager.fileExists(atPath: dir.path) {
                state.updatedAt = captured.createdAt
                return environment.writer.write(state: state, toProjectDirectory: dir)
                    .receive(on: DispatchQueue.main.eraseToAnyScheduler())
                    .fireAndForget()
            }
        case .export where state.export == nil:
            return environment.exporter.export(projectDirectory: directory)
                .receive(on: DispatchQueue.main.eraseToAnyScheduler())
                .catchToEffect { result in
                    switch result {
                    case .failure(let error):
                        return Action.failure(.exportError)
                    case .success(let url):
                        return Action.exported(url)
                    }
                }
        case .exported(let url):
            state.export = url
        default:
            break
        }
        return .none
    }
)
