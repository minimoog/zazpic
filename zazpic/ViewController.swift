//
//  ViewController.swift
//  zazpic
//
//  Created by Toni Jovanoski on 4/6/17.
//  Copyright © 2017 Antonie Jovanoski. All rights reserved.
//

import UIKit

class ViewController: UIViewController, CameraCaptureHelperDelegate {

    let imageView = MetalImageView()
    let cameraCaptureHelper = CameraCaptureHelper(cameraPosition: .front)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        view.addSubview(imageView)
        
        cameraCaptureHelper.delegate = self
    }

    override func viewDidLayoutSubviews() {
        imageView.frame = view.bounds.insetBy(dx: 5, dy: 5)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func newCameraImage(_ cameraCaptureHelper: CameraCaptureHelper, image: CIImage) {
        imageView.image = image
    }
}

