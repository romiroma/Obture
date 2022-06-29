//
//  Obture.swift
//  Obture
//
//  Created by Roman on 29.06.2022.
//

import ComposableArchitecture

enum Obture {

    struct State: Equatable {
        var getStarted: GetStarted.State?
    }

    enum Action: Equatable {

        // Main Scene Lifecycle
        case active
        case background
        case inactive

        case getStarted(GetStarted.Action)
    }

    struct Environment {
        @Injected fileprivate var getStarted: GetStarted.Environment
    }

    static let reducer: Reducer<State, Action, Environment> = .combine(
        GetStarted.reducer.optional().pullback(state: \.getStarted,
                                               action: /Action.getStarted,
                                               environment: \.getStarted),
        .init { state, action, environment in
            switch action {
            case .active where state.getStarted == nil:
                state.getStarted = .init()
            default:
                break
            }
            return .none
        }.debug()
    )
}
