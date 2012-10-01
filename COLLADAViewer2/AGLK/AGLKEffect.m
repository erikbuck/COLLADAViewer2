//
//  AGLKEffect.m
//  SPEditor
//
//  Created by Erik Buck on 9/11/12.
//  Copyright (c) 2012 Erik Buck. All rights reserved.
//

#import "AGLKEffect.h"

#undef __gl_h_
#import <GLKit/GLKit.h>


@interface AGLKEffect ()
{
}

- (BOOL)compileShader:(GLuint *)shader 
   type:(GLenum)type 
   file:(NSString *)file;
- (BOOL)linkProgram:(GLuint)prog;
- (BOOL)validateProgram:(GLuint)prog;

@end


@implementation AGLKEffect

@synthesize program = program_;
@synthesize transform = transform_;
@synthesize light0 = light0_;
@synthesize lightModelAmbientColor = lightModelAmbientColor_;
@synthesize texture2d0 = texture2d0_;
@synthesize texture2d1 = texture2d1_;
@synthesize texture2d0Transform = texture2d0Transform_;
@synthesize texture2d1Transform = texture2d1Transform_;


#pragma mark - Lifecycle

- (id)init
{
   self = [super init];
   if (self)
   {
      transform_ = [[GLKEffectPropertyTransform alloc] init];
      texture2d0Transform_ = GLKMatrix3Identity;
      texture2d1Transform_ = GLKMatrix3Identity;
      lightModelAmbientColor_ = GLKVector4Make(0.3, 0.3, 0.3, 1.0);
   }

   return self;
}


#pragma mark - Accessors

- (GLKEffectPropertyLight *)light0;
{
   if(nil == light0_)
   {
      light0_ = [[GLKEffectPropertyLight alloc] init];
   }
   
   return light0_;
}


- (GLKEffectPropertyTexture *)texture2d0;
{
   if(nil == texture2d0_)
   {
      texture2d0_ = [[GLKEffectPropertyTexture alloc] init];
   }
   
   return texture2d0_;
}


- (GLKEffectPropertyTexture *)texture2d1;
{
   if(nil == texture2d1_)
   {
      texture2d1_ = [[GLKEffectPropertyTexture alloc] init];
   }
   
   return texture2d1_;
}


#pragma mark - AGLKNamedEffect

/////////////////////////////////////////////////////////////////
// If the receiver's OpenGL ES 2.0 Shading Language programs have
// not been loaded, this method calls -prepareOpenGL. This method
// configures the OpenGL state to use the receiver's OpenGL ES 
// 2.0 Shading Language programs and then calls 
// -updateUniformValues to update any Shading Language program
// specific state required for drawing.
- (void)prepareToDraw;
{
   if(0 == self.program)
   {
      [self prepareOpenGL];
      
      NSAssert(0 != self.program,
         @"prepareOpenGL failed to load shaders");
   }
   
   glUseProgram(self.program);
   
   [self updateUniformValues];
}

#pragma mark - Subclasses should override

/////////////////////////////////////////////////////////////////
// Subclasses should override this implementation to load any
// OpenGL ES 2.0 Shading Language programs prior to drawing any 
// geometry with the receiver. The override should typically
// call [self loadShadersWithName:<baseName>] specifying the
// base name for the desired Shading Language programs.
- (void)prepareOpenGL
{
}


/////////////////////////////////////////////////////////////////
// Subclasses should override this implementation to configure 
// OpenGL uniform values prior to drawing any geometry with the
// receiver.
- (void)updateUniformValues
{
}


#pragma mark -  Required overloads

/////////////////////////////////////////////////////////////////
// Subclasses must override this implementation to bind any 
// OpenGL ES 2.0 Shading Language program attributes.
- (void)bindAttribLocations;
{
   NSAssert(0, 
      @"Subclasses failed to override this implementation");
}


/////////////////////////////////////////////////////////////////
// Subclasses must override this implementation to bind any 
// OpenGL ES 2.0 Shading Language program uniform locations.
- (void)configureUniformLocations;
{
   NSAssert(0, 
      @"Subclasses failed to override this implementation");
}


#pragma mark -  OpenGL shader compilation

/////////////////////////////////////////////////////////////////
// This method loads and compiles OpenGL ES 2.0 Shading Language 
// programs with the root name aShaderName and the 
// suffixes/extensions "vsh" and "fsh".
- (BOOL)loadShadersWithName:(NSString *)aShaderName;
{
   NSParameterAssert(nil != aShaderName);
   
   GLuint vertShader, fragShader;
   NSString *vertShaderPathname, *fragShaderPathname;
   
   if (self.program) 
   {
      glDeleteProgram(self.program);
      program_ = 0;
   }
   
   // Create shader program.
   program_ = glCreateProgram();
   
   // Create and compile vertex shader.
   vertShaderPathname = [[NSBundle mainBundle] 
      pathForResource:aShaderName ofType:@"vsh"];
   if (![self compileShader:&vertShader type:GL_VERTEX_SHADER 
      file:vertShaderPathname]) 
   {
      NSLog(@"Failed to compile vertex shader");
      return NO;
   }
   
   // Create and compile fragment shader.
   fragShaderPathname = [[NSBundle mainBundle] 
      pathForResource:aShaderName ofType:@"fsh"];
   if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER 
      file:fragShaderPathname]) 
   {
      NSLog(@"Failed to compile fragment shader");
      return NO;
   }
   
   // Attach vertex shader to program.
   glAttachShader(self.program, vertShader);
   
   // Attach fragment shader to program.
   glAttachShader(self.program, fragShader);
   
   // Bind attribute locations.
   // This needs to be done prior to linking.
   [self bindAttribLocations];
   
   // Link program.
   if (![self linkProgram:self.program]) 
   {
      NSLog(@"Failed to link program: %d", self.program);
      
      if (vertShader) 
      {
         glDeleteShader(vertShader);
         vertShader = 0;
      }
      if (fragShader) 
      {
         glDeleteShader(fragShader);
         fragShader = 0;
      }
      if (self.program) 
      {
         glDeleteProgram(self.program);
         program_ = 0;
      }
      
      return NO;
   }

   // Get uniform locations.
   [self configureUniformLocations];
   
   // Delete vertex and fragment shaders.
   if (vertShader) 
   {
      glDetachShader(self.program, vertShader);
      glDeleteShader(vertShader);
   }
   if (fragShader) 
   {
      glDetachShader(self.program, fragShader);
      glDeleteShader(fragShader);
   }
   
   return YES;
}


/////////////////////////////////////////////////////////////////
// 
- (BOOL)compileShader:(GLuint *)shader 
   type:(GLenum)type 
   file:(NSString *)file
{
   GLint status;
   const GLchar *source;
   
   source = (GLchar *)[[NSString stringWithContentsOfFile:file 
      encoding:NSUTF8StringEncoding error:nil] UTF8String];
   if (!source) 
   {
      NSLog(@"Failed to load vertex shader");
      return NO;
   }
   
   *shader = glCreateShader(type);
   glShaderSource(*shader, 1, &source, NULL);
   glCompileShader(*shader);
   
#if defined(DEBUG)
   GLint logLength;
   glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
   if (logLength > 0) 
   {
      GLchar *log = (GLchar *)malloc(logLength);
      glGetShaderInfoLog(*shader, logLength, &logLength, log);
      NSLog(@"Shader compile log:\n%s", log);
      free(log);
   }
#endif
   
   glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
   if (status == 0) 
   {
      glDeleteShader(*shader);
      return NO;
   }
   
   return YES;
}


/////////////////////////////////////////////////////////////////
// 
- (BOOL)linkProgram:(GLuint)prog
{
   GLint status;
   glLinkProgram(prog);
   
#if defined(DEBUG)
   GLint logLength;
   glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
   if (logLength > 0) 
   {
      GLchar *log = (GLchar *)malloc(logLength);
      glGetProgramInfoLog(prog, logLength, &logLength, log);
      NSLog(@"Program link log:\n%s", log);
      free(log);
   }
#endif
   
   glGetProgramiv(prog, GL_LINK_STATUS, &status);
   if (status == 0) 
   {
      return NO;
   }
   
   return YES;
}


/////////////////////////////////////////////////////////////////
// 
- (BOOL)validateProgram:(GLuint)prog
{
   GLint logLength, status;
   
   glValidateProgram(prog);
   glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
   if (logLength > 0) 
   {
      GLchar *log = (GLchar *)malloc(logLength);
      glGetProgramInfoLog(prog, logLength, &logLength, log);
      NSLog(@"Program validate log:\n%s", log);
      free(log);
   }
   
   glGetProgramiv(prog, GL_VALIDATE_STATUS, &status);
   if (status == 0) 
   {
      return NO;
   }
   
   return YES;
}

@end
