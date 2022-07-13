//
//  Permissions.swift
//  Obture
//
//  Created by Roman on 29.06.2022.
//

import ComposableArchitecture
import AVFoundation
import Common

enum Permissions {

    enum Error: Equatable, Swift.Error {
        case errorRequestingAccess
    }

    typealias State = AVAuthorizationStatus?

    enum Action {
        case getStatus
        case gotStatus(AVAuthorizationStatus)
        case requestAccess
        case openSettings
        case failure(Error)
    }

    struct Environment {
        let status: () -> AVAuthorizationStatus
        let requestAccess: () async throws -> Bool
        let openSettings: () -> Void
    }

    static let reducer: Reducer<State, Action, Environment> = .init { state, action, environment in
        switch action {
        case .getStatus:
            let s = environment.status()
            return .init(value: .gotStatus(s))
        case .gotStatus(let s):
            state = s
            return .none
        case .requestAccess:
            return effect(scheduler: DispatchQueue.main.eraseToAnyScheduler()) {
                do {
                    let s = try await environment.requestAccess()
                    let status = environment.status()
                    return .gotStatus(status)
                } catch {
                    return .failure(.errorRequestingAccess)
                }
            }
        case .openSettings:
            return .fireAndForget {
                environment.openSettings()
            }
        case .failure(let error):
            assertionFailure(error.localizedDescription)
        }
        return .none
    }
}

extension Permissions.State {
    var isCameraPermitted: Bool {
        return self == .authorized
    }
}
