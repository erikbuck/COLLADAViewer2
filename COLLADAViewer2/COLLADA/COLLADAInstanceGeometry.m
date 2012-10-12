//
//  COLLADAInstanceGeometry.m
//  COLLADAViewer2
//
//  Created by Erik Buck on 9/30/12.
//  Copyright (c) 2012 Erik Buck. All rights reserved.
//

#import "COLLADAInstanceGeometry.h"
#import "COLLADARoot.h"
#import "COLLADAResource.h"
#import "COLLADAEffect.h"
#import "COLLADAImagePath.h"


@implementation COLLADAInstanceGeometry

/////////////////////////////////////////////////////////////////
//
- (NSSet *)bindMaterials;
{
   if(nil == _bindMaterials)
   {
      _bindMaterials = [NSSet set];
   }
   
   return _bindMaterials;
}


/////////////////////////////////////////////////////////////////
//
- (COLLADAImagePath *)imagePathForMaterialBinding:
   (COLLADAInstance *)bindMaterial
   root:(COLLADARoot *)aRoot;
{
   COLLADAImagePath *result = nil;
   
   COLLADAResource *referencedMaterial =
      [aRoot.materials objectForKey:bindMaterial.url];
   
   if(nil == referencedMaterial)
   {
      NSLog(@"instance_geometry references unknown material");
   }
   else
   {
      COLLADAInstance *instanceEffect =
         referencedMaterial.instances.anyObject;
      
      COLLADAEffect *referencedEffect =
         [aRoot.effects objectForKey:instanceEffect.url];
      
      if(nil == referencedEffect)
      {
         NSLog(@"instance_geometry references unknown effect");
      }
      else
      {
         result = [aRoot.imagePaths objectForKey:
            referencedEffect.diffuseTextureImagePathURL];
      }
   }
   
   return result;
}


/////////////////////////////////////////////////////////////////
//
- (NSUInteger)calculateNumberOfTrianglesWithRoot:
   (COLLADARoot *)aRoot;
{
   id referencedGeometry =
      [aRoot.geometries objectForKey:self.url];
      
   return [referencedGeometry
     calculateNumberOfTrianglesWithRoot:aRoot];
}

@end
