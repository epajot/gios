//
//  ViewController.swift
//  try-camera-output-as-background
//
//  Created by Rudolf Farkas on 10.01.22.
//

// from https://coderedirect.com/questions/534341/set-up-camera-on-the-background-of-uiview

import AVFoundation
import UIKit

class ViewController: UIViewController {
    var previewView: UIView!
    var boxView: UIView!
    var backgroundImageView: UIImageView!
    
    var profile: Profile?

    // Camera Capture requiered properties
    var videoDataOutput: AVCaptureVideoDataOutput!
    var videoDataOutputQueue: DispatchQueue!
    var previewLayer: AVCaptureVideoPreviewLayer!
    var captureDevice: AVCaptureDevice!
    let session = AVCaptureSession()
    var currentFrame: CIImage!
    var done = false
    
    weak var profileSelectedDelegate: ReceiverChangedDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        printClassAndFunc("@")

        previewView = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height))
        previewView.contentMode = .scaleAspectFit
        view.addSubview(previewView)

        // Add a box view
        boxView = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 200))
        boxView.backgroundColor = UIColor.green
        boxView.alpha = 0.3
        view.addSubview(boxView)
        
        // Add a background view
//        backgroundImageView.image = UIImage(named: "SHARE_background_11_Pro Blue")
//        backgroundImageView.backgroundColor = .clear
//        backgroundImageView.alpha = 0.5
//        backgroundImageView.clipsToBounds = view.superview.

        setupAVCapture()
        
        
    }

    override func viewWillAppear(_: Bool) {
        if !done {
            session.startRunning()
        }
    }

    override func viewDidAppear(_: Bool) {
        presentSecondViewController(identifier: "ChangeUserView")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override var shouldAutorotate: Bool {
        if UIDevice.current.orientation == UIDeviceOrientation.landscapeLeft ||
            UIDevice.current.orientation == UIDeviceOrientation.landscapeRight ||
            UIDevice.current.orientation == UIDeviceOrientation.unknown
        {
            return false
        } else {
            return true
        }
    }
}

// AVCaptureVideoDataOutputSampleBufferDelegate protocol and related methods
extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func setupAVCapture() {
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
            previewLayer.frame = view.layer.bounds
            previewLayer.videoGravity = .resizeAspectFill
            view.layer.addSublayer(previewLayer)

            view.bringSubviewToFront(boxView)

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

extension ViewController {
    func presentSecondViewController(identifier: String) {
        printClassAndFunc("@")

        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let secondVC = storyboard.instantiateViewController(identifier: identifier)

        // show(secondVC, sender: self)
        present(secondVC, animated: true)
    }
}
