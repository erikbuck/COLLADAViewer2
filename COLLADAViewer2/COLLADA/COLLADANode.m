//
//  COLLADANode.m
//  COLLADAViewer2
//
//  Created by Erik Buck on 9/30/12.
//  Copyright (c) 2012 Erik Buck. All rights reserved.
//

#import "COLLADANode.h"
#import "COLLADARoot.h"
#import "COLLADAInstance.h"


/////////////////////////////////////////////////////////////////
//
@interface COLLADANode ()

@property (nonatomic, assign, readwrite)
   NSUInteger numberOfTriangles;

@end


/////////////////////////////////////////////////////////////////
//
@implementation COLLADANode

/////////////////////////////////////////////////////////////////
//
- (id)init
{
    self = [super init];
    if (self)
    {
        self.transform = GLKMatrix4Identity;
    }
   
    return self;
}


/////////////////////////////////////////////////////////////////
//
- (NSSet *)subnodes;
{
   if(nil == _subnodes)
   {
      _subnodes = [NSSet set];
   }
   
   return _subnodes;
}


/////////////////////////////////////////////////////////////////
//
- (NSUInteger)calculateNumberOfTrianglesWithRoot:
   (COLLADARoot *)aRoot;
{
   NSUInteger result =
      [super calculateNumberOfTrianglesWithRoot:aRoot];
   
   for(COLLADANode *subnode in self.subnodes)
   {
      result += [subnode
         calculateNumberOfTrianglesWithRoot:aRoot];
   }
   
   self.numberOfTriangles = result;
   
   return result;
}

@end
