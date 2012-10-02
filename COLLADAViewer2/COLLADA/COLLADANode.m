//
//  COLLADANode.m
//  COLLADAViewer2
//
//  Created by Erik Buck on 9/30/12.
//  Copyright (c) 2012 Erik Buck. All rights reserved.
//

#import "COLLADANode.h"
#import "COLLADANode.h"


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

@end
