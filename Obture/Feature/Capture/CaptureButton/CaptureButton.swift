//
//  CaptureButton.swift
//  Obture
//
//  Created by Roman on 04.07.2022.
//

import ComposableArchitecture

enum CaptureButton {

    struct State: Equatable {}

    enum Action: Equatable {}

    struct Environment {}

    static let reducer: Reducer<State, Action, Environment> = .init { state, action, environment in
            .none
    }
}
