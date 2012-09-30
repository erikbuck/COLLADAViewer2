//
//  AGLKView.h
//  SPEditor
//
//  Created by Erik Buck on 9/11/12.
//  Copyright (c) 2012 Erik Buck. All rights reserved.
//

@protocol AGLKViewDelegate;


@interface AGLKView : NSOpenGLView

@property (weak, nonatomic, readwrite)
id <AGLKViewDelegate> delegate;

@end


@protocol AGLKViewDelegate <NSObject>

@required
- (void)prepareOpenGL;

@optional
- (void)aglkView:(AGLKView *)view
   drawInRect:(NSRect)rect;
- (void)aglkViewDidReshape:(AGLKView *)view;
- (void)aglkViewWillBeRemoved:(AGLKView *)view;
- (void)aglkViewDidHide:(AGLKView *)view;
- (void)aglkViewDidUnhide:(AGLKView *)view;

-(IBAction)moveUp:(id)sender;
-(IBAction)moveDown:(id)sender;
-(IBAction)moveLeft:(id)sender;
-(IBAction)moveRight:(id)sender;

@end
