//
//  SetupView.swift
//  Obture-macOS
//
//  Created by Roman on 07.07.2022.
//

import SwiftUI
import ComposableArchitecture

struct SetupView: View {

    let store: Store<Setup.State, Setup.Action>

    var body: some View {
        SwitchStore(store) {
            CaseLet(state: /Setup.State.fileSelection,
                    action: Setup.Action.fileSelection) { fileSelectionStore in
                FileSelectionView(store: fileSelectionStore)
            }
            CaseLet(state: /Setup.State.unpack,
                    action: Setup.Action.unpack) { unpackStore in
                UnpackView(store: unpackStore)
            }
            CaseLet(state: /Setup.State.photogrammetry,
                    action: Setup.Action.photogrammetry) { photogrammetryStore in
                PhotogrammetryView(store: photogrammetryStore)
            }
        }
    }
}
