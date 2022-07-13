//
//  FileSelection.swift
//  Obture-macOS
//
//  Created by Roman on 07.07.2022.
//

import ComposableArchitecture
import Common

enum FileSelection {

    enum State: Equatable {
        case idle
        case selecting
        case selected(URL)
    }

    enum Action {
        case openDialog
        case selected(URL)
        case dismiss
    }

    struct Environment {
        @Injected(name: "fileOpen") var fileOpen: () -> URL?
    }

    static let reducer: Reducer<State, Action, Environment> = .init { state, action, environment in
        switch action {
        case .openDialog:
            state = .selecting
            if let url = environment.fileOpen() {
                return .init(value: .selected(url))
            } else {
                return .init(value: .dismiss)
            }
        case .selected(let url):
            state = .selected(url)
        case .dismiss:
            state = .idle
        }
        return .none
    }
}
