//
//  Capture.swift
//  Obture
//
//  Created by Roman on 29.06.2022.
//

import ComposableArchitecture
import Foundation

enum Capture {

    struct State: Equatable {
        var camera: Camera.State
        var motion: Motion.State
        var project: ProjectEdit.State

        var buttonTitle: String = ""
    }

    enum Action: Equatable {
        case appear
        case camera(Camera.Action)
        case motion(Motion.Action)
        case project(ProjectEdit.Action)
        case takePhoto
        case photogrammetry
    }

    struct Environment {
        @Injected var camera: Camera.Environment
        @Injected var motion: Motion.Environment
        @Injected var project: ProjectEdit.Environment
    }

    static let reducer: Reducer<State, Action, Environment> = .combine(
        Camera.reducer.pullback(state: \.camera, action: /Action.camera, environment: \.camera),
        Motion.reducer.pullback(state: \.motion,
                                action: /Action.motion,
                                environment: \.motion),
        ProjectEdit.reducer.pullback(state: \.project,
                                    action: /Action.project,
                                    environment: \.project),
        .init { state, action, environment in
            switch action {
            case .appear:
                return .init(value: .motion(.start))
            case .takePhoto:
                return .init(value: .camera(.cameraSession(.takePhoto)))
            case let .camera(.cameraSession(.tookPhoto(photo))):
                return .init(value: .project(.add(photo)))
            case .project(.subnode(id: _, action: .didWrite)):
                state.buttonTitle = .init(describing: state.project.subnodes.count)
            case .photogrammetry:
                break
            default:
                break
            }
            return .none
        })
}
