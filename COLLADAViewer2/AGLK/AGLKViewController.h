//
//  AGLKViewController.h
//  SPEditor
//
//  Created by Erik Buck on 9/11/12.
//  Copyright (c) 2012 Erik Buck. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AGLKView.h"

@protocol AGLKViewControllerDelegate;


@interface AGLKViewController : NSViewController
<AGLKViewDelegate>

@property (weak, nonatomic)
IBOutlet id <AGLKViewControllerDelegate> delegate;

@property (assign, nonatomic)
NSInteger preferredFramesPerSecond;

@property (assign, nonatomic, readonly)
NSInteger framesPerSecond;

@property (assign, nonatomic, getter=isPaused)
BOOL paused;

@property (assign, nonatomic, readonly)
NSInteger framesDisplayed;

@property (assign, nonatomic, readonly)
NSTimeInterval timeSinceLastUpdate;

@property (assign, nonatomic, readonly)
NSTimeInterval timeSinceLastDraw;

@end


#pragma mark -
#pragma mark AGLKViewControllerDelegate
#pragma mark -

@protocol AGLKViewControllerDelegate <NSObject>

@required
- (void)AGLKViewControllerUpdate:(AGLKViewController *)controller;

@end
