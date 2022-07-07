//
//  GetStarted.swift
//  Obture
//
//  Created by Roman on 29.06.2022.
//

import ComposableArchitecture

enum GetStarted {
    struct State: Equatable {}

    enum Action: Equatable {
        case appear
        case `continue`
    }

    struct Environment {}

    static let reducer: Reducer<State, Action, Environment> = .init { state, action, environment in
        switch action {
        case .appear:
            return .none
        case .continue:
            return .none
        }
    }
}
