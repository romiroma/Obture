//
//  CameraSession.swift
//  Obture
//
//  Created by Roman on 02.07.2022.
//

import AVFoundation
import ComposableArchitecture
import Combine
import CoreLocation
import CoreMotion

enum CameraSession {

    enum StopReason {
        case inactiveState
    }

    enum Error: Swift.Error, Equatable {
        case configurationError
        case photoCaptureError
    }

    enum State: Equatable {
        case none
        case settingUp
        case running(AVCaptureSession)
        case idle(StopReason)
    }

    enum Action: Equatable {
        case setup
        case failure(Error)
        case didSetup
        case start
        case didStart(AVCaptureSession)
        case stop(StopReason)
        case didStop(StopReason)
        case takePhoto
        case tookPhoto(CapturedPhoto)
    }

    struct Environment {
        @Injected(name: "CaptureSession") var session: AVCaptureSession
        @Injected(name: "SessionQueue") var queue: DispatchQueue
        @Injected var motionManager: CMMotionManager
        @Injected var sessionConfigurator: SessionConfigurator
        @Injected var photoTaker: PhotoTaker
    }

    static let reducer: Reducer<State, Action, Environment> = .init { state, action, environment in
        switch action {
        case .setup where state == .none:
            state = .settingUp
            return environment.sessionConfigurator
                .configure(environment.session, queue: environment.queue)
                .receive(on: DispatchQueue.main.eraseToAnyScheduler())
                .catchToEffect { result in
                    switch result {
                    case .success:
                        return Action.didSetup
                    case .failure(let failure):
                        return Action.failure(failure)
                    }
                }
        case .didSetup:
            return environment.sessionConfigurator
                .start(environment.session, queue: environment.queue)
                .receive(on: DispatchQueue.main.eraseToAnyScheduler())
                .catchToEffect { result in
                    switch result {
                    case .success:
                        return Action.didStart(environment.session)
                    case .failure(let failure):
                        return Action.failure(failure)
                    }
                }
        case .didStart:
            state = .running(environment.session)
        case .failure(let error):
            switch error {
            case .configurationError:
                state = .none
            case .photoCaptureError:
                break
            }
        case .start:
            return environment.sessionConfigurator
                .start(environment.session, queue: environment.queue)
                .receive(on: DispatchQueue.main.eraseToAnyScheduler())
                .catchToEffect { result in
                    switch result {
                    case .success:
                        return Action.didStart(environment.session)
                    case .failure(let failure):
                        return Action.failure(failure)
                    }
                }
        case .stop(let reason):
            return environment.sessionConfigurator
                .stop(environment.session, queue: environment.queue)
                .receive(on: DispatchQueue.main.eraseToAnyScheduler())
                .catchToEffect { result in
                    switch result {
                    case .success:
                        return Action.didStop(reason)
                    case .failure(let failure):
                        return Action.failure(failure)
                    }
                }
        case .didStop(let reason):
            state = .idle(reason)
        case .takePhoto:
            // TODO: As PhotoTaker is Environment also, configure it with proper session, queue, photoOutputProvider and MotionManager.
            return environment.photoTaker.takePhoto(environment.session,
                                                    queue: environment.queue,
                                                    from: environment.sessionConfigurator.photoOutput,
                                                    motionManager: environment.motionManager)
            .receive(on: DispatchQueue.main.eraseToAnyScheduler())
            .catchToEffect { result in
                switch result {
                case let .success(photo):
                    return Action.tookPhoto(photo)
                case .failure(let failure):
                    return Action.failure(.photoCaptureError)
                }
            }
        case .tookPhoto:
            break
        default:
            break
        }
        return .none
    }
}
