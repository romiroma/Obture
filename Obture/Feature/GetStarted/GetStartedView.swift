//
//  GetStartedView.swift
//  Obture
//
//  Created by Roman on 29.06.2022.
//

import SwiftUI
import ComposableArchitecture

struct GetStartedView: View {
    let store: Store<GetStarted.State, GetStarted.Action>

    var body: some View {
        WithViewStore(store) { viewStore in
            VStack {
                Spacer()
//                NavigationLink("Continue", value: "Capture")
                Button("Continue") {
                    withAnimation {
                        viewStore.send(.continue)
                    }
                }
            }.onAppear {
                viewStore.send(.appear)
            }
        }
    }
}
