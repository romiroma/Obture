//
//  CameraView.swift
//  Obture
//
//  Created by Roman on 01.07.2022.
//

import SwiftUI
import ComposableArchitecture

struct CameraView: View {

    let store: Store<Camera.State, Camera.Action>
    
    var body: some View {
        WithViewStore(store) { viewStore in
            SwitchStore(store) {
                CaseLet(state: /Camera.State.permissions,
                        action: Camera.Action.permissions) { permissionsStore in
                    PermissionsView(store: permissionsStore)
                }
                CaseLet(state: /Camera.State.cameraSession,
                        action: Camera.Action.cameraSession) { cameraSessionStore in
                    ZStack {
                        CameraSessionView(store: cameraSessionStore)
                    }

                }
            }
            .edgesIgnoringSafeArea(.all)
            .onAppear {
                viewStore.send(.appear)
            }
        }

    }
}
