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

    struct State: Equatable {
        var fileSelection: FileSelection.State
        var unpack: Unpack.State
        var quality: Quality.State
    }

    enum Action {
        case fileSelection(FileSelection.Action)
        case unpack(Unpack.Action)
        case quality(Quality.Action)
    }

    struct Environment {
        @Injected var fileSelection: FileSelection.Environment
        @Injected var unpack: Unpack.Environment
        @Injected var quality: Quality.Environment
    }

    static let reducer: Reducer<State, Action, Environment> = .combine(
        FileSelection.reducer.pullback(state: \.fileSelection,
                                       action: /Setup.Action.fileSelection,
                                       environment: \.fileSelection),
        Unpack.reducer.pullback(state: \.unpack,
                                action: /Setup.Action.unpack,
                                environment: \.unpack),
        Quality.reducer.pullback(state: \.quality,
                                action: /Setup.Action.quality,
                                environment: \.quality),
        .init { state, action, environment in
            switch action {
            case .fileSelection(.selected(let url)):
                if url.pathExtension == "zip" {
                    state.unpack = .idle(input: url)
                    return .init(value: .unpack(.start))
                }
            case .unpack(.finished(let unpackedFolder)):
                break
//                state = .photogrammetry(.idle(directory: unpackedFolder))
            default:
                break
            }
            return .none
        }
    )
}
