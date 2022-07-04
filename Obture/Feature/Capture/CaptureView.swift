//
//  CaptureView.swift
//  Obture
//
//  Created by Roman on 29.06.2022.
//

import SwiftUI
import ComposableArchitecture

struct CaptureView: View {

    let store: Store<Capture.State, Capture.Action>
    var body: some View {
        WithViewStore(store) { viewStore in
            ZStack {
                MotionView(store: store.scope(state: \.motion, action: Capture.Action.motion))
                CameraView(store: store.scope(state: \.camera, action: Capture.Action.camera))
                    .edgesIgnoringSafeArea(.all)
                VStack {
                    Spacer()
                    CaptureButton(store: store)
                        .frame(alignment: .center)
                }

            }.onAppear {
                viewStore.send(.appear)
            }
        }


    }
}
