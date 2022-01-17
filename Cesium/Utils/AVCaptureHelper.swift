//
//  AVCaptureHelper.swift
//  try-camera-output-as-background
//
//  Created by Rudolf Farkas on 12.01.22.
//

// adapted from https://coderedirect.com/questions/534341/set-up-camera-on-the-background-of-uiview

import AVFoundation
import UIKit

// AVCaptureVideoDataOutputSampleBufferDelegate protocol and related methods
class AVCaptureHelper: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    // Camera Capture required properties
    var videoDataOutput: AVCaptureVideoDataOutput!
    var videoDataOutputQueue: DispatchQueue!
    var previewLayer: AVCaptureVideoPreviewLayer!
    var captureDevice: AVCaptureDevice!
    let session = AVCaptureSession()
    var currentFrame: CIImage!
    var done = false
    
    var parentView: UIView!
    
    /// Start video capture and display it in the parent view as background
    /// - Parameter view: parent view
    func setupAVCaptureAndDisplay(in parentView: UIView) {
        self.parentView = parentView

        session.sessionPreset = AVCaptureSession.Preset.vga640x480
        guard let device = AVCaptureDevice
            .default(AVCaptureDevice.DeviceType.builtInWideAngleCamera,
                     for: .video,
                     position: AVCaptureDevice.Position.back)
        else {
            return
        }
        captureDevice = device
        beginSession()
        done = true
    }

    func beginSession() {
        var deviceInput: AVCaptureDeviceInput!
        do {
            deviceInput = try AVCaptureDeviceInput(device: captureDevice)
            guard deviceInput != nil else {
                print("error: cant get deviceInput")
                return
            }

            if session.canAddInput(deviceInput) {
                session.addInput(deviceInput)
            }

            videoDataOutput = AVCaptureVideoDataOutput()
            videoDataOutput.alwaysDiscardsLateVideoFrames = true
            videoDataOutputQueue = DispatchQueue(label: "VideoDataOutputQueue")
            videoDataOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)

            if session.canAddOutput(videoDataOutput) {
                session.addOutput(videoDataOutput)
            }

            videoDataOutput.connection(with: AVMediaType.video)?.isEnabled = true

            previewLayer = AVCaptureVideoPreviewLayer(session: session)
            previewLayer.frame = parentView.layer.bounds
            previewLayer.videoGravity = .resizeAspectFill
            parentView.layer.insertSublayer(previewLayer, at: 0)

            session.startRunning()
        } catch let error as NSError {
            deviceInput = nil
            print("error: \(error.localizedDescription)")
        }
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        currentFrame = convertImageFromCMSampleBufferRef(sampleBuffer)
    }

    // clean up AVCapture
    func stopCamera() {
        session.stopRunning()
        done = false
    }

    func convertImageFromCMSampleBufferRef(_ sampleBuffer: CMSampleBuffer) -> CIImage {
        let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
        let ciImage = CIImage(cvImageBuffer: pixelBuffer)
        return ciImage
    }
}
