//
//  CaptureButton.swift
//  Obture
//
//  Created by Roman on 04.07.2022.
//

import SwiftUI
import ComposableArchitecture

/// This capture button view is modeled after the Camera app button. The view changes shape when the
/// user starts shooting in automatic mode.
struct CaptureButton: View {

    let store: Store<Capture.State, Capture.Action>

    static let outerDiameter: CGFloat = 80
    static let strokeWidth: CGFloat = 4
    static let innerPadding: CGFloat = 10
    static let innerDiameter: CGFloat = CaptureButton.outerDiameter -
    CaptureButton.strokeWidth - CaptureButton.innerPadding
    static let rootTwoOverTwo: CGFloat = CGFloat(2.0.squareRoot() / 2.0)
    static let squareDiameter: CGFloat = CaptureButton.innerDiameter * CaptureButton.rootTwoOverTwo -
    CaptureButton.innerPadding



    var body: some View {
        WithViewStore(store) { viewStore in
            Button(action: {
                viewStore.send(.takePhoto)
            }, label: {
                ZStack {
                    ManualCaptureButtonView().frame(alignment: .center)
                    Text(viewStore.buttonTitle)
                }
            })//.disabled(!model.isCameraAvailable || !model.readyToCapture)
        }
    }
}

/// This is a helper view for the `CaptureButton`. It implements the shape for automatic capture mode.
//struct AutoCaptureButtonView: View {
//    @ObservedObject var model: CameraViewModel
//
//    var body: some View {
//        ZStack {
//            Rectangle()
//                .foregroundColor(Color.red)
//                .frame(width: CaptureButton.squareDiameter,
//                       height: CaptureButton.squareDiameter,
//                       alignment: .center)
//                .cornerRadius(5)
//            TimerView(model: model, diameter: CaptureButton.outerDiameter)
//        }
//    }
//}

/// This is a helper view for the `CaptureButton`. It implements the shape for manual capture mode.
struct ManualCaptureButtonView: View {

    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(Color.white, lineWidth: CaptureButton.strokeWidth)
                .frame(width: CaptureButton.outerDiameter,
                       height: CaptureButton.outerDiameter,
                       alignment: .center)
            Circle()
                .foregroundColor(Color.white)
                .frame(width: CaptureButton.innerDiameter,
                       height: CaptureButton.innerDiameter,
                       alignment: .center)
        }
    }
}
