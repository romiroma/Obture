//
//  Quality.swift
//  Obture-macOS
//
//  Created by Roman on 30.07.2022.
//

import ComposableArchitecture
import RealityFoundation

enum Quality {

    typealias State = PhotogrammetrySession.Request.Detail

    enum Action {
        case set(State)
        case done
    }

    struct Environment {}

    static let reducer: Reducer<State, Action, Environment> = .init { state, action, environment in
        switch action {
        case .set(let s):
            state = s
        case .done:
            break
        }
        return .none
    }
}

extension Quality.State: CaseIterable {
    public static var allCases: [PhotogrammetrySession.Request.Detail] = [.preview, .reduced, .medium, .full, .raw]
}
