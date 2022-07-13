//
//  Camera.swift
//  Obture
//
//  Created by Roman on 01.07.2022.
//

import ComposableArchitecture
import Foundation
import AVFoundation
import Common

enum Camera {

    enum State: Equatable {
        case permissions(Permissions.State)
        case cameraSession(CameraSession.State)
    }

    enum Action {
        case appear
        case permissions(Permissions.Action)
        case cameraSession(CameraSession.Action)
    }

    struct Environment {
        @Injected var permissions: Permissions.Environment
        @Injected var cameraSession: CameraSession.Environment
    }

    static let reducer: Reducer<State, Action, Environment> = .combine(
        Permissions.reducer.pullback(state: /State.permissions,
                                     action: /Action.permissions,
                                     environment: \.permissions),
        CameraSession.reducer.pullback(state: /State.cameraSession,
                                       action: /Action.cameraSession,
                                       environment: \.cameraSession),
        .init { state, action, environment in
            switch action {
            case .appear where state == .permissions(.none):
                return .init(value: .permissions(.getStatus))
            case let .permissions(.gotStatus(s)) where s == .authorized:
                state = .cameraSession(.none)
                return .init(value: .cameraSession(.setup))
            case .cameraSession(.didStart(let session)):
                break
            default:
                break
            }
            return .none
        }
    )
}
