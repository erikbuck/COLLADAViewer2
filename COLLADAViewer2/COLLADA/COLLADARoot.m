//
//  COLLADARoot.m
//  SPEditor
//
//  Created by Erik Buck on 9/29/12.
//  Copyright (c) 2012 Erik Buck. All rights reserved.
//

#import "COLLADARoot.h"
#import "COLLADANode.h"
#import "COLLADAInstance.h"
#import "COLLADAMeshGeometry.h"
#import "COLLADAInstanceGeometry.h"
#import "AGLKMesh.h"


/////////////////////////////////////////////////////////////////
//
@interface COLLADARoot ()

@property (strong, nonatomic, readwrite)
   NSNumber *numberOfTriangles;

@end


/////////////////////////////////////////////////////////////////
//
@implementation COLLADARoot

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
- (NSUInteger)calculateNumberOfTriangles;
{
   NSUInteger result = 0;
   
   for(COLLADANode *scene in self.visualScenes.allValues)
   {
      result += [scene calculateNumberOfTrianglesWithRoot:self];
   }
   
   self.numberOfTriangles =
      [NSNumber numberWithUnsignedInteger:result];
   
   return result;
}


/////////////////////////////////////////////////////////////////
//
- (NSNumber *)numberOfVertices;
{
   NSInteger result = 0;
   
   for(COLLADAMeshGeometry *meshGeometry in
      self.geometries.allValues)
   {
      result += [meshGeometry.mesh numberOfIndices];
   }
   
   return [NSNumber numberWithUnsignedInteger:result];
}


/////////////////////////////////////////////////////////////////
//
- (NSNumber *)numberOfTextures;
{
   return [NSNumber numberWithUnsignedInteger:
      self.imagePaths.count];
}


/////////////////////////////////////////////////////////////////
//
- (NSMutableDictionary *)nodes;
{
   if(nil == _nodes)
   {
      _nodes = [NSMutableDictionary dictionary];
   }
   
   return _nodes;
}


/////////////////////////////////////////////////////////////////
//
- (NSMutableDictionary *)imagePaths;
{
   if(nil == _imagePaths)
   {
      _imagePaths = [NSMutableDictionary dictionary];
   }
   
   return _imagePaths;
}


/////////////////////////////////////////////////////////////////
//
- (NSMutableDictionary *)visualScenes;
{
   if(nil == _visualScenes)
   {
      _visualScenes = [NSMutableDictionary dictionary];
   }
   
   return _visualScenes;
}


/////////////////////////////////////////////////////////////////
//
- (NSMutableDictionary *)geometries;
{
   if(nil == _geometries)
   {
      _geometries = [NSMutableDictionary dictionary];
   }
   
   return _geometries;
}


/////////////////////////////////////////////////////////////////
//
- (NSMutableDictionary *)materials;
{
   if(nil == _materials)
   {
      _materials = [NSMutableDictionary dictionary];
   }
   
   return _materials;
}


/////////////////////////////////////////////////////////////////
//
- (NSMutableDictionary *)effects;
{
   if(nil == _effects)
   {
      _effects = [NSMutableDictionary dictionary];
   }
   
   return _effects;
}


/////////////////////////////////////////////////////////////////
//
+keyPathsForValuesAffectingInspectableNodes
{
   return [NSSet setWithObjects:
      @"nodes",
      nil];
}


/////////////////////////////////////////////////////////////////
//
- (NSArray *)inspectableNodes;
{
   return self.nodes.allValues;
}

@end
