//
//  NewProject.swift
//  Obture
//
//  Created by Roman on 04.07.2022.
//

import ComposableArchitecture

enum NewProject {

    struct State: Project {

        let directory: URL

        var id: String
        var created_at: Date
        var updated_at: Date

        var subnodes: [NewProject.SubNode.State]
    }

    enum Action: Equatable {}

    struct Environment {}

    static let reducer: Reducer<State, Action, Environment> = .init { state, action, environment in
            .none
    }
}

extension NewProject.State {
    var nodes: [any Node] {
        return subnodes as [any Node]
    }
}
