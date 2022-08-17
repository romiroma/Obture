//
//  ObtureARView.swift
//  Obture
//
//  Created by Roman on 31.07.2022.
//

import Foundation
import SwiftUI
import ARKit
import RealityKit
import SceneKit.ModelIO

struct ObtureARView: UIViewRepresentable {

    func makeUIView(context: Context) -> ARView {

        let arView = ARView(frame: .zero)
        arView.automaticallyConfigureSession = false
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        configuration.sceneReconstruction = .meshWithClassification
        configuration.worldAlignment = .gravity
        guard ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth) else {
            assertionFailure()
            return arView
        }
        configuration.frameSemantics.insert(.sceneDepth)
//        configuration.frameSemantics.insert(.personSegmentationWithDepth)
        configuration.environmentTexturing = .none
        arView.session.run(configuration, options: .resetTracking)
        arView.environment.sceneUnderstanding.options.insert(.occlusion)
        arView.environment.sceneUnderstanding.options.insert(.collision)
        arView.environment.sceneUnderstanding.options.insert(.physics)
        let tap = UITapGestureRecognizer()
        tap.addTarget(context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        arView.addGestureRecognizer(tap)
        arView.cameraMode = .ar
        arView.debugOptions = [.showSceneUnderstanding, .showWorldOrigin]
        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {

    }
}

extension ObtureARView {
    class Coordinator: NSObject {

        var currentAnchor: AnchorEntity?

        @objc func handleTap(_ recognizer: UITapGestureRecognizer) {
            guard let arView = recognizer.view as? ARView else {
                return
            }

            let point = recognizer.location(in: arView)
            guard let query = arView.makeRaycastQuery(from: point, allowing: .estimatedPlane, alignment: .any) else {
                return
            }

            let results = arView.session.raycast(query)

            if let r = results.first, let currentFrame = arView.session.currentFrame {

                let origin = currentFrame.camera.transform.position
                let direction = r.worldTransform.position
//                nearbyFaceWithClassification(arView, to: direction) { centerOfFace, classification in
//                    print("=== result", centerOfFace, classification.description)
//                }

                let results =  arView.scene.raycast(from: origin, to: direction)
                for result in results {
                    let entity = result.entity

                    if entity.components.has(ModelComponent.self),
                       let modelEntity = entity.components[ModelComponent.self] as? ModelComponent,
                       let transform = entity.components[Transform.self] as? Transform {
                        let bounds = modelEntity.mesh.bounds

                        print("===modelEntity", modelEntity.mesh.bounds.boundingRadius)
                        let mesh = modelEntity.mesh
                        var materials = modelEntity.materials

//
//                        let size = bounds.max - bounds.min
//                        let meshedBox = MeshResource.generateBox(width: size.x,
//                                                                 height: size.y,
//                                                                 depth: size.z)
                        var metalicMaterial = PhysicallyBasedMaterial.init()
                        materials.insert(metalicMaterial, at: 0)
//                        metalicMaterial.baseColor = .init(CustomMaterial.BaseColor.init(tint: .yellow.withAlphaComponent(0.5)))


                        let model = ModelEntity(mesh: mesh, materials: materials)

                        // Create a new Anchor Entity using Identity Transform.
                        currentAnchor.map(arView.scene.removeAnchor)
                        let anchorEntity = AnchorEntity(world: transform.matrix)
                        currentAnchor = anchorEntity
                        // Add the entity as a child of the new anchor.
                        anchorEntity.addChild(model)

                        // Add the anchor to the scene.
                        arView.scene.addAnchor(anchorEntity)
                    }
                }


//                let sphereMesh = MeshResource.generateSphere(radius: 0.05)
//                let metalicMaterial = SimpleMaterial(color: .blue.withAlphaComponent(0.3), roughness: 0.2, isMetallic: true)
//                let sphereModel = ModelEntity(mesh: sphereMesh, materials: [metalicMaterial])
//
//                // Create a new Anchor Entity using Identity Transform.
//                currentAnchor.map(arView.scene.removeAnchor)
//                let anchorEntity = AnchorEntity(world: r.worldTransform)
//                currentAnchor = anchorEntity
//                // Add the entity as a child of the new anchor.
//                anchorEntity.addChild(sphereModel)
//
//                // Add the anchor to the scene.
//                arView.scene.addAnchor(anchorEntity)
            }

        }

        func nearbyFaceWithClassification(_ arView: ARView,
                                          to location: SIMD3<Float>,
                                          completionBlock: @escaping (SIMD3<Float>?, ARMeshClassification) -> Void) {
            guard let frame = arView.session.currentFrame else {
                completionBlock(nil, .none)
                return
            }

            // Perform the search asynchronously in order not to stall rendering.
            DispatchQueue.global().async {
                var meshAnchors = frame.anchors.compactMap({ $0 as? ARMeshAnchor })
                meshAnchors.sort { distance($0.transform.position, location) < distance($1.transform.position, location) }
                for anchor in meshAnchors {
                    for index in 0..<anchor.geometry.faces.count {
                        // Get the center of the face so that we can compare it to the given location.
                        let geometricCenterOfFace = anchor.geometry.centerOf(faceWithIndex: index)

                        // Convert the face's center to world coordinates.
                        var centerLocalTransform = matrix_identity_float4x4
                        centerLocalTransform.columns.3 = SIMD4<Float>(geometricCenterOfFace.0, geometricCenterOfFace.1, geometricCenterOfFace.2, 1)
                        let centerWorldPosition = (anchor.transform * centerLocalTransform).position

                        // We're interested in a classification that is sufficiently close to the given location––within 1 cm.
                        let distanceToFace = distance(centerWorldPosition, location)
                        print("distanceToFace", distanceToFace)
                        if distanceToFace <= 0.01 {
                            DispatchQueue.main.async {
                                addMeshEntity(with: anchor, to: arView)
                            }

                            // Get the semantic classification of the face and finish the search.
//                            let classification: ARMeshClassification = anchor.geometry.classificationOf(faceWithIndex: index)
//                            completionBlock(centerWorldPosition, classification)
                            return
                        }
                    }
                }

                // Let the completion block know that no result was found.
                completionBlock(nil, .none)
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        return .init()
    }
}
