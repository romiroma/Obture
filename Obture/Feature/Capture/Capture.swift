//
//  Capture.swift
//  Obture
//
//  Created by Roman on 29.06.2022.
//

import ComposableArchitecture

enum Capture {

    struct State: Equatable {
        var camera: Camera.State
        var motion: Motion.State
        var project: NewProject.State
    }

    enum Action: Equatable {
        case appear
        case camera(Camera.Action)
        case motion(Motion.Action)
        case project(NewProject.Action)
        case takePhoto
    }

    struct Environment {
        @Injected var camera: Camera.Environment
        @Injected var motion: Motion.Environment
        @Injected var project: NewProject.Environment
    }

    static let reducer: Reducer<State, Action, Environment> = .combine(
        Camera.reducer.pullback(state: \.camera, action: /Action.camera, environment: \.camera),
        Motion.reducer.pullback(state: \.motion,
                                action: /Action.motion,
                                environment: \.motion),
        NewProject.reducer.pullback(state: \.project,
                                    action: /Action.project,
                                    environment: \.project),
        .init { state, action, environment in
            switch action {
            case .appear:
                return .init(value: .motion(.start))
            case .takePhoto:
                return .init(value: .camera(.cameraSession(.takePhoto)))
            default:
                break
            }
            return .none
        })
}
