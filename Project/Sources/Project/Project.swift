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

public enum Error: Swift.Error, Equatable {
    case cantCreateSubnode
    case exportError
}

public struct State: Identifiable, Equatable, Codable {

    public let directory: URL

    public var id: String
    public var createdAt: Date
    public var updatedAt: Date

    public var subnodes: IdentifiedArrayOf<Node.State>

    public var export: URL?

    public init(directory: URL,
                id: String,
                createdAt: Date,
                updatedAt: Date,
                subnodes: IdentifiedArrayOf<Node.State>,
                export: URL?) {
        self.directory = directory
        self.id = id
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.subnodes = subnodes
        self.export = export
    }
}

public enum Action {
    case add(CapturedPhoto)
    case failure(Error)
    case subnode(id: Node.State.ID, action: Node.Action)
    case export
    case exported(URL)

    public static func == (lhs: Project.Action, rhs: Project.Action) -> Bool {
        false
    }
}

public struct Environment {
    @Injected var subnode: Node.Environment
    @Injected var exporter: Exporter

    public init() {}
}

public let reducer: Reducer<State, Action, Environment> = .combine(
    Node.reducer.forEach(state: \.subnodes,
                                    action: /Action.subnode(id:action:),
                                    environment: \.subnode),
    .init { state, action, environment in
        switch action {
        case let .add(captured):
            do {
                let subnode: Node.State = try .init(parentDirectory: state.directory, createdAt: captured.createdAt)
                state.subnodes.append(subnode)
                state.export = nil
                return .init(value: .subnode(id: subnode.id, action: .write(captured)))
            } catch {
                logger.error("\(error.localizedDescription)")
                return .init(value: .failure(.cantCreateSubnode))
            }
        case let .subnode(id, .didWrite(captured)):
            break
        case .export where state.export == nil:
            return environment.exporter.export(state)
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
