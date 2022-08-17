//
//  MeshAnchorGeometry.swift
//  Obture
//
//  Created by Roman on 03.08.2022.
//

import ARKit
import RealityKit
import Metal
import SwiftUI

struct generatedMesh {
    var vertices: [SIMD3<Float>] = []
    var triangles: [faceObj] = []
    var normals: [SIMD3<Float>] = []
}

struct faceObj {
    var classificationId: UInt32
    var triangles: [UInt32] = []
}

// The ARMeshAnchor contains polygonal geometry which we can use to create our own entity
func addMeshEntity(with anchor: ARMeshAnchor, to view: ARView) {
    /// 1. Create two entities, an AnchorEntity using the ARMeshAnchors position
    /// And a ModelEntity used to store our extracted mesh
    let meshAnchorEntity = AnchorEntity(world: anchor.transform)
    let meshModelEntity = createMeshEntity(with: anchor, from: view)
    meshAnchorEntity.name = anchor.identifier.uuidString + "_anchor"
    meshModelEntity.name = anchor.identifier.uuidString + "_model"

    /// 2. Add to scene
    meshAnchorEntity.addChild(meshModelEntity)
    view.scene.addAnchor(meshAnchorEntity)
}

func createMeshEntity(with anchor: ARMeshAnchor, from arView: ARView) -> ModelEntity {
    /// 1. Extract the the geometry from the ARMeshAnchor. Geometry is stored in a buffer-based array, format before using in MeshBuffers
    let anchorMesh = extractARMeshGeometry(with: anchor, in: arView)

    /// 2. Create a custom MeshDescriptor using the extracted mesh
    let mesh = createCustomMesh(name: "mesh", geometry: anchorMesh)



    /// 3. Create a new model entity for our mesh
    let generatedModel = ModelEntity(
        mesh: try! .generate(from: [mesh]),
        materials: [material]
    )
    return generatedModel
}

func removeMeshEntity(with anchor: ARMeshAnchor, from arView: ARView) {
    guard let meshAnchorEntity = arView.scene.findEntity(named: anchor.identifier.uuidString+"_anchor") else { return }
    arView.scene.removeAnchor(meshAnchorEntity as! AnchorEntity)
}

func updateMeshEntity(with anchor: ARMeshAnchor, in view: ARView ) {
    /// 1.Find the previously added meshes
    guard let entity = view.scene.findEntity(named: anchor.identifier.uuidString+"_model") else { return }
    let modelEntity = entity as! ModelEntity

    /// 2. Extact new geometry
    let anchorMesh = extractARMeshGeometry(with: anchor, in: view)

    /// 3. Create a new MeshDescriptor using the extracted mesh
    let mesh = createCustomMesh(name: "mesh", geometry: anchorMesh)

    /// 4. Try to update the mesh with the new geometry
    do {
        modelEntity.model!.mesh = try .generate(from: [mesh])
        modelEntity.model!.materials = [material]
    } catch {
        print("Error updating mesh geometry")
    }
}

func extractARMeshGeometry(with anchor: ARMeshAnchor, in view: ARView) -> generatedMesh {
    var vertices: [SIMD3<Float>] = []
    var triangles: [faceObj] = []
    var normals: [SIMD3<Float>] = []

    /// Extract the vertices using the Extension from Apple (VisualizingSceneSemantics)
    for index in 0..<anchor.geometry.vertices.count {
        let vertex = anchor.geometry.vertex(at: UInt32(index))
        let vertexPos = SIMD3<Float>(x: vertex.0, y: vertex.1, z: vertex.2)
        vertices.append(vertexPos)
    }
    /// Extract the faces
    for index in 0..<anchor.geometry.faces.count {
        let face = anchor.geometry.vertexIndicesOf(faceWithIndex: Int(index))
        let meshClassification: ARMeshClassification = anchor.geometry.classificationOf(faceWithIndex: index)
        triangles.append(faceObj(classificationId: UInt32(meshClassification.rawValue), triangles: [face[0],face[1],face[2]]))
    }
    /// Extract the normals. Normals uses an additional extension "normalsOf()"
    for index in 0..<anchor.geometry.normals.count {
        let normal = anchor.geometry.normalsOf(at: UInt32(index))
        normals.append(SIMD3<Float>(normal.0, normal.1, normal.2))
    }

    let extractedMesh = generatedMesh(vertices: vertices, triangles: triangles, normals: normals)
    return extractedMesh
}

func createCustomMesh(name: String, geometry: generatedMesh ) -> MeshDescriptor{
    /// Create a new MeshDescriptor using the generate geometry
    var mesh = MeshDescriptor(name: name)
    let faces = geometry.triangles.flatMap{ $0.triangles }
    let faceMaterials = geometry.triangles.compactMap{ $0.classificationId }
    let positions = MeshBuffers.Positions(geometry.vertices)
    let triangles = MeshDescriptor.Primitives.triangles(faces)
    let normals = MeshBuffers.Normals(geometry.normals)

    mesh.positions = positions
    mesh.primitives = triangles
    mesh.normals = normals

    /// Use the classificationIds to set the material on each face
    mesh.materials = MeshDescriptor.Materials.perFace(faceMaterials)

    return mesh
}

var material: RealityFoundation.Material {
    let m = SimpleMaterial(color: .yellow.withAlphaComponent(0.4), isMetallic: true)
    return m
}

