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
    
    var colorSlot = GLuint()  //vertex color for shader (should be in shader class)
    var positionSlot = GLuint() //vertex position for shader (should be in shader class)
    var worldMatrix = GLuint()  //connection to world matrix for shader (should be in shader class)
    var projectionUniform = GLuint() //connection to projection matrix for shader (should be in shader class)
    
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
        if (self.compileShaders() != 0) {
            NSLog("OpenGLView init():  compileShaders() failed")
            return
        }
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
    
    func compileShader(shaderName: String, shaderType: GLenum, shader: UnsafeMutablePointer<GLuint>) -> Int {
        let shaderPath = Bundle.main.path(forResource: shaderName, ofType:"glsl")
        var error : NSError?
        let shaderString: NSString?
        do {
            shaderString = try NSString(contentsOfFile: shaderPath!, encoding:String.Encoding.utf8.rawValue)
        } catch let error1 as NSError {
            error = error1
            shaderString = nil
        }
        if error != nil {
            NSLog("OpenGLView compileShader():  error loading shader: %@", error!.localizedDescription)
            return -1
        }
        
        shader.pointee = glCreateShader(shaderType)
        if (shader.pointee == 0) {
            NSLog("OpenGLView compileShader():  glCreateShader failed")
            return -1
        }
        var shaderStringUTF8 = shaderString!.utf8String
        var shaderStringLength: GLint = GLint(Int32(shaderString!.length))
        glShaderSource(shader.pointee, 1, &shaderStringUTF8, &shaderStringLength)
        
        glCompileShader(shader.pointee);
        var success = GLint()
        glGetShaderiv(shader.pointee, GLenum(GL_COMPILE_STATUS), &success)
        
        if (success == GL_FALSE) {
            let infoLog = UnsafeMutablePointer<GLchar>.allocate(capacity: 256)
            var infoLogLength = GLsizei()
            
            glGetShaderInfoLog(shader.pointee, GLsizei(MemoryLayout<GLchar>.size * 256), &infoLogLength, infoLog)
            NSLog("OpenGLView compileShader():  glCompileShader() failed:  %@", String(cString: infoLog))
            
            infoLog.deallocate(capacity: 256)
            return -1
        }
        
        return 0
    }
    
    func compileShaders() -> Int {
        let vertexShader = UnsafeMutablePointer<GLuint>.allocate(capacity: 1)
        if (self.compileShader(shaderName: "VS", shaderType: GLenum(GL_VERTEX_SHADER), shader: vertexShader) != 0 ) {
            NSLog("OpenGLView compileShaders():  compileShader() failed")
            return -1
        }
        
        let fragmentShader = UnsafeMutablePointer<GLuint>.allocate(capacity: 1)
        if (self.compileShader(shaderName: "FS", shaderType: GLenum(GL_FRAGMENT_SHADER), shader: fragmentShader) != 0) {
            NSLog("OpenGLView compileShaders():  compileShader() failed")
            return -1
        }
        
        let program = glCreateProgram()
        glAttachShader(program, vertexShader.pointee)
        glAttachShader(program, fragmentShader.pointee)
        glLinkProgram(program)
        
        var success = GLint()
        
        glGetProgramiv(program, GLenum(GL_LINK_STATUS), &success)
        if (success == GL_FALSE) {
            let infoLog = UnsafeMutablePointer<GLchar>.allocate(capacity: 1024)
            var infoLogLength = GLsizei()
            
            glGetProgramInfoLog(program, GLsizei(MemoryLayout<GLchar>.size * 1024), &infoLogLength, infoLog)
            NSLog("OpenGLView compileShaders():  glLinkProgram() failed:  %@", String(cString:  infoLog))
            
            infoLog.deallocate(capacity: 1024)
            fragmentShader.deallocate(capacity: 1)
            vertexShader.deallocate(capacity: 1)
            
            return -1
        }
        
        //stuff for setting shader parameters each time we want to use it
        glUseProgram(program)
        
        //connect variables with shader program
        positionSlot = GLuint(glGetAttribLocation(program, "Position"))
        colorSlot = GLuint(glGetAttribLocation(program, "SourceColor"))
        glEnableVertexAttribArray(positionSlot)
        glEnableVertexAttribArray(colorSlot)
        
        projectionUniform = GLuint(glGetUniformLocation(program, "Projection"))
        worldMatrix = GLuint(glGetUniformLocation(program, "World"))
        
        fragmentShader.deallocate(capacity: 1)
        vertexShader.deallocate(capacity: 1)
        return 0
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
    
    func render(model: Model) -> Int {
        
        var proj = projectionMatrix  //needed to avoid multiple access error
        //stack overflow code to convert proj matrix to pointer
        //send projection matrix to shader
        withUnsafePointer(to: &projectionMatrix.m) {
            $0.withMemoryRebound(to: GLfloat.self, capacity: MemoryLayout.size(ofValue: proj.m)) {
                glUniformMatrix4fv(GLint(projectionUniform), 1, 0, $0)
            }
        }
        var world = model.worldMatrix  //needed to avoid multiple access error
        //send world matrix to shader
        withUnsafePointer(to: &model.worldMatrix.m) {
            $0.withMemoryRebound(to: GLfloat.self, capacity: MemoryLayout.size(ofValue: world.m)) {
                glUniformMatrix4fv(GLint(worldMatrix), 1, 0, $0)
            }
        }
        
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), model.vertexBuffer)  //tells opengl to use this vertex buffer for rendering
        glBindBuffer(GLenum(GL_ELEMENT_ARRAY_BUFFER), model.indexBuffer)  //same but for index buffer
        
        //setup shaders for drawing for an object
        let positionSlotFirstComponent = UnsafePointer<Int>(bitPattern:0)
        glEnableVertexAttribArray(positionSlot)
        glVertexAttribPointer(positionSlot, 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(MemoryLayout<Vertex>.size), positionSlotFirstComponent)
        
        glEnableVertexAttribArray(colorSlot)
        let colorSlotFirstComponent = UnsafePointer<Int>(bitPattern:MemoryLayout<Float>.size * 3)
        glVertexAttribPointer(colorSlot, 4, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(MemoryLayout<Vertex>.size), colorSlotFirstComponent)
        
        
        
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
