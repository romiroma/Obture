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

import os

private let logger = Logger(subsystem: "com.andrykevych.Obture",
                            category: "Project")

enum Project {

    enum Error: Swift.Error, Equatable {
        case cantCreateSubnode
        case exportError
    }

    struct State: Identifiable, Equatable, Codable {

        let directory: URL

        var id: String
        var createdAt: Date
        var updatedAt: Date

        var subnodes: IdentifiedArrayOf<Project.SubNode.State>

        var export: URL?
    }

    enum Action: Equatable {
        case add(CapturedPhoto)
        case failure(Error)
        case subnode(id: Project.SubNode.State.ID, action: Project.SubNode.Action)
        case export
        case exported(URL)

        static func == (lhs: Project.Action, rhs: Project.Action) -> Bool {
            false
        }
    }

    struct Environment {
        @Injected var subnode: SubNode.Environment
        @Injected var exporter: Exporter
    }

    static let reducer: Reducer<State, Action, Environment> = .combine(
        Project.SubNode.reducer.forEach(state: \.subnodes,
                                            action: /Action.subnode(id:action:),
                                            environment: \.subnode),
        .init { state, action, environment in
            switch action {
            case let .add(captured):
                do {
                    let subnode: SubNode.State = try .init(parentDirectory: state.directory, createdAt: captured.createdAt)
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
}
