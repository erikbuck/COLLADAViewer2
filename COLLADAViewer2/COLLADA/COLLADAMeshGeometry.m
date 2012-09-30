//
//  COLLADAMeshGeometry.m
//  COLLADAViewer2
//
//  Created by Erik Buck on 9/30/12.
//  Copyright (c) 2012 Erik Buck. All rights reserved.
//

#import "COLLADAMeshGeometry.h"
#import "AGLKMesh.h"


@implementation COLLADAMeshGeometry

/////////////////////////////////////////////////////////////////
//  
- (AGLKMesh *)mesh;
{
   if(nil == _mesh)
   {
      _mesh = [[AGLKMesh alloc] init];
   }
   
   return _mesh;
}

@end
