//
//  COLLADAImagePath.m
//  COLLADAViewer2
//
//  Created by Erik Buck on 9/30/12.
//  Copyright (c) 2012 Erik Buck. All rights reserved.
//

#import "COLLADAImagePath.h"


@implementation COLLADAImagePath

/////////////////////////////////////////////////////////////////
//
- (id)init
{
    self = [super init];
    if (self)
    {
       self.textureTransform = GLKMatrix4Identity;
    }
   
    return self;
}


/////////////////////////////////////////////////////////////////
//
- (NSDictionary *)plistRepresentation
{
   return [NSDictionary dictionaryWithObjectsAndKeys:
      [self.image TIFFRepresentation],
      @"imageData", 
      [NSNumber numberWithUnsignedInteger:self.image.size.width],
      @"width", 
      [NSNumber numberWithUnsignedInteger:self.image.size.height],
      @"height", 
      nil];
}


@end
