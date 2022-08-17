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
                
//                CameraView(store: store.scope(state: \.camera, action: Capture.Action.camera))
//                    .edgesIgnoringSafeArea(.all)
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
//                        CaptureButton(store: store)
//                            .frame(alignment: .center)
//                        if viewStore.state.project.export == nil {
//                            Button("Photogrametry!") {
//                                viewStore.send(.photogrammetry)
//                            }
//                        } else {
//                            Button("Share!") {
//                                viewStore.send(.share)
//                            }
//                        }

                        Spacer()
                    }

                }

            }.onAppear {
                viewStore.send(.appear)
            }
        }
    }
}
