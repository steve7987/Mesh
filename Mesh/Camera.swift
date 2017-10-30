//
//  Camera.swift
//  Mesh
//
//  Created by Stephen Russell on 10/30/17.
//  Copyright © 2017 Stephen Russell. All rights reserved.
//

import Foundation
import GLKit

class Camera: NSObject {
    var viewMatrix = GLKMatrix4()
    
    var xPosition: Float = 0
    var yPosition: Float = 0
    var zPosition: Float = 0
    
    var xLook: Float = 0
    var yLook: Float = 0
    var zLook: Float = 0
    
    init(x: Float, y: Float, z: Float, xl: Float, yl: Float ,zl: Float) {
        super.init()
        xPosition = x
        yPosition = y
        zPosition = z
        
        xLook = xl
        yLook = yl
        zLook = zl
        
        calculateViewMatrix()
    }
    
    func calculateViewMatrix(){
        viewMatrix = GLKMatrix4MakeLookAt(xPosition, yPosition, zPosition, xPosition + xLook, yPosition + yLook, zPosition + zLook, 0, 1, 0)
    }
    
    func setPosition(x: Float, y: Float, z: Float) {
        xPosition = x
        yPosition = y
        zPosition = z
        
        calculateViewMatrix()
    }
    
    func setLook(xl: Float, yl: Float, zl: Float) {
        xLook = xl
        yLook = yl
        zLook = zl
        
        calculateViewMatrix()
    }
}
