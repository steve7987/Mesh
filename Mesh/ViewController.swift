//
//  ViewController.swift
//  Mesh
//
//  Created by Stephen Russell on 10/27/17.
//  Copyright © 2017 Stephen Russell. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    var glView: OpenGLView!
    var testModel: Model!
    var tm2 : Model!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        NSLog("Creating GLView")
        let frame = UIScreen.main.bounds
        glView = OpenGLView(frame: frame)
        self.view.addSubview(glView)
        
        //setup game loop
        let displayLink : CADisplayLink = CADisplayLink(target: self, selector: #selector(ViewController.render(displayLink:)))
        displayLink.add(to: RunLoop.current, forMode: RunLoopMode(rawValue: RunLoopMode.defaultRunLoopMode.rawValue))
        
        
        //test stuff
        testModel = Model(x: 1, y: 0, z: -12)
        tm2 = Model(x: -1, y: 0, z: -8)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @objc func render(displayLink: CADisplayLink) -> Int {
        if (glView.beginFrame() != 0) {
            NSLog("ViewController: render(): glView.beginFrame failed")
            return -1
        }
        //call render functions for each object here
        glView.render(model: testModel)
        glView.render(model: tm2)
        
        if (glView.endFrame() != 0) {
            NSLog("ViewController: render(): glView.endFrame failed")
            return -1
        }
        return 0
    }
}

