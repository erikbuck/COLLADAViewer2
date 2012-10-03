//
//  COLLADAMeshGeometry.m
//  COLLADAViewer2
//
//  Created by Erik Buck on 9/30/12.
//  Copyright (c) 2012 Erik Buck. All rights reserved.
//

#import "COLLADAMeshGeometry.h"
#import "COLLADARoot.h"
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


/////////////////////////////////////////////////////////////////
//
- (NSUInteger)calculateNumberOfTrianglesWithRoot:
   (COLLADARoot *)aRoot;
{
   NSUInteger result = 0;
   
   for(NSDictionary *currentCommand in self.mesh.self.commands)
   {
      // 3 indices are needed for each triangle
      result += [[currentCommand objectForKey:@"numberOfIndices"] 
            unsignedIntegerValue] / 3;
   }
   
   return result;
}

@end
