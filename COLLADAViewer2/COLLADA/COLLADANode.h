//
//  COLLADANode.h
//  COLLADAViewer2
//
//  Created by Erik Buck on 9/30/12.
//  Copyright (c) 2012 Erik Buck. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKMath.h>
#import "COLLADAResource.h"

@class COLLADANode;

@interface COLLADANode : COLLADAResource

@property (nonatomic, assign) GLKMatrix4 transform;
@property (nonatomic, retain) NSSet *subnodes;
@property (nonatomic, retain) COLLADANode *parent;

@end
