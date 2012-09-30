//
//  AGLKBaseEffect.m
//  SPEditor
//
//  Created by Erik Buck on 9/12/12.
//  Copyright (c) 2012 Erik Buck. All rights reserved.
//

#import "AGLKBaseEffect.h"

#undef __gl_h_
#import <GLKit/GLKit.h>

/////////////////////////////////////////////////////////////////
//
#define MAX_TEXTURES    2


/////////////////////////////////////////////////////////////////
// GLSL program uniform indices.
enum
{
   AGLKMVPMatrix,
   AGLKNormalMatrix,
   AGLKSamplers2D,
   AGLKLightModelAmbientColor,
   AGLKLight0Position,
   AGLKLight0DiffuseColor,
   AGLKNumUniforms
};


@interface AGLKBaseEffect ()
{
   GLint uniforms_[AGLKNumUniforms];
}

@end


@implementation AGLKBaseEffect

#pragma mark -  OpenGL shader compilation

/////////////////////////////////////////////////////////////////
//
- (void)bindAttribLocations;
{
   glBindAttribLocation(
      self.program, 
      AGLKVertexAttribPosition, 
      "a_position");
   glBindAttribLocation(
      self.program, 
      AGLKVertexAttribNormal, 
      "a_normal");
}


/////////////////////////////////////////////////////////////////
//
- (void)configureUniformLocations
{
   uniforms_[AGLKMVPMatrix] = glGetUniformLocation(
      self.program, 
      "u_mvpMatrix");
   uniforms_[AGLKNormalMatrix] = glGetUniformLocation(
      self.program, 
      "u_normalMatrix");
   uniforms_[AGLKSamplers2D] = glGetUniformLocation(
      self.program, 
      "u_units");
   uniforms_[AGLKLightModelAmbientColor] = glGetUniformLocation(
      self.program, 
      "u_lightModelAmbientColor");
   uniforms_[AGLKLight0Position] = glGetUniformLocation(
      self.program, 
      "u_light0Position");
   uniforms_[AGLKLight0DiffuseColor] = glGetUniformLocation(
      self.program, 
      "u_light0DiffuseColor");
}


#pragma mark -  Render Support

/////////////////////////////////////////////////////////////////
//
- (void)prepareOpenGL
{
   [self loadShadersWithName:@"AGLKBaseEffectShader"];
}


/////////////////////////////////////////////////////////////////
//
- (void)updateUniformValues
{
   [self prepareModelview];
      
   // Lighting
   glUniform4fv(uniforms_[AGLKLight0Position], 1,
      GLKVector4Normalize(self.light0.position).v);
   glUniform4fv(uniforms_[AGLKLight0DiffuseColor], 1,
      self.light0.diffuseColor.v);
   glUniform4fv(uniforms_[AGLKLightModelAmbientColor], 1,
      self.lightModelAmbientColor.v );
      
   // Textures
   GLuint units[MAX_TEXTURES];
   units[0] = self.texture2d0.name;
   units[1] = self.texture2d1.name;
   glUniform2uiv(uniforms_[AGLKSamplers2D], 1,
      units);
}


/////////////////////////////////////////////////////////////////
// This method exists as a minor optimization to update the 
// modelview matrix and normal matrix without updating any other
// uniform values used by the Shading Language program.
- (void)prepareModelview
{
   // Pre-calculate the mvpMatrix and normal matrix
   GLKMatrix4 modelViewProjectionMatrix = 
      GLKMatrix4Multiply(
         self.transform.projectionMatrix,
         self.transform.modelviewMatrix);         
   glUniformMatrix4fv(uniforms_[AGLKMVPMatrix], 1, 0,
      modelViewProjectionMatrix.m);

   GLKMatrix3 normalMatrix = self.transform.normalMatrix;
   glUniformMatrix3fv(uniforms_[AGLKNormalMatrix], 1,
      GL_FALSE, normalMatrix.m);
}

@end
