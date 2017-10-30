//
//  ColorShader.swift
//  Mesh
//
//  Created by Stephen Russell on 10/29/17.
//  Copyright © 2017 Stephen Russell. All rights reserved.
//

import Foundation
import GLKit

class ColorShader: NSObject {
    var colorSlot = GLuint()  //vertex color for shader (should be in shader class)
    var positionSlot = GLuint() //vertex position for shader (should be in shader class)
    var worldMatrix = GLuint()  //connection to world matrix for shader (should be in shader class)
    var projectionUniform = GLuint() //connection to projection matrix for shader (should be in shader class)
    
    let program = glCreateProgram()
    
    init(vs: String, fs: String) {
        super.init()
        
        //compile vertex shader
        let vertexShader = UnsafeMutablePointer<GLuint>.allocate(capacity: 1)
        if (self.compileShader(shaderName: vs, shaderType: GLenum(GL_VERTEX_SHADER), shader: vertexShader) != 0 ) {
            NSLog("ColorShader init():  compileShader() failed")
            return
        }
        //compile fragment shader
        let fragmentShader = UnsafeMutablePointer<GLuint>.allocate(capacity: 1)
        if (self.compileShader(shaderName: fs, shaderType: GLenum(GL_FRAGMENT_SHADER), shader: fragmentShader) != 0) {
            NSLog("ColorShader init():  compileShader() failed")
            return
        }
        
        
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
            
            return
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
    
    func setShaderParameters(model: Model, projectionMatrix: GLKMatrix4, viewMatrix: GLKMatrix4){
        glUseProgram(program)  //set this shader set as the one to use
        
        var proj = GLKMatrix4Multiply(projectionMatrix, viewMatrix)  //combine projection and view (camera) matrix
        //stack overflow code to convert proj matrix to pointer
        //send projection matrix to shader
        withUnsafePointer(to: &proj.m) {
            $0.withMemoryRebound(to: GLfloat.self, capacity: MemoryLayout.size(ofValue: proj.m)) {
                glUniformMatrix4fv(GLint(projectionUniform), 1, 0, $0)
            }
        }
        var world = model.worldMatrix  //needed to avoid multiple access error
        //send world matrix to shader
        withUnsafePointer(to: &world.m) {
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
    }
}
