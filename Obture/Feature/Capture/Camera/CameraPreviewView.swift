//
//  CameraPreviewView.swift
//  Obture
//
//  Created by Roman on 02.07.2022.
//

import AVFoundation
import SwiftUI
import UIKit
import os

struct CameraPreviewView: UIViewRepresentable {

    class PreviewView: UIView {

        var videoPreviewLayer: AVCaptureVideoPreviewLayer {
            guard let layer = layer as? AVCaptureVideoPreviewLayer else {
                fatalError("Expected `AVCaptureVideoPreviewLayer` type for layer. Check PreviewView.layerClass implementation.")
            }
            return layer
        }

        var session: AVCaptureSession? {
            get {
                return videoPreviewLayer.session
            }
            set {
                videoPreviewLayer.session = newValue
            }
        }

        override class var layerClass: AnyClass {
            return AVCaptureVideoPreviewLayer.self
        }
    }

    let session: AVCaptureSession

    init(session: AVCaptureSession) {
        self.session = session
    }

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.videoPreviewLayer.session = session

        // Set the view's initial state.
        view.backgroundColor = .black
        view.videoPreviewLayer.cornerRadius = 0
        view.videoPreviewLayer.videoGravity = .resizeAspect
        view.videoPreviewLayer.connection?.videoOrientation = .portrait

        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {  }
}
