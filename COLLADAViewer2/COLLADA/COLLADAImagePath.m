//
//  COLLADAImagePath.m
//  COLLADAViewer2
//
//  Created by Erik Buck on 9/30/12.
//  Copyright (c) 2012 Erik Buck. All rights reserved.
//

#import "COLLADAImagePath.h"

#undef __gl_h_
#import <GLKit/GLKit.h>


@implementation COLLADAImagePath

/////////////////////////////////////////////////////////////////
//
- (id)init
{
    self = [super init];
    if (self)
    {
       self.textureTransform = GLKMatrix4Identity;
    }
   
    return self;
}


/////////////////////////////////////////////////////////////////
//
NSString *CVMissingImageName = @"MissingImage";

/////////////////////////////////////////////////////////////////
//
const float CVMaximumTextureDimension = 256.0;


/////////////////////////////////////////////////////////////////
//
- (void)loadImageFromBasePath:(NSString *)aPath;
{
   NSString *fullPath =
      [aPath stringByAppendingPathComponent:self.path];
   
   if(nil == fullPath)
   {
      NSLog(@"Invalid image path could not be loaded");
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
      image =
         CGImageSourceCreateImageAtIndex(imageSource, 0, nil);
      CFRelease(url);
      CFRelease(imageSource);
   }
   
   if(NULL == image)
   {
      NSLog(@"Image path could not be loaded: <%@>",
         fullPath);
   }
   else
   {
      NSSize imageSize =
         NSMakeSize(MIN(CVMaximumTextureDimension, CGImageGetWidth(image)),
             MIN(CVMaximumTextureDimension, CGImageGetHeight(image)));
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
               nil]
            error:&error];
      
      if(nil == self.textureInfo)
      {
         NSLog(@"Could not create texture for image: <%@>\n%@",
            fullPath, error);
      }
      else
      {
         glTexParameteri(GL_TEXTURE_2D, 
            GL_TEXTURE_MAG_FILTER, 
            GL_LINEAR);
         glTexParameteri(GL_TEXTURE_2D, 
            GL_TEXTURE_MIN_FILTER, 
            GL_NEAREST);
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


/////////////////////////////////////////////////////////////////
//
- (GLKTextureInfo *)textureInfo;
{   
   if(nil == _textureInfo)
   {
      NSString *path =
         [[NSBundle bundleForClass:[self class]]
            pathForImageResource:CVMissingImageName];
      
      if(nil == path)
      {
         NSLog(@"Could not finf placeholder for missing image.");
      }
      else
      {
         NSError *error = nil;
         
         self.textureInfo =
            [GLKTextureLoader textureWithContentsOfFile:path
               options:nil
               error:&error];
         
         if(nil == self.textureInfo)
         {
            NSLog(@"Could not create texture for image: <%@>\n%@",
               path, error);
         }
      }
   }
   
   return _textureInfo;
}

@end
