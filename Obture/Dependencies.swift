//
//  Dependencies.swift
//  Obture
//
//  Created by Roman on 29.06.2022.
//

import ComposableArchitecture

extension Resolver {

    static func obtureAppDependencies() -> Resolver.Type {
        let r = Resolver.self


        r.register(GetStarted.Environment.self, factory: GetStarted.Environment.init)
        r.register(Obture.Environment.self, factory: Obture.Environment.init)
        return r
    }
}
