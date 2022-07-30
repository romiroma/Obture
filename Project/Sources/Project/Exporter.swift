//
//  Exporter.swift
//  Obture
//
//  Created by Roman on 07.07.2022.
//

import Foundation
import Combine
import Common

public protocol Exporter {
    func export(projectDirectory: URL) -> Future<URL, Error>
}
