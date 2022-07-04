//
//  Node.swift
//  Obture
//
//  Created by Roman on 04.07.2022.
//

import ComposableArchitecture

extension NewProject {
    enum SubNode {

        struct State: Node {
            let directory: URL
            var id: String
            var created_at: Date
            var updated_at: Date
        }

        enum Action: Equatable {}

        struct Environment {}

        static let reducer: Reducer<State, Action, Environment> = .init { state, action, environment in
                .none
        }
    }
}

