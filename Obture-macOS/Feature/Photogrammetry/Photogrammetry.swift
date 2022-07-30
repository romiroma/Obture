//
//  Photogrammetry.swift
//  Obture-macOS
//
//  Created by Roman on 07.07.2022.
//

import ComposableArchitecture
import RealityKit
import RealityFoundation
import Common
import Combine

enum Photogrammetry {
    enum Error: Swift.Error, Equatable {
        static func == (lhs: Photogrammetry.Error, rhs: Photogrammetry.Error) -> Bool {
            return false
        }

        case sessionError(any Swift.Error)
        case samplesError(any Swift.Error)
    }

    enum State: Equatable {
        case idle(directory: URL, quality: Quality.State)
        case inProgress
        case failure(Error)
        case completed(URL)
    }

    enum Action {
        case start
        case samplesPrepared(fromURL: URL, any Sequence<PhotogrammetrySample>, quality: Quality.State)
        case started
        case completed(URL)
        case failed(Error)
        case openResult
    }

    struct Environment {
        @Injected(name: "samplesFromDirectory") var samplesFromDirectory: (URL) -> any Sequence<PhotogrammetrySample>
        @Injected var sessionHolder: SessionHolder
        @Injected(name: "openResult") var open: (URL) -> Void
        let mainQueue: DispatchQueue = .main
        let samplesQueue: DispatchQueue = .init(label: "com.andrykevych.Obture.PhotogrammetrySetup.samples", qos: .userInitiated)
    }

    static let reducer: Reducer<State, Action, Environment> = .init { state, action, environment in
        switch action {
        case .start:
            guard case let .idle(url, quality) = state else { break }
            return Future { (promise: @escaping Future<any Sequence<PhotogrammetrySample>, Never>.Promise) in
                environment.samplesQueue.async {
                    let samples = environment.samplesFromDirectory(url)
                    promise(.success(samples))
                }
            }
            .receive(on: environment.mainQueue)
            .catchToEffect { result in
                switch result {
                case .success(let sequence):
                    return Action.samplesPrepared(fromURL: url, sequence, quality: quality)
                case .failure(let error):
                    return Action.failed(.samplesError(error))
                }
            }
        case .samplesPrepared(let url, let samples, let quality):
            let session: PhotogrammetrySession
            do {
                session = try PhotogrammetrySession(input: samples)
            } catch {
                state = .failure(.sessionError(error))
                break
            }
            environment.sessionHolder.session = session
            do {
                try session.process(requests: [.modelFile(url: url.appendingPathComponent("object", conformingTo: .usdz),
                                                          detail: quality)])
            } catch {
                state = .failure(.sessionError(error))
                break
            }
            return Effect<Action, Never>.run { (s: Effect<Action, Never>.Subscriber) in
                Task {
                    do {
                        for try await output in session.outputs {
                            switch output {
                            case .processingComplete:
                                print("processingComplete")
                            case .requestError(let request, let error):
                                environment.mainQueue.async {
                                    s.send(.failed(.sessionError(error)))
                                }
                            case .requestComplete(let request, let result):
                                switch result {
                                case .modelFile(let url):
                                    environment.mainQueue.async {
                                        s.send(.completed(url))
                                    }
                                default:
                                    break
                                }
                            case .requestProgress(let request, let fractionComplete):
                                break
                            case .inputComplete:
                                environment.mainQueue.async {
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
        case .failed(let error):
            state = .failure(.samplesError(error))
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
        }
        return .none
    }
}

extension Task: Cancellable {}
