//
//  Photogrammetry.swift
//  Obture-macOS
//
//  Created by Roman on 07.07.2022.
//

import ComposableArchitecture
import RealityKit
import Common
import Combine

enum Photogrammetry {
    enum Error: Swift.Error, Equatable {
        static func == (lhs: Photogrammetry.Error, rhs: Photogrammetry.Error) -> Bool {
            return false
        }

        case sessionError(any Swift.Error)
    }

    enum State: Equatable {
        case idle(directory: URL)
        case inProgress
        case failure(Error)
        case completed(URL)
    }

    enum Action: Equatable {
        case start
        case started
        case completed(URL)
        case failed(Error)
        case openResult
    }

    struct Environment {
        @Injected(name: "samplesFromDirectory") var samplesFromDirectory: (URL) -> any Sequence<PhotogrammetrySample>
        @Injected var sessionHolder: SessionHolder
        @Injected(name: "openResult") var open: (URL) -> Void
    }

    static let reducer: Reducer<State, Action, Environment> = .init { state, action, environment in
        switch action {
        case .start:
            guard case let .idle(url) = state else { break }
            let session: PhotogrammetrySession
            do {
                let samples = environment.samplesFromDirectory(url)
                session = try PhotogrammetrySession(input: samples)
            } catch {
                state = .failure(.sessionError(error))
                break
            }
            environment.sessionHolder.session = session
            do {
                try session.process(requests: [.modelFile(url: url.appendingPathComponent("object", conformingTo: .usdz),
                                                          detail: .raw)])
            } catch {
                state = .failure(.sessionError(error))
                break
            }

            let queue: DispatchQueue = .main
            return Effect<Action, Never>.run { (s: Effect<Action, Never>.Subscriber) in
                Task {
                    do {
                        for try await output in session.outputs {
                            switch output {
                            case .processingComplete:
                                print("processingComplete")
                            case .requestError(let request, let error):
                                queue.async {
                                    s.send(.failed(.sessionError(error)))
                                }
                            case .requestComplete(let request, let result):
                                switch result {
                                case .modelFile(let url):
                                    queue.async {
                                        s.send(.completed(url))
                                    }
                                default:
                                    break
                                }
                            case .requestProgress(let request, let fractionComplete):
                                break
                            case .inputComplete:  // data ingestion only!
                                queue.async {
                                    s.send(.started)
                                }
                            case .invalidSample(let id, let reason):
                                print(".invalidSample(id: \(id), reason: \(reason)):")
                            case .skippedSample(let id):
                                print(".skippedSample(id: \(id):")
                            case .automaticDownsampling:
                                print(".automaticDownsampling")
                            case .processingCancelled:
                                print(".processingCancelled")
                            @unknown default:
                                break
                            }
                        }
                    } catch {
                        s.send(.failed(.sessionError(error)))
                    }
                }
            }
            .cancellable(id: "PhotogrammetrySession")
        case .started:
            state = .inProgress
        case .completed(let url):
            state = .completed(url)
        case .openResult:
            guard case let .completed(url) = state else {
                break
            }
            return .fireAndForget {
                environment.open(url)
            }
        default:
            break
        }
        return .none
    }
}

extension Task: Cancellable {}
