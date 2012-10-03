//
//  COLLADAResource.m
//  COLLADAViewer2
//
//  Created by Erik Buck on 9/30/12.
//  Copyright (c) 2012 Erik Buck. All rights reserved.
//

#import "COLLADAResource.h"
#import "COLLADAInstance.h"


@implementation COLLADAResource

/////////////////////////////////////////////////////////////////
//
- (NSSet *)instances;
{
   if(nil == _instances)
   {
      _instances = [NSSet set];
   }
   
   return _instances;
}


/////////////////////////////////////////////////////////////////
//
- (NSUInteger)calculateNumberOfTrianglesWithRoot:
   (COLLADARoot *)aRoot;
{
   NSUInteger result = 0;
   
   for(COLLADAInstance *instance in self.instances)
   {
      result += [instance
         calculateNumberOfTrianglesWithRoot:aRoot];
   }
   
   return result;
}

@end
