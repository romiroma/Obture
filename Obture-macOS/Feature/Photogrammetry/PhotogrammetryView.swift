//
//  PhotogrammetryView.swift
//  Obture-macOS
//
//  Created by Roman on 07.07.2022.
//

import SwiftUI
import Common
import ComposableArchitecture

struct PhotogrammetryView: View {

    let store: Store<Photogrammetry.State, Photogrammetry.Action>

    var body: some View {
        WithViewStore(store) { viewStore in
            VStack {
                switch viewStore.state {
                case .idle:
                    ProgressView("Starting Up...")
                case .inProgress:
                    ProgressView("In Progress...")
                case .failure(let error):
                    Text(error.localizedDescription).foregroundColor(.red)
                case .completed:
                    Button("Open Result") {
                        viewStore.send(.openResult)
                    }
                }
            }.onAppear {
                viewStore.send(.start)
            }
        }
    }
}
