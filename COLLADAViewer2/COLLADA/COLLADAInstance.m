//
//  COLLADAInstance.m
//  COLLADAViewer2
//
//  Created by Erik Buck on 9/30/12.
//  Copyright (c) 2012 Erik Buck. All rights reserved.
//

#import "COLLADAInstance.h"
#import "COLLADAResource.h"
#import "COLLADARoot.h"


@implementation COLLADAInstance


/////////////////////////////////////////////////////////////////
//
- (NSUInteger)calculateNumberOfTrianglesWithRoot:
   (COLLADARoot *)aRoot;
{
   id referencedNode =
      [aRoot.nodes objectForKey:self.url];
   
   return [referencedNode
      calculateNumberOfTrianglesWithRoot:aRoot];
}

@end
