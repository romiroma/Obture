//
//  Unpack.swift
//  Obture-macOS
//
//  Created by Roman on 07.07.2022.
//

import ComposableArchitecture
import Common
import Combine

enum Unpack {

    enum Error: Swift.Error, Equatable {
        case unpackError
    }

    enum State: Equatable {
        case idle(input: URL)
        case inProgress(input: URL, value: Double)
        case done(outputFolder: URL)
        case failed(Error)
    }

    enum Action {
        case start
        case progress(Double)
        case finished(URL)
        case failure(Error)
    }

    struct Environment {
        @Injected(name: "unpackProject") var unpackProject: (URL) -> Future<URL, Swift.Error>
    }

    static let reducer: Reducer<State, Action, Environment> = .init { state, action, environment in
        switch action {
        case .start:
            guard case let .idle(url) = state else { break }
            state = .inProgress(input: url, value: 0)
            return environment.unpackProject(url)
                .receive(on: DispatchQueue.main.eraseToAnyScheduler())
                .catchToEffect { result in
                switch result {
                case .failure(let error):
                    return .failure(.unpackError)
                case .success(let unpackedFolder):
                    return .finished(unpackedFolder)
                }
            }
        case .progress(_):
            break
        case .finished(let url):
            state = .done(outputFolder: url)
        case .failure(let error):

            state = .failed(Unpack.Error.unpackError)
        }
        return .none
    }
}
