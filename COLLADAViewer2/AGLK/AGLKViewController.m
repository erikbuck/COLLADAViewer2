//
//  AGLKViewController.m
//  SPEditor
//
//  Created by Erik Buck on 9/11/12.
//  Copyright (c) 2012 Erik Buck. All rights reserved.
//

#import "AGLKViewController.h"

@interface AGLKViewController ()

@property (strong, nonatomic)
NSTimer *timer;

@property (atomic, assign)
CVTimeStamp outputTime;

@property (atomic, assign)
NSTimeInterval lastUpdateTime;

@property (atomic, assign)
NSTimeInterval firstUpdateTime;

@property (nonatomic, readwrite)
NSInteger framesPerSecond;

@property (nonatomic, readwrite)
NSInteger framesDisplayed;

@property (nonatomic, readwrite)
NSTimeInterval timeSinceLastUpdate;

@property (nonatomic, readwrite)
NSTimeInterval timeSinceLastDraw;

@end


@implementation AGLKViewController

/////////////////////////////////////////////////////////////////
// 
- (id)initWithNibName:(NSString *)nibNameOrNil
   bundle:(NSBundle *)nibBundleOrNil;
{
   if(nil != (self =
      [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]))
   {      
      self.preferredFramesPerSecond = 30.0;
   }
   
   return self;
}


/////////////////////////////////////////////////////////////////
// 
- (void)_spStartTimers
{
   [self.timer invalidate];

   self.timer = [NSTimer timerWithTimeInterval:
          1.0 / MAX(1, self.preferredFramesPerSecond)
       target:self
       selector:@selector(_spPrepareToDraw:)
       userInfo:nil
       repeats:YES];
   [[NSRunLoop mainRunLoop] addTimer:self.timer
      forMode:NSRunLoopCommonModes];
}


/////////////////////////////////////////////////////////////////
// 
- (void)_spInvalidateTimers
{
   [self.timer invalidate];
   self.timer = nil;
}


/////////////////////////////////////////////////////////////////
// 
- (void)setView:(NSView *)view
{
   NSParameterAssert(nil == view ||
      [view isKindOfClass:[AGLKView class]]);

   [super setView:view];
   
   if(nil != view)
   {
      if(nil == [(AGLKView *)view delegate])
      {
         [(AGLKView *)view setDelegate:self];
      }
      [self _spStartTimers];
   }
   else
   {
      [self _spInvalidateTimers];
   }
}


/////////////////////////////////////////////////////////////////
// 
- (void)aglkViewWillBeRemoved:(AGLKView *)view
{
   view.delegate = nil;
   self.view = nil;
}


/////////////////////////////////////////////////////////////////
// 
- (void)aglkViewDidHide:(AGLKView *)view
{
   [self _spInvalidateTimers];
}


/////////////////////////////////////////////////////////////////
// 
- (void)aglkViewDidUnhide:(AGLKView *)view
{
   [self _spStartTimers];
}


/////////////////////////////////////////////////////////////////
// 
- (void)update
{
}


/////////////////////////////////////////////////////////////////
// 
- (void)_spPrepareToDraw:(id)dummy
{
   @autoreleasepool
   {
      if(0 >= self.lastUpdateTime)
      {
         self.firstUpdateTime =
            [NSDate timeIntervalSinceReferenceDate];
         self.lastUpdateTime = self.firstUpdateTime;
      }
      else
      {
         NSTimeInterval currentTime =
            [NSDate timeIntervalSinceReferenceDate];
         self.timeSinceLastUpdate =
            (currentTime - self.lastUpdateTime);
         self.timeSinceLastDraw =
            (currentTime - self.lastUpdateTime);
         self.framesPerSecond = 1.0 / self.timeSinceLastUpdate;
         self.framesDisplayed++;
            
         [self update];
         [self.view display];

         self.lastUpdateTime = currentTime;
      }
   }
}


/////////////////////////////////////////////////////////////////
// 
- (void)initGL
{
	[[(AGLKView *)self.view openGLContext] makeCurrentContext];
	
	// Synchronize buffer swaps with vertical refresh rate
	GLint swapInt = 1;
	[[(AGLKView *)self.view openGLContext] setValues:&swapInt
      forParameter:NSOpenGLCPSwapInterval];
}


/////////////////////////////////////////////////////////////////
// 
- (void)prepareOpenGL
{
	// Make all the OpenGL calls to setup rendering  
	//  and build the necessary rendering objects
	[self initGL];
}


@end

