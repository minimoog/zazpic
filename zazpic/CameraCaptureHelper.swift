//
//  CameraCaptureHelper.swift
//  CoreImageHelpers
//
//  Created by Simon Gladman on 09/01/2016.
//  Copyright © 2016 Simon Gladman. All rights reserved.
//

import AVFoundation
import CoreMedia
import CoreImage
import UIKit

/// `CameraCaptureHelper` wraps up all the code required to access an iOS device's
/// camera images and convert to a series of `CIImage` images.
///
/// The helper's delegate, `CameraCaptureHelperDelegate` receives notification of
/// a new image in the main thread via `newCameraImage()`.
class CameraCaptureHelper: NSObject {
    let captureSession = AVCaptureSession()
    let cameraPosition: AVCaptureDevicePosition
    
    weak var delegate: CameraCaptureHelperDelegate?
    
    required init(cameraPosition: AVCaptureDevicePosition) {
        self.cameraPosition = cameraPosition
        
        super.init()
        
        initialiseCaptureSession()
    }
    
    fileprivate func initialiseCaptureSession() {
        captureSession.sessionPreset = AVCaptureSessionPresetPhoto
        
        let discoverySession = AVCaptureDeviceDiscoverySession(deviceTypes: [.builtInWideAngleCamera, .builtInDualCamera], mediaType: AVMediaTypeVideo, position: cameraPosition)
        
        guard let camera = discoverySession?.devices.first else {
            fatalError("Unable to access camera")
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: camera)
            
            captureSession.addInput(input)
        }
        catch {
            fatalError("Unable to access back camera")
        }
        
        let videoOutput = AVCaptureVideoDataOutput()
        
        videoOutput.setSampleBufferDelegate(self,
            queue: DispatchQueue(label: "sample buffer delegate", attributes: []))
        
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }
        
        captureSession.startRunning()
    }
}

extension CameraCaptureHelper: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!)
    {
        connection.videoOrientation = AVCaptureVideoOrientation(rawValue: UIApplication.shared.statusBarOrientation.rawValue)!
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else
        {
            return
        }

        let copy = pixelBuffer.copy()
        
        DispatchQueue.main.async
        {
            self.delegate?.newCameraImage(self,
                image: CIImage(cvPixelBuffer: copy))
        }
        
    }
}

protocol CameraCaptureHelperDelegate: class
{
    func newCameraImage(_ cameraCaptureHelper: CameraCaptureHelper, image: CIImage)
}

extension CVPixelBuffer {
    func copy() -> CVPixelBuffer {
        precondition(CFGetTypeID(self) == CVPixelBufferGetTypeID(), "copy on nonCVPixelBuffer")
        
        var _copy: CVPixelBuffer?
        
        CVPixelBufferCreate(nil,
                            CVPixelBufferGetWidth(self),
                            CVPixelBufferGetHeight(self),
                            CVPixelBufferGetPixelFormatType(self),
                            CVBufferGetAttachments(self, .shouldPropagate),
                            &_copy)
        
        guard let copy = _copy else { fatalError() }
        
        CVPixelBufferLockBaseAddress(self, .readOnly)
        CVPixelBufferLockBaseAddress(copy, CVPixelBufferLockFlags(rawValue: 0))
        
        for plane in 0..<CVPixelBufferGetPlaneCount(self) {
            let dest = CVPixelBufferGetBaseAddressOfPlane(copy, plane)
            let source = CVPixelBufferGetBaseAddressOfPlane(self, plane)
            let height = CVPixelBufferGetHeightOfPlane(self, plane)
            let bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(self, plane)
            
            memcpy(dest, source, height * bytesPerRow)
        }
        
        CVPixelBufferUnlockBaseAddress(copy, CVPixelBufferLockFlags(rawValue: 0))
        CVPixelBufferUnlockBaseAddress(self, .readOnly)
        
        return copy
    }
}

