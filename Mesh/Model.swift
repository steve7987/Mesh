//
//  Model.swift
//  Mesh
//
//  Created by Stephen Russell on 10/29/17.
//  Copyright © 2017 Stephen Russell. All rights reserved.
//

import Foundation
import GLKit

class Model: NSObject {
    var vertices = [
        Vertex(Position: ( 1, -1,  1), Color: (1, 1, 0, 1)),
        Vertex(Position: ( 1,  1,  1), Color: (0, 1, 1, 1)),
        Vertex(Position: (-1,  1,  1), Color: (1, 1, 0, 1)),
        Vertex(Position: (-1, -1,  1), Color: (1, 1, 0, 1)),
        Vertex(Position: ( 1, -1, -1), Color: (0, 1, 1, 1)),
        Vertex(Position: ( 1,  1, -1), Color: (1, 1, 0, 1)),
        Vertex(Position: (-1,  1, -1), Color: (1, 1, 0, 1)),
        Vertex(Position: (-1, -1, -1), Color: (0, 1, 1, 1))
    ]
    
    var indices : [GLubyte] = [
        // Front
        0, 1, 2,
        2, 3, 0,
        // Back
        4, 6, 5,
        4, 7, 6,
        // Left
        2, 7, 3,
        7, 6, 2,
        // Right
        0, 4, 1,
        4, 1, 5,
        // Top
        6, 2, 1,
        1, 6, 5,
        // Bottom
        0, 3, 7,
        0, 7, 4
    ]
    
    var worldMatrix = GLKMatrix4() //scaling, rotation and translation for model
    var vertexBuffer = GLuint()
    var indexBuffer = GLuint()
    
    init(x: Float, y: Float, z: Float) {
        super.init()
        //create world matrix
        worldMatrix = GLKMatrix4MakeTranslation(x, y, z)
        
        //create virtual buffer objects
        if (setupVBOs() != 0){
            NSLog("Model: init() setupVBOs failed")
        }
    }
    
    func setupVBOs() -> Int {
        glGenBuffers(1, &vertexBuffer)
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), vertexBuffer)
        glBufferData(GLenum(GL_ARRAY_BUFFER), (vertices.count * MemoryLayout<Vertex>.size), vertices, GLenum(GL_STATIC_DRAW))
        
        glGenBuffers(1, &indexBuffer)
        glBindBuffer(GLenum(GL_ELEMENT_ARRAY_BUFFER), indexBuffer)
        glBufferData(GLenum(GL_ELEMENT_ARRAY_BUFFER), (indices.count * MemoryLayout<GLubyte>.size), indices, GLenum(GL_STATIC_DRAW))
        return 0
    }
}
