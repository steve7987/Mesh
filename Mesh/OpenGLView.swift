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
    
    var colorSlot = GLuint()  //vertex color for shader (should be in shader class)
    var positionSlot = GLuint() //vertex position for shader (should be in shader class)
    var worldMatrix = GLuint()  //scaling, rotation and translation for shader (should be in shader class)
    var projectionUniform = GLuint() //projection matrix
    
    var vertices = [
        Vertex(Position: ( 1, -1,  1), Color: (1, 0, 0, 1)),
        Vertex(Position: ( 1,  1,  1), Color: (0, 1, 0, 1)),
        Vertex(Position: (-1,  1,  1), Color: (0, 0, 1, 1)),
        Vertex(Position: (-1, -1,  1), Color: (1, 0, 0, 1)),
        Vertex(Position: ( 1, -1, -1), Color: (0, 1, 0, 1)),
        Vertex(Position: ( 1,  1, -1), Color: (0, 0, 1, 1)),
        Vertex(Position: (-1,  1, -1), Color: (1, 0, 0, 1)),
        Vertex(Position: (-1, -1, -1), Color: (0, 1, 0, 1))
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
        //should be part of model class
        if (self.setupVBOs() != 0) {
            NSLog("OpenGLView init():  setupVBOs() failed")
            return
        }
        
        if (self.setupDisplayLink() != 0) {
            NSLog("OpenGLView init():  setupDisplayLink() failed")
        }
        NSLog("setup done")
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
    
    @objc func render(displayLink: CADisplayLink) -> Int {
        //called to begin drawing
        glClearColor(0, 104.0/255.0, 55.0/255.0, 1.0)
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT))  //clear depth and color buffer
        glEnable(GLenum(GL_DEPTH_TEST))  //enable depth testing (maybe not call every frame??)
        
        //calculate projection matrix
        let asp : Float = Float(self.frame.size.width) / Float(self.frame.size.height)
        var proj = GLKMatrix4MakePerspective(1.39, asp, 1.0, 1000.0)  //fov is 1.39 rad == 70 deg
        
        //stack overflow code to convert proj matrix to pointer
        //send projection matrix to shader
        withUnsafePointer(to: &proj.m) {
            $0.withMemoryRebound(to: GLfloat.self, capacity: MemoryLayout.size(ofValue: proj.m)) {
                glUniformMatrix4fv(GLint(projectionUniform), 1, 0, $0)
            }
        }
        
        //calculate world matrix (should be done in model class)
        var world = GLKMatrix4Multiply(GLKMatrix4MakeTranslation(Float(sin(CACurrentMediaTime())), 0, -7), GLKMatrix4MakeRotation(Float(3.14 * cos(CACurrentMediaTime())), 1, 1, 0))
        
        //send world matrix to shader
        withUnsafePointer(to: &world.m) {
            $0.withMemoryRebound(to: GLfloat.self, capacity: MemoryLayout.size(ofValue: world.m)) {
                glUniformMatrix4fv(GLint(worldMatrix), 1, 0, $0)
            }
        }
        
        glViewport(0, 0, GLsizei(self.frame.size.width), GLsizei(self.frame.size.height))
        
        //setup drawing for an object
        let positionSlotFirstComponent = UnsafePointer<Int>(bitPattern:0)
        glEnableVertexAttribArray(positionSlot)
        glVertexAttribPointer(positionSlot, 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(MemoryLayout<Vertex>.size), positionSlotFirstComponent)
        
        glEnableVertexAttribArray(colorSlot)
        let colorSlotFirstComponent = UnsafePointer<Int>(bitPattern:MemoryLayout<Float>.size * 3)
        glVertexAttribPointer(colorSlot, 4, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(MemoryLayout<Vertex>.size), colorSlotFirstComponent)

        let vertexBufferOffset = UnsafeMutableRawPointer(bitPattern: 0)
        glDrawElements(GLenum(GL_TRIANGLES), GLsizei((indices.count * MemoryLayout<GLubyte>.size)/MemoryLayout<GLubyte>.size),
                       GLenum(GL_UNSIGNED_BYTE), vertexBufferOffset)
        
        //called to finish rendering
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
    
    
    func setupDisplayLink() -> Int {
        let displayLink : CADisplayLink = CADisplayLink(target: self, selector: #selector(OpenGLView.render(displayLink:)))
        displayLink.add(to: RunLoop.current, forMode: RunLoopMode(rawValue: RunLoopMode.defaultRunLoopMode.rawValue))
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
    
    //should be part of model class
    func setupVBOs() -> Int {
        var vertexBuffer = GLuint()
        glGenBuffers(1, &vertexBuffer)
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), vertexBuffer)
        glBufferData(GLenum(GL_ARRAY_BUFFER), (vertices.count * MemoryLayout<Vertex>.size), vertices, GLenum(GL_STATIC_DRAW))
        
        var indexBuffer = GLuint()
        glGenBuffers(1, &indexBuffer)
        glBindBuffer(GLenum(GL_ELEMENT_ARRAY_BUFFER), indexBuffer)
        glBufferData(GLenum(GL_ELEMENT_ARRAY_BUFFER), (indices.count * MemoryLayout<GLubyte>.size), indices, GLenum(GL_STATIC_DRAW))
        return 0
    }
}
