//
//  FileSelectionView.swift
//  Obture-macOS
//
//  Created by Roman on 07.07.2022.
//

import SwiftUI
import ComposableArchitecture

struct FileSelectionView: View {

    let store: Store<FileSelection.State, FileSelection.Action>

    var body: some View {
        WithViewStore(store) { viewStore in
            Button("Open") {
                viewStore.send(.openDialog)
            }
        }
    }
}
