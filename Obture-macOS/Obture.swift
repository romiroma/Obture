//
//  Obture.swift
//  Obture-macOS
//
//  Created by Roman on 07.07.2022.
//

import Common
import ComposableArchitecture

enum Obture {
    enum State: Equatable {
        case none
        case setup(Setup.State)
        case photogrammetry(Photogrammetry.State)
    }

    enum Action: Equatable {
        
        // Main Scene Lifecycle
        case active
        case background
        case inactive

        case setup(Setup.Action)
    }


    struct Environment {
        @Injected var setup: Setup.Environment
    }

    static let reducer: Reducer<State, Action, Environment> = .combine(
        Setup.reducer.pullback(state: /State.setup,
                               action: /Action.setup,
                               environment: \.setup),
        .init { state, action, environment in
            switch action {
            case .active where state == .none:
                state = .setup(.fileSelection(.idle))
            default:
                break
            }
            return .none
        }
    ).debug()
}
