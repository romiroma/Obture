//
//  PermissionsView.swift
//  Obture
//
//  Created by Roman on 29.06.2022.
//

import SwiftUI
import ComposableArchitecture

struct PermissionsView: View {

    let store: Store<Permissions.State, Permissions.Action>

    var body: some View {
        WithViewStore(store) { viewStore in
            switch viewStore.state {
            case .none, .notDetermined:
                Button("Request Access") {
                    withAnimation {
                        viewStore.send(.requestAccess)
                    }
                }
            case .denied, .restricted:
                Button("Open Settings") {
                    withAnimation {
                        viewStore.send(.openSettings)
                    }
                }
            default:
                Text("Permissions View unexpected appearance")
            }
        }
    }
}
