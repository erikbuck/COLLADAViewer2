//
//  CVView.m
//  COLLADAViewer2
//
//  Created by Erik Buck on 9/30/12.
//  Copyright (c) 2012 Erik Buck. All rights reserved.
//

#import "CVView.h"
#import <GLKit/GLKQuaternion.h>


@interface CVView ()

@property (assign, nonatomic)
	CGPoint iniLocation;
@property (assign, nonatomic)
	GLKQuaternion quarternion;
@property (assign, nonatomic)
	float distance;

@end


@implementation CVView

#define RADIANS_PER_PIXEL (M_PI / 620.f)
 
/////////////////////////////////////////////////////////////////
// 
- (void)prepareOpenGL;
{
   [super prepareOpenGL];

	self.quarternion = GLKQuaternionMake(0.f, 0.f, 0.f, 1.f);
	self.iniLocation = CGPointMake(0.f, 0.f);
   self.distance = 10.0;
}


#pragma mark - Arc Ball

/////////////////////////////////////////////////////////////////
// 
- (GLKMatrix4)makeLookAtMatrixWithArcBall
{
   return GLKMatrix4MakeLookAt(
      self.distance, self.distance, self.distance,
      0, 0, 0,
      0, 1, 0);
}


/////////////////////////////////////////////////////////////////
// 
- (GLKMatrix4)makeRotateMatrixWithArcBall
{
   GLKMatrix4 result = GLKMatrix4Identity;
   
	GLKVector3 axis = GLKQuaternionAxis(self.quarternion);
	float angle = GLKQuaternionAngle(self.quarternion);
	if( fabs(angle) > 0.0000001f )
   {
		result = GLKMatrix4Rotate(result, angle, axis.x, axis.y, axis.z);
   }
   
   return result;
}


/////////////////////////////////////////////////////////////////
// 
- (void)rotateQuaternionWithVector:(CGPoint)delta
{
	GLKVector3 up = GLKVector3Make(0.0f, 1.0f, 0.0f);
	GLKVector3 right = GLKVector3Make(1.0f, 0.0f, 0.0f);
 
	up = GLKQuaternionRotateVector3( GLKQuaternionInvert(self.quarternion), up );
	self.quarternion =
      GLKQuaternionMultiply(self.quarternion,
         GLKQuaternionMakeWithAngleAndVector3Axis(
            delta.x * RADIANS_PER_PIXEL, up));
 
	right = GLKQuaternionRotateVector3(
      GLKQuaternionInvert(self.quarternion), right );
   
	self.quarternion = GLKQuaternionMultiply(
      self.quarternion, GLKQuaternionMakeWithAngleAndVector3Axis(
         delta.y * RADIANS_PER_PIXEL, right));
}


#pragma mark - Event Handling

/////////////////////////////////////////////////////////////////
// 
- (BOOL)canBecomeFirstResponder
{
    return YES;
}


/////////////////////////////////////////////////////////////////
// 
- (void)mouseDown:(NSEvent *)theEvent
{
	CGPoint location =
      [self convertPoint:[theEvent locationInWindow] fromView:nil];
 
	self.iniLocation = location;
   
   [self.window makeFirstResponder:self];
}


/////////////////////////////////////////////////////////////////
// 
- (void)mouseDragged:(NSEvent *)theEvent
{
	CGPoint location =
      [self convertPoint:[theEvent locationInWindow] fromView:nil];
 
	// get touch delta
	CGPoint delta =
      CGPointMake(location.x - self.iniLocation.x,
         -(location.y - self.iniLocation.y));
	self.iniLocation = location;
 
	// rotate
	[self rotateQuaternionWithVector:delta];
}


/////////////////////////////////////////////////////////////////
//
- (void)scrollWheel:(NSEvent *)theEvent
{
   float  deltaY = [theEvent deltaY];
   
   if(0 < deltaY)
   {
      [self moveDown:theEvent];
   }
   else
   {
      [self moveUp:theEvent];
   }
}


/////////////////////////////////////////////////////////////////
// 
- (void)keyDown:(NSEvent *)theEvent
{
   // Arrow keys are associated with the numeric keypad
   if ([theEvent modifierFlags] & NSNumericPadKeyMask)
   {
     [self interpretKeyEvents:[NSArray arrayWithObject:theEvent]];
   }
   else
   {
      NSString *characters = [theEvent characters];
      BOOL didHandleInput = NO;
      
      for(int i = 0 ; i < characters.length; i++)
      {
         unichar character = [characters characterAtIndex:i];
         
         if(character == [@"a" characterAtIndex:0])
         {
            [self moveLeft:nil];
            didHandleInput = YES;
         }
         else if(character == [@"d" characterAtIndex:0])
         {
            [self moveRight:nil];
            didHandleInput = YES;
         }
         else if(character == [@"w" characterAtIndex:0])
         {
            [self moveUp:nil];
            didHandleInput = YES;
         }
         else if(character == [@"s" characterAtIndex:0])
         {
            [self moveDown:nil];
            didHandleInput = YES;
         }
         else if(character == [@"-" characterAtIndex:0])
         {
            [self moveUp:nil];
            didHandleInput = YES;
         }
         else if(character == [@"+" characterAtIndex:0])
         {
            [self moveDown:theEvent];
            didHandleInput = YES;
         }
      }
   
      if(!didHandleInput)
      {
         [super keyDown:theEvent];
      }
   }
}

 
/////////////////////////////////////////////////////////////////
// 
-(IBAction)moveUp:(id)sender
{
   if([self.delegate respondsToSelector:@selector(moveUp:)])
   {
      [self.delegate moveUp:sender];
   }
   else
   {
      if(self.distance > 1.0)
      {
         self.distance *= 0.9f;
      }
      
      [[self window] invalidateCursorRectsForView:self];      
   }
}


/////////////////////////////////////////////////////////////////
// 
-(IBAction)moveDown:(id)sender
{
   if([self.delegate respondsToSelector:@selector(moveDown:)])
   {
      [self.delegate moveDown:sender];
   }
   else
   {
      self.distance *= 1.1f;
      
      [[self window] invalidateCursorRectsForView:self];      
   }
}


/////////////////////////////////////////////////////////////////
// 
const float CVKeyboardBasedRotationDelta = (10.0f);

/////////////////////////////////////////////////////////////////
// 
-(IBAction)moveLeft:(id)sender
{
   if([self.delegate respondsToSelector:@selector(moveLeft:)])
   {
      [self.delegate moveLeft:sender];
   }
   else
   {
   	[self rotateQuaternionWithVector:CGPointMake(
         -CVKeyboardBasedRotationDelta,
         0.0f)];
      [[self window] invalidateCursorRectsForView:self];      
   }
}


/////////////////////////////////////////////////////////////////
// 
-(IBAction)moveRight:(id)sender
{
   if([self.delegate respondsToSelector:@selector(moveRight:)])
   {
      [self.delegate moveRight:sender];
   }
   else
   {
   	[self rotateQuaternionWithVector:CGPointMake(
         CVKeyboardBasedRotationDelta,
         0.0f)];
      [[self window] invalidateCursorRectsForView:self];      
   }
}

@end
