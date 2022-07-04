//
//  CameraSessionView.swift
//  Obture
//
//  Created by Roman on 03.07.2022.
//

import SwiftUI
import ComposableArchitecture

struct CameraSessionView: View {

    let store: Store<CameraSession.State, CameraSession.Action>

    var body: some View {
        WithViewStore(store) { viewStore in
            switch viewStore.state {
            case .none:
                Image("idle").edgesIgnoringSafeArea(.all)
            case .settingUp:
                ProgressView()
            case .running(let session):
                VStack {
                    CameraPreviewView(session: session)
                        .edgesIgnoringSafeArea(.all)
                }
            case .idle(_):
                Image("idle").edgesIgnoringSafeArea(.all)
            }
        }
    }
}
