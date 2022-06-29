//
//  ObtureApp.swift
//  Obture
//
//  Created by Roman on 29.06.2022.
//

import SwiftUI
import ComposableArchitecture

@main
struct ObtureApp: App {

    @Environment(\.scenePhase) private var scenePhase

    let store: Store<Obture.State, Obture.Action> = .init(initialState: .init(),
                                                          reducer: Obture.reducer,
                                                          environment: Resolver.obtureAppDependencies().resolve())
    
    var body: some Scene {
        WithViewStore(store) { viewStore in
            WindowGroup {
                IfLetStore(store.scope(state: \.getStarted, action: { Obture.Action.getStarted($0) })) { s in
                    GetStartedView(store: s)
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
