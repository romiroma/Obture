//
//  SessionConfigurator.swift
//  Obture
//
//  Created by Roman on 02.07.2022.
//

import AVFoundation
import Combine
import CoreMotion
import Project
import Node
import os

private let logger = Logger(subsystem: "com.andrykevych.Obture",
                            category: "SessionConfigurator/PhotoTaker")

protocol SessionConfigurator: AnyObject {
    var photoOutput: AVCapturePhotoOutput { get }
    func configure(_ session: AVCaptureSession, queue: DispatchQueue) -> Future<Void, CameraSession.Error>
    func start(_ session: AVCaptureSession, queue: DispatchQueue) -> Future<Void, CameraSession.Error>
    func stop(_ session: AVCaptureSession, queue: DispatchQueue) -> Future<Void, CameraSession.Error>
}

protocol PhotoTaker: AnyObject {
    var inProgressPhotoCaptureDelegates: [UUID: PhotoCaptureDelegate] { get set }
    func takePhoto(_ session: AVCaptureSession,
                   queue: DispatchQueue,
                   from photoOutput: AVCapturePhotoOutput,
                   motionManager: CMMotionManager) -> Future<CapturedPhoto, Swift.Error>
}
