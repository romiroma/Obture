//
//  UnpackView.swift
//  Obture-macOS
//
//  Created by Roman on 07.07.2022.
//

import SwiftUI
import ComposableArchitecture

struct UnpackView: View {

    let store: Store<Unpack.State, Unpack.Action>

    var body: some View {
        WithViewStore(store) { viewStore in
            switch viewStore.state {
            case .idle(let url):
                ProgressView(url.lastPathComponent)
            case .inProgress(input: let url, value: let value):
                ProgressView("Extracting... \(url.lastPathComponent)")
            case .failed(let error):
                Text(error.localizedDescription)
            case .done(let output):
                Text(" : -> " + output.absoluteString)
            }
        }
    }
}
