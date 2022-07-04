//
//  Resolver+Effect.swift
//  Obture
//
//  Created by Roman on 01.07.2022.
//

import Foundation
import ComposableArchitecture
import Combine

func effect<Output>(scheduler: AnySchedulerOf<DispatchQueue>,
                    action: @escaping () async -> Output) -> Effect<Output, Never> {
    Future<Output, Never> { promise in
        Task {
            promise(.success(await action()))
        }
    }.receive(on: scheduler, options: nil).eraseToEffect()
}
