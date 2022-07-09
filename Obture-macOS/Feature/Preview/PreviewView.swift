//
//  PreviewView.swift
//  Obture-macOS
//
//  Created by Roman on 09.07.2022.
//

import SwiftUI
import SceneKit
import ComposableArchitecture

struct PreviewView: View {

    let store: Store<Preview.State, Preview.Action>
    let scene = SCNScene(named: "Preview")

    var cameraNode: SCNNode? {
        scene?.rootNode.childNode(withName: "camera", recursively: false)
    }

    var body: some View {
        WithViewStore(store) { viewStore in
            ZStack {
                if let scene = viewStore.scene {
                    ZStack {
                        SceneView(
                            scene: scene,
                            pointOfView: cameraNode,
                            options: [.allowsCameraControl, .autoenablesDefaultLighting ,.jitteringEnabled]
                        )
                        VStack {
                            Spacer()
                            Toggle("Enable Wireframe",
                                   isOn: viewStore.binding(get: \.isWireframeViewEnabled, send: { previewState in
                                    .setWireframeView(active: previewState)
                            })).background(Color.red)
                        }
                    }
                } else {
                    Circle()
                }
            }.onAppear {
                viewStore.send(.appear)
            }
        }
    }
}
