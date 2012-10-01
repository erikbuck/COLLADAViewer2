//
//  COLLADARoot.m
//  SPEditor
//
//  Created by Erik Buck on 9/29/12.
//  Copyright (c) 2012 Erik Buck. All rights reserved.
//

#import "COLLADARoot.h"

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
- (NSMutableDictionary *)meshes;
{
   if(nil == _meshes)
   {
      _meshes = [NSMutableDictionary dictionary];
   }
   
   return _meshes;
}

@end
