//
//  ObtureApp.swift
//  Obture
//
//  Created by Roman on 29.06.2022.
//

import SwiftUI
import ComposableArchitecture
import Common

@main
struct ObtureApp: App {

    @Environment(\.scenePhase) private var scenePhase

    let store: Store<Obture.State, Obture.Action> = .init(initialState: .getStarted(.init()),
                                                          reducer: Obture.reducer,
                                                          environment: Resolver.obtureAppDependencies().resolve())
    
    var body: some Scene {
        WithViewStore(store) { viewStore in
            WindowGroup {
                    SwitchStore(store) {
                        CaseLet(state: /Obture.State.getStarted, action: Obture.Action.getStarted) { getStartedStore in
                            GetStartedView(store: getStartedStore)
                        }
                        CaseLet(state: /Obture.State.capture, action: Obture.Action.capture) { captureStore in
                            CaptureView(store: captureStore)
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
