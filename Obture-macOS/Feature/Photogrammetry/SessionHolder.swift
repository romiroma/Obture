//
//  SessionHolder.swift
//  Obture-macOS
//
//  Created by Roman on 07.07.2022.
//

import Foundation
import RealityKit

protocol SessionHolder: AnyObject {
    var session: PhotogrammetrySession? { get set }
}
