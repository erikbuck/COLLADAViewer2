//
//  COLLADARoot+viewAdditions.m
//  SPEditor
//
//  Created by Erik Buck on 9/29/12.
//  Copyright (c) 2012 Erik Buck. All rights reserved.
//

#import "COLLADARoot+viewAdditions.h"
#import "COLLADANode.h"
#import "COLLADAMeshGeometry.h"
#import "COLLADAInstanceGeometry.h"
#import "COLLADAImagePath.h"
#import "AGLKEffect.h"
#import "AGLKMesh+viewAdditions.h"

#undef __gl_h_
#import <GLKit/GLKit.h>


/////////////////////////////////////////////////////////////////
//
@implementation COLLADAMeshGeometry (viewAdditions)

/////////////////////////////////////////////////////////////////
//
- (void)drawWithEffect:(AGLKEffect *)anEffect
   root:(COLLADARoot *)aRoot;
{
   [anEffect prepareToDraw];
   [self.mesh prepareToDraw];
   [self.mesh drawAllCommands];
}

@end


/////////////////////////////////////////////////////////////////
//
@implementation COLLADAInstance (viewAdditions)

/////////////////////////////////////////////////////////////////
//
- (void)drawWithEffect:(AGLKEffect *)anEffect
   root:(COLLADARoot *)aRoot;
{
   id referencedNode =
      [aRoot.nodes objectForKey:self.url];
   
   if(nil == referencedNode)
   {
      NSLog(@"instance_node references unknown geometry");
      return;
   }
   
   [referencedNode drawWithEffect:anEffect
      root:aRoot];
}

@end


@implementation COLLADAInstanceGeometry (viewAdditions)

/////////////////////////////////////////////////////////////////
//
- (void)drawWithEffect:(AGLKEffect *)anEffect
   root:(COLLADARoot *)aRoot;
{
   id referencedGeometry =
      [aRoot.geometries objectForKey:self.url];
   
   if(nil == referencedGeometry)
   {
      NSLog(@"instance_geometry references unknown geometry");
      return;
   }
   
   if(nil == self.textureInfo)
   {
      anEffect.texture2d0.name = 0;
      anEffect.texture2d0.target = 0;

      COLLADAInstance *bindMaterial = [self.bindMaterials anyObject];
      
      if(nil != bindMaterial)
      {
         self.textureInfo =
            [self textureForMaterialBinding:bindMaterial
               root:aRoot];
      }
   }
   
   if(nil != self.textureInfo)
   {
      anEffect.texture2d0.name = self.textureInfo.name;
      anEffect.texture2d0.target = self.textureInfo.target;
   }
   
   [referencedGeometry drawWithEffect:anEffect
      root:aRoot];
}

@end


/////////////////////////////////////////////////////////////////
//
@implementation COLLADANode (viewAdditions)

/////////////////////////////////////////////////////////////////
//
- (void)drawWithEffect:(AGLKEffect *)anEffect
   root:(COLLADARoot *)aRoot;
{
   GLKMatrix4 savedMatrix =
      anEffect.transform.modelviewMatrix;

   anEffect.transform.modelviewMatrix =
      GLKMatrix4Multiply(savedMatrix, self.transform);
   
   for(COLLADAInstance *instance in self.instances)
   {
      [instance drawWithEffect:anEffect
         root:aRoot];
   }
   
   for(COLLADANode *subnode in self.subnodes)
   {
      [subnode drawWithEffect:anEffect
         root:aRoot];
   }
   
   anEffect.transform.modelviewMatrix =
      savedMatrix;
}

@end


/////////////////////////////////////////////////////////////////
//
@implementation COLLADAImagePath (viewAdditions)

/////////////////////////////////////////////////////////////////
//
NSString *CVMissingImageName = @"MissingImage";


/////////////////////////////////////////////////////////////////
//
- (GLKTextureInfo *)placeholderTextureInfo;
{
   GLKTextureInfo *result = nil;
   
   NSString *path =
      [[NSBundle bundleForClass:[self class]]
         pathForImageResource:CVMissingImageName];
   
   if(nil == path)
   {
      NSLog(@"Could not find placeholder for missing image.");
   }
   else
   {
      NSError *error = nil;
      
      result =
         [GLKTextureLoader textureWithContentsOfFile:path
            options:[NSDictionary dictionaryWithObjectsAndKeys:
               [NSNumber numberWithBool:YES],
               GLKTextureLoaderOriginBottomLeft,
               [NSNumber numberWithBool:YES],
               GLKTextureLoaderGenerateMipmaps,
               nil]
            error:&error];
      
      if(nil == result)
      {
         NSLog(@"Could not create texture for image: <%@>\n%@",
            path, error);
      }
      else
      {
         glTexParameteri(GL_TEXTURE_2D, 
            GL_TEXTURE_MAG_FILTER, 
            GL_LINEAR);
         glTexParameteri(GL_TEXTURE_2D, 
            GL_TEXTURE_MIN_FILTER, 
            GL_NEAREST_MIPMAP_LINEAR);
         glTexParameteri(
            GL_TEXTURE_2D, 
            GL_TEXTURE_WRAP_S, 
            GL_REPEAT);
         glTexParameteri(
            GL_TEXTURE_2D, 
            GL_TEXTURE_WRAP_T, 
            GL_REPEAT);
      }
   }
   
   return result;
}


/////////////////////////////////////////////////////////////////
//
const float CVMaximumTextureDimension = 256.0;


/////////////////////////////////////////////////////////////////
//
- (void)loadImageFromBasePath:(NSString *)aPath;
{
   NSString *fullPath =
      [aPath stringByAppendingPathComponent:[self.url path]];
   
   if(nil == fullPath)
   {
      NSLog(@"Invalid image path could not be loaded");
      self.textureInfo = [self placeholderTextureInfo];
      return;
   }
   
	CGImageRef image = NULL;
   
   {
      CFURLRef url = CFURLCreateWithFileSystemPath(
         kCFAllocatorDefault,
         (__bridge CFStringRef)(fullPath),
         kCFURLPOSIXPathStyle,
         false);
      CGImageSourceRef imageSource =
         CGImageSourceCreateWithURL(url, nil);
      
      if(NULL != imageSource)
      {
         image =
            CGImageSourceCreateImageAtIndex(imageSource, 0, nil);
         CFRelease(imageSource);
      }
      CFRelease(url);
   }
   
   if(NULL == image)
   {
      NSLog(@"Image path could not be loaded: <%@>",
         fullPath);
      self.textureInfo = [self placeholderTextureInfo];
   }
   else
   {
      NSSize imageSize =
         NSMakeSize(
            MIN(CVMaximumTextureDimension,
               CGImageGetWidth(image)),
            MIN(CVMaximumTextureDimension,
               CGImageGetHeight(image)));
      self.image =
         [[NSImage alloc] initWithCGImage:image size:imageSize];
      
      if(nil == self.image)
      {
         NSLog(@"Image could not be cached: <%@>",
            fullPath);
      }

      NSError *error = nil;
      
      self.textureInfo =
         [GLKTextureLoader textureWithCGImage:image
            options:[NSDictionary dictionaryWithObjectsAndKeys:
               [NSNumber numberWithBool:YES],
               GLKTextureLoaderOriginBottomLeft,
               [NSNumber numberWithBool:YES],
               GLKTextureLoaderGenerateMipmaps,
               nil]
            error:&error];
      
      if(nil == self.textureInfo)
      {
         NSLog(@"Could not create texture for image: <%@>\n%@",
            fullPath, error);
         self.textureInfo = [self placeholderTextureInfo];
      }
      else
      {
         glTexParameteri(GL_TEXTURE_2D, 
            GL_TEXTURE_MAG_FILTER, 
            GL_LINEAR);
         glTexParameteri(GL_TEXTURE_2D, 
            GL_TEXTURE_MIN_FILTER, 
            GL_NEAREST_MIPMAP_LINEAR);
         glTexParameteri(
            GL_TEXTURE_2D, 
            GL_TEXTURE_WRAP_S, 
            GL_REPEAT);
         glTexParameteri(
            GL_TEXTURE_2D, 
            GL_TEXTURE_WRAP_T, 
            GL_REPEAT);
      }
   }
   
   CGImageRelease(image);
}

@end


/////////////////////////////////////////////////////////////////
//
@implementation COLLADARoot (viewAdditions)

/////////////////////////////////////////////////////////////////
//
- (void)drawWithEffect:(AGLKEffect *)anEffect;
{
   GLKMatrix4 savedMatrix =
      anEffect.transform.modelviewMatrix;

   anEffect.transform.modelviewMatrix =
      GLKMatrix4Multiply(savedMatrix, self.transform);
   
   for(COLLADANode *scene in self.visualScenes.allValues)
   {
      [scene drawWithEffect:anEffect
         root:self];
   }
   
   anEffect.transform.modelviewMatrix =
      savedMatrix;
}


/////////////////////////////////////////////////////////////////
//
- (void)loadImages
{
   for(COLLADAImagePath *imagePath in self.imagePaths.allValues)
   {
      [imagePath loadImageFromBasePath:self.path];
   }
}

@end
