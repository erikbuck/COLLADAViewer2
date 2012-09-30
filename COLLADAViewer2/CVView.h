//
//  CVView.h
//  COLLADAViewer2
//
//  Created by Erik Buck on 9/30/12.
//  Copyright (c) 2012 Erik Buck. All rights reserved.
//

#import "AGLKView.h"
#import <GLKit/GLKMath.h>


@interface CVView : AGLKView

- (GLKMatrix4)makeLookAtMatrixWithArcBall;
- (GLKMatrix4)makeRotateMatrixWithArcBall;

@end
