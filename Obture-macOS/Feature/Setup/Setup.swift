//
//  Setup.swift
//  Obture-macOS
//
//  Created by Roman on 07.07.2022.
//

import ComposableArchitecture
import Common
import Combine
import Files

enum Setup {

    enum Error: Swift.Error, Equatable {

    }

    enum State: Equatable {
        case fileSelection(FileSelection.State)
        case unpack(Unpack.State)
        case photogrammetry(Photogrammetry.State)
    }

    enum Action: Equatable {
        case fileSelection(FileSelection.Action)
        case unpack(Unpack.Action)
        case photogrammetry(Photogrammetry.Action)
    }

    struct Environment {
        @Injected var fileSelection: FileSelection.Environment
        @Injected var unpack: Unpack.Environment
        @Injected var photogrammetry: Photogrammetry.Environment
    }

    static let reducer: Reducer<State, Action, Environment> = .combine(
        FileSelection.reducer.pullback(state: /Setup.State.fileSelection,
                                       action: /Setup.Action.fileSelection,
                                       environment: \.fileSelection),
        Unpack.reducer.pullback(state: /Setup.State.unpack,
                                action: /Setup.Action.unpack,
                                environment: \.unpack),
        Photogrammetry.reducer.pullback(state: /Setup.State.photogrammetry,
                                        action: /Setup.Action.photogrammetry,
                                        environment: \.photogrammetry),
        .init { state, action, environment in
            switch action {
            case .fileSelection(.selected(let url)):
                if url.pathExtension == "zip" {
                    state = .unpack(.idle(input: url))
                    return .init(value: .unpack(.start))
                }
            case .unpack(.finished(let unpackedFolder)):
                state = .photogrammetry(.idle(directory: unpackedFolder))
                return .init(value: Action.photogrammetry(.start))
            default:
                break
            }
            return .none
        }
    )
}
