//
//  OpenGLView.swift
//  Mesh
//
//  Created by Stephen Russell on 10/27/17.
//  Copyright © 2017 Stephen Russell. All rights reserved.
//

import Foundation
import UIKit
import QuartzCore
import OpenGLES
import GLKit

struct Vertex {
    var Position: (Float, Float, Float)
    var Color: (Float, Float, Float, Float)
}

class OpenGLView: UIView {
    var context: EAGLContext?
    var eaglLayer: CAEAGLLayer?
    
    var depthRenderBuffer = GLuint()
    var colorRenderBuffer = GLuint()
    
    var projectionMatrix = GLKMatrix4()  //projection matrix for going from world to screen
 
    var colorShader: ColorShader!  //object containing the color shader info
    var shaderTest: ColorShader!  //for testing
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        if (self.setupLayer() != 0) {
            NSLog("OpenGLView init():  setupLayer() failed")
            return
        }
        if (self.setupContext() != 0) {
            NSLog("OpenGLView init():  setupContext() failed")
            return
        }
        if (self.setupDepthBuffer() != 0) {
            NSLog("OpenGLView init():  setupDepthBuffer() failed")
            return
        }
        if (self.setupRenderBuffer() != 0) {
            NSLog("OpenGLView init():  setupRenderBuffer() failed")
            return
        }
        if (self.setupFrameBuffer() != 0) {
            NSLog("OpenGLView init():  setupFrameBuffer() failed")
            return
        }
        //create shaders
        colorShader = ColorShader.init(vs: "VS", fs: "FS")
        shaderTest = ColorShader.init(vs: "VSTest", fs: "FS")
        NSLog("OpenGLView setup done")
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("OpenGLView init(coder:) has not been implemented")
    }
    
    override class var layerClass: AnyClass {
        get {
            return CAEAGLLayer.self
        }
    }
 
    func beginFrame() -> Int {
        glClearColor(0, 104.0/255.0, 55.0/255.0, 1.0)
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT))  //clear depth and color buffer
        glEnable(GLenum(GL_DEPTH_TEST))  //enable depth testing (maybe not call every frame??)
        glViewport(0, 0, GLsizei(self.frame.size.width), GLsizei(self.frame.size.height))  //say where we want to draw on the screen
        
        //calculate projection matrix for this frame
        let asp : Float = Float(self.frame.size.width) / Float(self.frame.size.height)
        projectionMatrix = GLKMatrix4MakePerspective(1.39, asp, 1.0, 1000.0)  //fov is 1.39 rad == 70 deg
        
        //calculate view matrix as well
        
        return 0
    }
    
    func render(model: Model, camera: Camera, shaderType: Int) -> Int {
        if (shaderType == 1) {
            shaderTest.setShaderParameters(model: model, projectionMatrix: projectionMatrix, viewMatrix: camera.viewMatrix)
        }
        else {
            colorShader.setShaderParameters(model: model, projectionMatrix: projectionMatrix, viewMatrix: camera.viewMatrix)
        }
        let vertexBufferOffset = UnsafeMutableRawPointer(bitPattern: 0)
        glDrawElements(GLenum(GL_TRIANGLES), GLsizei((model.indices.count * MemoryLayout<GLubyte>.size)/MemoryLayout<GLubyte>.size),
                       GLenum(GL_UNSIGNED_BYTE), vertexBufferOffset)
        
        return 0
    }
 
    
    func endFrame() -> Int {
        context!.presentRenderbuffer(Int(GL_RENDERBUFFER))
        return 0
    }

    func setupContext() -> Int {
        let api : EAGLRenderingAPI = EAGLRenderingAPI.openGLES3
        context = EAGLContext(api: api)
        
        if (context == nil) {
            NSLog("Failed to initialize OpenGLES 2.0 context")
            return -1
        }
        if (!EAGLContext.setCurrent(context)) {
            NSLog("Failed to set current OpenGL context")
            return -1
        }
        return 0
    }
    
    func setupFrameBuffer() -> Int {
        var framebuffer: GLuint = 0
        glGenFramebuffers(1, &framebuffer)
        glBindFramebuffer(GLenum(GL_FRAMEBUFFER), framebuffer)
        glFramebufferRenderbuffer(GLenum(GL_FRAMEBUFFER), GLenum(GL_COLOR_ATTACHMENT0), GLenum(GL_RENDERBUFFER), colorRenderBuffer)
        glFramebufferRenderbuffer(GLenum(GL_FRAMEBUFFER), GLenum(GL_DEPTH_ATTACHMENT), GLenum(GL_RENDERBUFFER), depthRenderBuffer);
        return 0
    }
    
    func setupLayer() -> Int {
        eaglLayer = self.layer as? CAEAGLLayer
        if (eaglLayer == nil) {
            NSLog("setupLayer:  _eaglLayer is nil")
            return -1
        }
        eaglLayer!.isOpaque = true
        return 0
    }
    
    func setupRenderBuffer() -> Int {
        glGenRenderbuffers(1, &colorRenderBuffer)
        glBindRenderbuffer(GLenum(GL_RENDERBUFFER), colorRenderBuffer)
        
        if (context == nil) {
            NSLog("setupRenderBuffer():  _context is nil")
            return -1
        }
        if (eaglLayer == nil) {
            NSLog("setupRenderBuffer():  _eagLayer is nil")
            return -1
        }
        if (context!.renderbufferStorage(Int(GL_RENDERBUFFER), from: eaglLayer!) == false) {
            NSLog("setupRenderBuffer():  renderbufferStorage() failed")
            return -1
        }
        return 0
    }
    
    func setupDepthBuffer() -> Int {
        glGenRenderbuffers(1, &depthRenderBuffer);
        glBindRenderbuffer(GLenum(GL_RENDERBUFFER), depthRenderBuffer);
        glRenderbufferStorage(GLenum(GL_RENDERBUFFER), GLenum(GL_DEPTH_COMPONENT16), GLsizei(self.frame.size.width), GLsizei(self.frame.size.height))
        return 0
    }
}
