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
                Button("Continue") {
                    viewStore.send(.continue)
                }
            }.onAppear {
                viewStore.send(.appear)
            }
        }
    }
}

struct GetStartedView_Previews: PreviewProvider {
    static var previews: some View {
        GetStartedView(store: .init(initialState: .init(), reducer: GetStarted.reducer, environment: Resolver.resolve()))
    }
}
