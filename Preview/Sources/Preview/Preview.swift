
import ComposableArchitecture
import Common
import SceneKit
import SceneKit.ModelIO
import AppKit

public struct State: Equatable {
    public let modelURL: URL
    public var scene: SCNScene? = nil

    public var isWireframeViewEnabled: Bool = false

    public init(modelURL url: URL) {
        modelURL = url
    }
}

public enum Action {
    case appear
    case setWireframeView(active: Bool)
}

public struct Environment {
    public init() {}
}

public let reducer: Reducer<State, Action, Environment> = .init { state, action, environment in
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

private extension SCNNode {
    func deepestRootNode() -> SCNNode {
        if let childNode = childNodes.first, childNodes.count == 1 {
            return childNode.deepestRootNode()
        } else {
            return self
        }
    }
}
