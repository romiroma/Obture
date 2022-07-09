//
//  Preview.swift
//  Obture-macOS
//
//  Created by Roman on 09.07.2022.
//

import ComposableArchitecture
import SceneKit
import SceneKit.ModelIO
import AppKit

enum Preview {

    struct State: Equatable {
        let modelURL: URL
        var scene: SCNScene?

        var isWireframeViewEnabled: Bool = false
    }

    enum Action: Equatable {
        case appear
        case setWireframeView(active: Bool)
    }

    struct Environment {

    }

    static let reducer: Reducer<State, Action, Environment> = .init { state, action, environment in
        switch action {
        case .appear:
            let asset = MDLAsset(url: state.modelURL)
            asset.loadTextures()
            let scene = SCNScene(mdlAsset: asset)
            state.scene = scene
        case let .setWireframeView(active):
            guard let scene = state.scene else {
                break
            }
            let deepestRootNode = scene.rootNode.deepestRootNode()
            deepestRootNode.geometry?.firstMaterial?.fillMode = active ? .lines : .fill
            state.isWireframeViewEnabled = active
        }
        return .none
    }
}

private extension SCNNode {
    func deepestRootNode() -> SCNNode {
        if let childNode = childNodes.first, childNodes.count == 1 {
            return childNode.deepestRootNode()
        } else {
            return self
        }
    }
}
