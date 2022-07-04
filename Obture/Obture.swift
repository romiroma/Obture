//
//  Obture.swift
//  Obture
//
//  Created by Roman on 29.06.2022.
//

import ComposableArchitecture

enum Obture {

    enum State: Equatable {
        case getStarted(GetStarted.State)
        case capture(Capture.State)
    }

    enum Action: Equatable {

        // Main Scene Lifecycle
        case active
        case background
        case inactive

        // Feature Actions
        case getStarted(GetStarted.Action)
        case capture(Capture.Action)
    }

    struct Environment {
        @Injected fileprivate var getStarted: GetStarted.Environment
        @Injected fileprivate var capture: Capture.Environment
    }

    static let reducer: Reducer<State, Action, Environment> = .combine(
        GetStarted.reducer.pullback(state: /State.getStarted,
                                    action: /Action.getStarted,
                                    environment: \.getStarted),
        Capture.reducer.pullback(state: /State.capture,
                                 action: /Action.capture,
                                 environment: \.capture),
        .init { state, action, environment in
            switch action {
            case .active:
                switch state {
                case .capture(let captureState):
                    switch captureState.camera {
                    case .cameraSession(.idle(.inactiveState)):
                        return .init(value: .capture(.camera(.cameraSession(.start))))
                    default:
                        break
                    }
                default:
                    break
                }
            case .inactive:
                switch state {
                case .capture(let captureState):
                    switch captureState.camera {
                    case .cameraSession(.running):
                        return .init(value: .capture(.camera(.cameraSession(.stop(.inactiveState)))))
                    default:
                        break
                    }

                case .getStarted(_):
                    return .none
                }
            case .getStarted(.continue):
                state = .capture(.init(camera: .permissions(.none), motion: .idle))
            default:
                break
            }
            return .none
        }
    ).debug()
}
