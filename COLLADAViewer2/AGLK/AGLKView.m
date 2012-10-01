//
//  AGLKView.m
//  SPEditor
//
//  Created by Erik Buck on 9/11/12.
//  Copyright (c) 2012 Erik Buck. All rights reserved.
//

#import "AGLKView.h"

@implementation AGLKView

- (void)dealloc
{
   //NSLog(@"AGLKView -dealloc");
}


/////////////////////////////////////////////////////////////////
// 
- (void)removeFromSuperview
{
   if([self.delegate respondsToSelector:
      @selector(aglkViewWillBeRemoved:)])
   {
      [self.delegate aglkViewWillBeRemoved:self];
   }
   
   [super removeFromSuperview];   
}


/////////////////////////////////////////////////////////////////
// 
- (void)viewDidHide
{
   [super removeFromSuperview];
   
   if([self.delegate respondsToSelector:
      @selector(aglkViewWasRemoved:)])
   {
      [self.delegate aglkViewDidHide:self];
   }
}


/////////////////////////////////////////////////////////////////
// 
- (void)viewDidUnhide
{
   [super removeFromSuperview];
   
   if([self.delegate respondsToSelector:
      @selector(aglkViewWasRemoved:)])
   {
      [self.delegate aglkViewDidUnhide:self];
   }
}


/////////////////////////////////////////////////////////////////
// 
- (void)prepareOpenGL;
{
   [super prepareOpenGL];

   [self.delegate prepareOpenGL];
}


/////////////////////////////////////////////////////////////////
// 
- (void)reshape
{
	[[self openGLContext] makeCurrentContext];

   if([self.delegate respondsToSelector:
      @selector(aglkViewDidReshape:)])
   {
      [self.delegate aglkViewDidReshape:self];
   }
}


/////////////////////////////////////////////////////////////////
// 
- (void)drawRect:(NSRect)dirtyRect
{
	[[self openGLContext] makeCurrentContext];

   if([self.delegate respondsToSelector:
      @selector(aglkView:drawInRect:)])
   {
      [self.delegate aglkView:self drawInRect:dirtyRect];
   }
   else
   {
   }
	
   glFlush();
	CGLFlushDrawable([[self openGLContext] CGLContextObj]);
}

@end
