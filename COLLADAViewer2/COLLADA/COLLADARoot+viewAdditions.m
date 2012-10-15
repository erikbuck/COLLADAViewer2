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
   
//   if(nil == self.textureInfo)
   {
      anEffect.texture2d0.name = 0;
      anEffect.texture2d0.target = 0;

      COLLADAInstance *bindMaterial =
         [self.bindMaterials anyObject];
      
      if(nil != bindMaterial)
      {
         COLLADAImagePath *imagePath =
            [self imagePathForMaterialBinding:bindMaterial
               root:aRoot];
         
         if(nil != imagePath.textureInfo)
         {
            anEffect.texture2d0.name =
               imagePath.textureInfo.name;
            anEffect.texture2d0.target =
               imagePath.textureInfo.target;
            anEffect.texture2d0Transform =
               imagePath.textureTransform;
         }
         else
         {
            anEffect.texture2d0.name = 0;
         }
      }
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
static CGImageRef CVCreateImageFromBasePath(NSString *fullPath)
{
	CGImageRef image = NULL;
   
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
      
   return image;
}


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
   
	CGImageRef image = CVCreateImageFromBasePath(fullPath);
   
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

      if(nil != self.textureInfo)
      { // Delete any previously loaded texture images
         GLuint name = self.textureInfo.name;
         
         if(0 != name)
         {
            glDeleteTextures(1, &name);
         }
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
// This method asks each image path mamaged by the receiver to
// load actual image data from the image path relative to the
// receiver's path.
// It's common for several different imagePath instances to end
// up loading identical image data. This method detects that case
// and consolidates image paths that have identical image data.
// Consequently, it's possible for the same image path instance
// to end up stored via multiple different uid keys in the
// receiver's dictionary of image paths. When that happens, the
// image path for any particular uid key may have a uid
// stored in the image path's uid property that differs from the
// key.
- (void)loadImages
{
   NSArray *allImagePaths =
      [self.imagePaths.allValues copy];
   NSMutableSet *uniqueImagePaths =
      [NSMutableSet set];
   
   for(COLLADAImagePath *imagePath in allImagePaths)
   {
      [imagePath loadImageFromBasePath:self.path];
      
      // If an image path that's equal to imagePath in the sense
      // that both image paths have the same image
      if([uniqueImagePaths containsObject:imagePath])
      {  // Replace the image path just laded with the existing
         // path that has the same image
         [self.imagePaths
            setObject:[uniqueImagePaths member:imagePath]
            forKey:imagePath.uid];
      }
      else
      {  // This image data is unique
         [uniqueImagePaths addObject:imagePath];
      }
   }
}


/////////////////////////////////////////////////////////////////
//
- (void)useTextureAtlasImage:(NSImage *)anImage;
{
   NSError *error = nil;
   
   // Use Tiff reprsentation because GLKTextureLoader doesn't
   // support CGImageRef obtained directly from NSImage
   GLKTextureInfo *atlasTextureInfo =
      [GLKTextureLoader textureWithContentsOfData:
            [anImage TIFFRepresentation]
         options:[NSDictionary dictionaryWithObjectsAndKeys:
            [NSNumber numberWithBool:NO],
            GLKTextureLoaderOriginBottomLeft,
            [NSNumber numberWithBool:YES],
            GLKTextureLoaderGenerateMipmaps,
            nil]
         error:&error];
   
   if(nil == atlasTextureInfo)
   {
      NSLog(@"Could not create atlas texture.\n%@",
         error);
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
         GL_CLAMP);
      glTexParameteri(
         GL_TEXTURE_2D, 
         GL_TEXTURE_WRAP_T, 
         GL_CLAMP);

      for(COLLADAImagePath *imagePath in self.imagePaths.allValues)
      {
         imagePath.textureInfo = atlasTextureInfo;
      }
   }
}

@end
