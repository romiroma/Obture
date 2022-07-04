//
//  Project.swift
//  Obture
//
//  Created by Roman on 04.07.2022.
//

import Foundation

protocol Project: Node {
    var nodes: [any Node] { get }
}

protocol Node: Identifiable, Equatable, Codable {
    var id: String { get }

    var created_at: Date { get }
    var updated_at: Date { get }
}
