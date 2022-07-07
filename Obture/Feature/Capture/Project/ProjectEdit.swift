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
                            category: "ProjectEdit")

enum ProjectEdit {

    enum Error: Swift.Error, Equatable {
        case cantCreateSubnode
    }

    struct State: Project {

        let directory: URL

        var id: String
        var createdAt: Date
        var updatedAt: Date

        var subnodes: IdentifiedArrayOf<ProjectEdit.SubNode.State>
    }

    enum Action: Equatable {
        case add(CapturedPhoto)
        case failure(CapturedPhoto, Error)
        case subnode(id: ProjectEdit.SubNode.State.ID, action: ProjectEdit.SubNode.Action)

        static func == (lhs: ProjectEdit.Action, rhs: ProjectEdit.Action) -> Bool {
            false
        }
    }

    struct Environment {
        @Injected var subnode: SubNode.Environment
    }

    static let reducer: Reducer<State, Action, Environment> = .combine(
        ProjectEdit.SubNode.reducer.forEach(state: \.subnodes,
                                            action: /Action.subnode(id:action:),
                                            environment: \.subnode),
        .init { state, action, environment in
            switch action {
            case let .add(captured):
                do {
                    let subnode: SubNode.State = try .init(parentDirectory: state.directory, createdAt: captured.createdAt)
                    state.subnodes.append(subnode)
                    return .init(value: .subnode(id: subnode.id, action: .write(captured)))
                } catch {
                    logger.error("\(error.localizedDescription)")
                    return .init(value: .failure(captured, .cantCreateSubnode))
                }
            case let .subnode(id, .didWrite(captured)):
                break
            default:
                break
            }
            return .none
        }
    )
}

extension ProjectEdit.State {
    var nodes: [any Node] {
        return subnodes.map { $0 as any Node }
    }
}
