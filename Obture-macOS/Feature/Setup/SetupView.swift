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
        VStack {
            FileSelectionView(store: store.scope(state: \.fileSelection, action: Setup.Action.fileSelection))
            UnpackView(store: store.scope(state: \.unpack, action: Setup.Action.unpack))
            QualityView(store: store.scope(state: \.quality, action: Setup.Action.quality))
        }
//        SwitchStore(store) {
//            CaseLet(state: /Setup.State.fileSelection,
//                    action: Setup.Action.fileSelection) { fileSelectionStore in
//                FileSelectionView(store: fileSelectionStore)
//            }
//            CaseLet(state: /Setup.State.unpack,
//                    action: Setup.Action.unpack) { unpackStore in
//
//            }
//            CaseLet(state: /Setup.State.quality,
//                    action: Setup.Action.quality) { qualityStore in
//                QualityView(store: qualityStore)
//            }
//        }
    }
}
