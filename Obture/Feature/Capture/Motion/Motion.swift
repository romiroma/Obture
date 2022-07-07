//
//  Motion.swift
//  Obture
//
//  Created by Roman on 04.07.2022.
//

import ComposableArchitecture
import CoreMotion
import Common

enum Motion {

    enum State: Equatable {
        case idle
        case starting
        case running
        case stopping
    }

    enum Action: Equatable {
        case start
        case started
        case stop
        case stopped
    }

    struct Environment {
        @Injected var motionManager: CMMotionManager
    }

    static let reducer: Reducer<State, Action, Environment> = .init { state, action, environment in
        guard environment.motionManager.isDeviceMotionAvailable else { return .none }
        switch action {
        case .start where state == .idle:
            environment.motionManager.startDeviceMotionUpdates()
            state = .starting
            return .init(value: .started)
        case .started where state == .starting:
            state = environment.motionManager.isDeviceMotionActive ? .running : .idle
        case .stop where state == .running:
            environment.motionManager.stopDeviceMotionUpdates()
            state = .stopping
            return .init(value: .stopped)
        case .stopped:
            state = environment.motionManager.isDeviceMotionActive ? .running : .idle
        default:
            break
        }
        return .none
    }
}
