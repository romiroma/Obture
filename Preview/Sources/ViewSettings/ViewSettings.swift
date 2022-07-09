//
//  ViewSettings.swift
//  
//
//  Created by Roman on 10.07.2022.
//

import ComposableArchitecture
import Common
import SceneKit
import SceneKit.ModelIO
import AppKit

public struct State: Equatable {
    
}

public enum Action: Equatable {}

public struct Environment {}

public let reducer: Reducer<State, Action, Environment> = .init { state, action, environment in
        .none
}
