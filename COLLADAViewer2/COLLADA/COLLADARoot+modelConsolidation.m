//
//  COLLADARoot+modelConsolidation.m
//  COLLADAViewer2
//
//  Created by Erik Buck on 10/5/12.
//  Copyright (c) 2012 Erik Buck. All rights reserved.
//

#import "COLLADARoot+modelConsolidation.h"
#import "COLLADANode.h"
#import "COLLADAInstance.h"
#import "COLLADAInstanceGeometry.h"
#import "COLLADAMeshGeometry.h"
#import "AGLKMesh.h"
#import "AGLKModel.h"


/////////////////////////////////////////////////////////////////
//
@implementation COLLADAMeshGeometry (modelConsolidation)

/////////////////////////////////////////////////////////////////
//
- (void)appendToMesh:(AGLKMesh *)aMesh
   root:(COLLADARoot *)aRoot
   transform:(GLKMatrix4)aTransform;
{
   [aMesh appendMesh:[self.mesh copyWithTransform:aTransform
      textureTransform:GLKMatrix3Identity]];
}

@end


/////////////////////////////////////////////////////////////////
//
@implementation COLLADAInstanceGeometry (modelConsolidation)

/////////////////////////////////////////////////////////////////
//
- (void)appendToMesh:(AGLKMesh *)aMesh
   root:(COLLADARoot *)aRoot
   transform:(GLKMatrix4)aTransform;
{
   id referencedGeometry =
      [aRoot.geometries objectForKey:self.url];
   
   if(nil == referencedGeometry)
   {
      NSLog(@"instance_geometry references unknown geometry");
      return;
   }
   
   [referencedGeometry appendToMesh:aMesh
      root:aRoot
      transform:aTransform];
}

@end


/////////////////////////////////////////////////////////////////
//
@implementation COLLADAInstance (modelConsolidation)

/////////////////////////////////////////////////////////////////
//
- (void)appendToMesh:(AGLKMesh *)aMesh
   root:(COLLADARoot *)aRoot
   transform:(GLKMatrix4)aTransform;
{
   id referencedNode =
      [aRoot.nodes objectForKey:self.url];
   
   if(nil == referencedNode)
   {
      NSLog(@"instance_node references unknown geometry");
      return;
   }
   
   [referencedNode appendToMesh:aMesh
      root:aRoot
      transform:aTransform];
}

@end


/////////////////////////////////////////////////////////////////
//
@implementation COLLADANode (modelConsolidation)

/////////////////////////////////////////////////////////////////
//
- (void)appendToMesh:(AGLKMesh *)aMesh
   root:(COLLADARoot *)aRoot
   transform:(GLKMatrix4)aTransform;
{
   GLKMatrix4 localTransform =
      GLKMatrix4Multiply(aTransform, self.transform);
   
   for(COLLADAInstance *instance in self.instances)
   {
      [instance appendToMesh:aMesh
         root:aRoot
         transform:localTransform];
   }
   
   for(COLLADANode *subnode in self.subnodes)
   {
      [subnode appendToMesh:aMesh
         root:aRoot
         transform:localTransform];
   }
}


@end


/////////////////////////////////////////////////////////////////
//
@implementation COLLADARoot (modelConsolidation)

/////////////////////////////////////////////////////////////////
//
- (AGLKModel *)consolidatedModelWithMesh:(AGLKMesh *)consolidatedMesh;
{
   NSParameterAssert(nil != consolidatedMesh);
   
   NSUInteger nextAvailableCommandIndex =
      [consolidatedMesh commands].count;
   
   for(COLLADANode *scene in self.visualScenes.allValues)
   {
      [scene appendToMesh:consolidatedMesh
         root:self
         transform:self.transform];
   }

   return [[AGLKModel alloc] initWithName:self.name
      mesh:consolidatedMesh
      indexOfFirstCommand:nextAvailableCommandIndex
      numberOfCommands:([consolidatedMesh commands].count -
         nextAvailableCommandIndex)];
}


@end
