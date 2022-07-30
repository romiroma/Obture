//
//  Obture.swift
//  Obture-macOS
//
//  Created by Roman on 07.07.2022.
//

import Common
import ComposableArchitecture
import UniformTypeIdentifiers
import Preview

enum Obture {
    enum State: Equatable {
        case none
        case setup(Setup.State)
        case photogrammetry(Photogrammetry.State)
        case preview(Preview.State)
    }

    enum Action {
        
        // Main Scene Lifecycle
        case active
        case background
        case inactive

        case setup(Setup.Action)
        case photogrammetry(Photogrammetry.Action)
        case preview(Preview.Action)
    }


    struct Environment {
        @Injected var setup: Setup.Environment
        @Injected var photogrammetry: Photogrammetry.Environment
        @Injected var preview: Preview.Environment
    }

    static let reducer: Reducer<State, Action, Environment> = .combine(
        Setup.reducer.pullback(state: /State.setup,
                               action: /Action.setup,
                               environment: \.setup),
        Photogrammetry.reducer.pullback(state: /State.photogrammetry,
                                        action: /Action.photogrammetry,
                                        environment: \.photogrammetry),
        Preview.reducer.pullback(state: /State.preview,
                                 action: /Action.preview,
                                 environment: \.preview),
        .init { state, action, environment in
            switch action {
            case .active where state == .none:
                state = .setup(.init(fileSelection: .idle, unpack: .none, quality: .full))//.setup(.fileSelection(.idle))
            case .photogrammetry(.completed(let url)):
                state = .preview(.init(modelURL: url))
            case .setup(.fileSelection(.selected(let url))) where url.pathExtension == "usdz":
                state = .preview(.init(modelURL: url))
            case .setup(.unpack(.finished(let url))):
                state = .photogrammetry(.idle(directory: url))
            default:
                break
            }
            return .none
        }
    ).debug()
}
