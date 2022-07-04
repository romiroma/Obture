//
//  MotionStore.swift
//  Obture
//
//  Created by Roman on 04.07.2022.
//

import SwiftUI
import ComposableArchitecture

struct MotionView: View {
    let store: Store<Motion.State, Motion.Action>

    var body: some View {
        WithViewStore(store) { viewStore in
            EmptyView()
                .onAppear { viewStore.send(.start) }
        }
    }
}
