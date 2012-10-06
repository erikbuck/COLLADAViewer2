//
//  COLLADAImagePath.h
//  COLLADAViewer2
//
//  Created by Erik Buck on 9/30/12.
//  Copyright (c) 2012 Erik Buck. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKMath.h>
#import "COLLADAResource.h"

@class GLKTextureInfo;


@interface COLLADAImagePath : COLLADAResource

@property (nonatomic, retain)
   NSURL *url;

@property (nonatomic, retain)
   NSImage *image;

@property (nonatomic, strong)
   GLKTextureInfo *textureInfo;

@property (nonatomic, assign)
   GLKMatrix4 textureTransform;

@property (nonatomic, readonly, strong) NSDictionary
   *plistRepresentation;

@end
