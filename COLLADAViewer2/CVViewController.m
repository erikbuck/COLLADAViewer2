//
//  CVViewController.m
//  COLLADAViewer2
//
//  Created by Erik Buck on 9/30/12.
//  Copyright (c) 2012 Erik Buck. All rights reserved.
//

#import "CVViewController.h"
#import "CVView.h"
#import "AGLKBaseEffect.h"
#import "COLLADARoot+viewAdditions.h"

#undef __gl_h_
#import <GLKit/GLKit.h>


@interface CVViewController ()

@property (strong, nonatomic, readwrite)
   AGLKBaseEffect *baseEffect;

@end


@implementation CVViewController

/////////////////////////////////////////////////////////////////
// 
- (void)prepareOpenGL;
{
   [super prepareOpenGL];
   
   // Create a base effect that provides standard OpenGL ES 2.0
   // Shading Language programs and set constants to be used for 
   // all subsequent rendering
   self.baseEffect = [[AGLKBaseEffect alloc] init];
   
   //glEnable(GL_CULL_FACE);
   glEnable(GL_DEPTH_TEST);
   
   // Set the background color stored in the current context 
   glClearColor(0.0f, 0.3f, 0.0f, 1.0f); // background color
}


/////////////////////////////////////////////////////////////////
// 
- (void)aglkViewDidReshape:(AGLKView *)view;
{
   NSParameterAssert(nil != view);
   
   const GLfloat    width = [view bounds].size.width;
   const GLfloat    height = MAX(1.0f, [view bounds].size.height);
   
   // Tell OpenGL ES to draw into the full backing area
   glViewport(0, 0, width, height);

   // Calculate the aspect ratio for the scene and setup a 
   // perspective projection
   const GLfloat  aspectRatio = 
      width / height;
   
   self.baseEffect.transform.projectionMatrix =
      GLKMatrix4MakePerspective(GLKMathDegreesToRadians(35.0),
         aspectRatio, 0.5, 2048);
}


/////////////////////////////////////////////////////////////////
// This method is called automatically at the update rate of the 
// receiver (default 30 Hz). This method is implemented to
// update the physics simulation and remove any simulated objects
// that have fallen out of view.
- (void)update
{
   CVView *view = (id)self.view;
   
   self.baseEffect.transform.modelviewMatrix =
      [view makeLookAtMatrixWithArcBall];
   
   self.baseEffect.transform.modelviewMatrix =
      GLKMatrix4Multiply(self.baseEffect.transform.modelviewMatrix,
          [view makeRotateMatrixWithArcBall]);
   
}


/////////////////////////////////////////////////////////////////
//
- (void)drawSelectedRoots
{
   NSAssert(nil != self.selectionController,
      @"Missing required array controller for table selection.");
   
   [self.selectionController.selectionIndexes
      enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop)
   {
      COLLADARoot *root =
         [self.selectionController.arrangedObjects
            objectAtIndex:index];
      
      [root drawWithEffect:self.baseEffect];
   }];
}


/////////////////////////////////////////////////////////////////
// 
- (void)aglkView:(AGLKView *)view
   drawInRect:(NSRect)rect;
{
   // Clear Frame Buffer (erase previous drawing)
   glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT);
   
   // Configure a light
   self.baseEffect.light0.transform = self.baseEffect.transform;
   self.baseEffect.light0.position =
      GLKVector4Make(
         -0.6f,
         1.0f, 
         0.4f,
         0.0f); // Directional light
   self.baseEffect.light0.enabled = GL_TRUE;
   self.baseEffect.light0.diffuseColor =
      GLKVector4Make(
         1.0f, // Red 
         1.0f, // Green 
         1.0f, // Blue 
         1.0f);// Alpha
         
   [self drawSelectedRoots];
}

@end
