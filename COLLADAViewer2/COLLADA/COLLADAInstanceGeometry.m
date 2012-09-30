//
//  COLLADAInstanceGeometry.m
//  COLLADAViewer2
//
//  Created by Erik Buck on 9/30/12.
//  Copyright (c) 2012 Erik Buck. All rights reserved.
//

#import "COLLADAInstanceGeometry.h"


@implementation COLLADAInstanceGeometry

- (NSSet *)bindMaterials;
{
   if(nil == _bindMaterials)
   {
      _bindMaterials = [NSSet set];
   }
   
   return _bindMaterials;
}


@end
