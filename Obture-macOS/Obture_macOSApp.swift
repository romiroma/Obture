//
//  Obture_macOSApp.swift
//  Obture-macOS
//
//  Created by Roman on 07.07.2022.
//

import SwiftUI
import ComposableArchitecture
import Common

@main
struct Obture_macOSApp: App {

    @Environment(\.scenePhase) private var scenePhase

    let store: Store<Obture.State, Obture.Action> = .init(initialState: .none,
                                                          reducer: Obture.reducer,
                                                          environment: Resolver.obtureAppDependencies().resolve())

    var body: some Scene {
        WithViewStore(store) { viewStore in
            WindowGroup {
                SwitchStore(store) {
                    CaseLet(state: /Obture.State.setup, action: Obture.Action.setup) { setupStore in
                        SetupView(store: setupStore)
                    }
                    CaseLet(state: /Obture.State.preview, action: Obture.Action.preview) { previewStore in
                        PreviewView(store: previewStore)
                    }
                    Default {
                        Rectangle()
                    }
                }
            }.onChange(of: scenePhase) { newValue in
                switch newValue {
                case .active:
                    viewStore.send(.active)
                case .background:
                    viewStore.send(.background)
                case .inactive:
                    viewStore.send(.inactive)
                @unknown default:
                    assertionFailure("Unknown scenePhase: \(newValue)")
                }
            }
        }
    }
}
