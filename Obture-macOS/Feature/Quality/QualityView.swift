//
//  QualityView.swift
//  Obture-macOS
//
//  Created by Roman on 30.07.2022.
//

import SwiftUI
import ComposableArchitecture

struct QualityView: View {
    let store: Store<Quality.State, Quality.Action>

    var body: some View {
        WithViewStore(store) { viewStore in
            HStack {
                Text("Quality")
                HStack {
                    Spacer()
                    Slider(value: viewStore.binding(get: { Double($0.rawValue) }, send: { value in
                        let detailLevel = Int(value)
                        return .set(Quality.State(rawValue: detailLevel)!)
                    }), in: Double(Quality.State.preview.rawValue)...Double(Quality.State.raw.rawValue),
                           step: 1, label: {
                        Text(viewStore.state.localizedTitle)
                    }, minimumValueLabel: {
                        Text(Quality.State.preview.localizedTitle)
                    }, maximumValueLabel: {
                        Text(Quality.State.raw.localizedTitle)
                    })
                    Spacer()
                }
                Spacer()
            }
        }

    }
}

extension Quality.State {
    var localizedTitle: String {
        switch self {
        case .preview:
            return "Preview"
        case .reduced:
            return "Reduced"
        case .medium:
            return "Medium"
        case .full:
            return "Full"
        case .raw:
            return "Raw"
        }
    }
}
