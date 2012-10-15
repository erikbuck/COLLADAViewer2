//
//  CVDocument.m
//  COLLADAViewer2
//
//  Created by Erik Buck on 9/30/12.
//  Copyright (c) 2012 Erik Buck. All rights reserved.
//

#import "CVDocument.h"
#import "COLLADAParser.h"
#import "COLLADARoot+viewAdditions.h"
#import "COLLADARoot+modelConsolidation.h"
#import "COLLADAImagePath.h"
#import "COLLADAMeshGeometry.h"
#import "AGLKMesh.h"
#import "AGLKModel.h"

#undef __gl_h_
#import <GLKit/GLKit.h>


@interface CVDocument ()

@property (strong, nonatomic, readwrite)
   IBOutlet NSView *openCOLLADAAccessoryView;

@property (assign, nonatomic, readwrite)
   BOOL shouldPreserveTextureCoordinates;

@end


@implementation CVDocument

#pragma mark - (MVC) Model access

/////////////////////////////////////////////////////////////////
// 
- (NSArray *)allRoots
{
   if(nil == _allRoots)
   {
      _allRoots = [NSMutableArray array];
   }
   
   return _allRoots;
}


/////////////////////////////////////////////////////////////////
// 
- (void)appendRoot:(COLLADARoot *)aRoot
{
   self.allRoots =
      [self.allRoots arrayByAddingObject:aRoot];
}


#pragma mark - Document GUI

/////////////////////////////////////////////////////////////////
// 
- (NSString *)windowNibName
{
   // Override returning the nib file name of the document
   // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
   return @"CVDocument";
}


/////////////////////////////////////////////////////////////////
// 
+ (BOOL)autosavesInPlace
{
    return YES;
}


/////////////////////////////////////////////////////////////////
//
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem;
{
   BOOL result = [super validateMenuItem:menuItem];
   
   if([menuItem action] == @selector(exportModelplist:))
   {
      result = (0 < self.allRoots.count);
   }
   
   return result;
}


#pragma mark - Model loading

/////////////////////////////////////////////////////////////////
//
- (void)appendRootParsedFromCOLLADAFileAtURL:(NSURL *)aURL
{
   COLLADAParser *coladaParser =
      [[COLLADAParser alloc] init];
      
   [coladaParser parseCOLLADAFileAtURL:aURL];
   
   [self appendRoot:coladaParser.root];
   [coladaParser.root loadImages];
   [coladaParser.root calculateNumberOfTriangles];

   if(!self.shouldPreserveTextureCoordinates)
   {
      // Tell roots to normalize texture vertices
      for(COLLADAMeshGeometry *meshGeometry in
         coladaParser.root.geometries.allValues)
      {
         [meshGeometry.mesh normalizeAllTextureCoords];
      }
   }
   
   [self updateChangeCount:NSChangeReadOtherContents];
}


/////////////////////////////////////////////////////////////////
//
- (IBAction)importCOLLADA:(id)sender
{
   NSOpenPanel *oPanel = [NSOpenPanel openPanel];

   NSArray *fileTypes = [NSArray arrayWithObject:@"dae"];
   
   [oPanel setMessage:NSLocalizedString(
       @"Choose COLLADA .dae files to import.", 
       @"Choose COLLADA .dae files to import.")];
	[oPanel setCanChooseDirectories:NO];
	[oPanel setResolvesAliases:YES];
	[oPanel setCanChooseFiles:YES];
   [oPanel setAllowsMultipleSelection:YES];
   oPanel.allowedFileTypes = fileTypes;
   oPanel.accessoryView = self.openCOLLADAAccessoryView;
   
	void (^openPanelHandler)(NSInteger) = ^( NSInteger result )
	{
      NSArray *urlsToOpen = [oPanel URLs];
      
      for (NSURL *aURL in urlsToOpen)
      {
         [self appendRootParsedFromCOLLADAFileAtURL:aURL];
      }
	};
	
   [oPanel beginSheetModalForWindow:[self windowForSheet] 
      completionHandler:openPanelHandler];
}


#pragma mark - Modelplist support

/////////////////////////////////////////////////////////////////
// Creates and returns a dictionary containing plists of models
// keyed by model name. Model names are made unique if any
// conflict. All models share vertices appended into
// consolidatedMesh. The total number of vertices appended by
// this method will not excede the capacity consolidatedMesh.
// Excess vertices are discarded and models may be corrupted as
// a result.
- (NSDictionary *)allModelsPlistRepresentationWithMesh:
   (AGLKMesh *)consolidatedMesh;
{
   NSMutableDictionary *result = [NSMutableDictionary dictionary];
   
   for(COLLADARoot *root in self.allRoots)
   {
      AGLKModel *model =
         [root consolidatedModelWithMesh:consolidatedMesh];
      
      // Normalize texture vertices
      [consolidatedMesh normalizeAllTextureCoords];

      NSString *uniqueName = model.name;
      int counter = 1;
      
      while(nil != [result objectForKey:uniqueName])
      {  // Model with name already exists in dictionary
         uniqueName = [model.name stringByAppendingFormat:@"%d",
               counter];

         counter++;
      }
      
      model.name = uniqueName;
      NSAssert(nil == [result objectForKey:model.name],
         @"Duplicate model names");

      [result setObject:model.plistRepresentation 
         forKey:model.name];
   }
   
   return result;
}


/////////////////////////////////////////////////////////////////
// Returns a plist representation of the first image path found
// in allRoots. Returns an empty dictionary if no image paths
// are available.
- (NSDictionary *)modelplistTextureInfoPlist
{
   // Combine all the textures into one texture atlas
   [self consolidateTexturesIntoAtlas];
   
   COLLADAImagePath *anyImagePath = nil;
   
   for(COLLADARoot *root in self.allRoots)
   {
     if(nil == anyImagePath)
     {
         anyImagePath =
            [[root.imagePaths allValues] lastObject];
     }
   }
   
   NSDictionary *textureImageInfoPlist =
      [NSDictionary dictionary];
   
   if(nil != anyImagePath)
   {
      textureImageInfoPlist = [anyImagePath plistRepresentation];
   }
   
   return textureImageInfoPlist;
}


/////////////////////////////////////////////////////////////////
//
- (void)unconditionallyExportModelplist
{
   NSSavePanel *sPanel = [NSSavePanel savePanel];

   NSArray *fileTypes = [NSArray arrayWithObject:@"modelplist"];
   
   [sPanel setMessage:NSLocalizedString(
       @"Exporting to Modelplist format.",
       @"Exporting to Modelplist format.")];

   sPanel.allowedFileTypes = fileTypes;

	void (^savePanelHandler)(NSInteger) = ^( NSInteger result )
	{
      // This new empty mesh will accumulate the vertices from
      // all models to be exported
      AGLKMesh *consolidatedMesh =
         [[AGLKMesh alloc] init];
      
      NSData *modelPlistData =
         [NSKeyedArchiver archivedDataWithRootObject:
            [NSDictionary dictionaryWithObjectsAndKeys:
               [self modelplistTextureInfoPlist],
               @"textureImageInfo",
               [self allModelsPlistRepresentationWithMesh:consolidatedMesh],
               @"models",
               consolidatedMesh.plistRepresentation,
               @"mesh",
               nil]];
      [modelPlistData writeToURL:[sPanel URL] atomically:YES];
	};
	
   [sPanel beginSheetModalForWindow:[self windowForSheet] 
      completionHandler:savePanelHandler];
}


/////////////////////////////////////////////////////////////////
//
- (void)conditionallyExportModelplist:(NSAlert *)alert
   returnCode:(NSInteger)returnCode
   contextInfo:(void *)contextInfo;
{
   if(NSAlertDefaultReturn == returnCode)
   {
      [self unconditionallyExportModelplist];
   }
}


/////////////////////////////////////////////////////////////////
//
- (IBAction)exportModelplist:(id)sender;
{
   NSUInteger cumulativeNumberOfVertices = 0;
   
   // Calculate the total number of vertices in all models
   for(COLLADARoot *root in self.allRoots)
   {
      cumulativeNumberOfVertices +=
         root.numberOfVertices.unsignedIntegerValue;
   }
   
   if(AGLKMeshMaximumNumberOfVertices <
      cumulativeNumberOfVertices)
   {
      NSAlert *exportAlert =
         [NSAlert alertWithMessageText:
            NSLocalizedString(
               @"Some information will be discared during export.",
               @"Some information will be discared during export.")
            defaultButton:
            NSLocalizedString(
               @"Export Anyway",
               @"Export Anyway")
            alternateButton:
            NSLocalizedString(
               @"Cancel Export",
               @"Cancel Export")
            otherButton:nil
            informativeTextWithFormat:
            NSLocalizedString(
               @"The modelplist file format is limited to storing a maximum of %lu vertices. The collection of models being exported contains at least %lu vertices.",
               @"The modelplist file format is limited to storing a maximum of %lu vertices. The collection of models being exported contains at least %lu vertices."),
            AGLKMeshMaximumNumberOfVertices,
            cumulativeNumberOfVertices];
      
      [exportAlert beginSheetModalForWindow:self.windowForSheet
         modalDelegate:self
         didEndSelector:@selector(conditionallyExportModelplist:returnCode:contextInfo:)
         contextInfo:nil];
   }
   else
   {
      [self unconditionallyExportModelplist];
   }
}


#pragma mark - Texture Atlas

/////////////////////////////////////////////////////////////////
//
- (NSSet *)allTextureImagePaths
{
   NSMutableSet *textureImages =
      [NSMutableSet set];
   
   for(COLLADARoot *root in self.allRoots)
   {
      for(NSString *imagePathKey in root.imagePaths)
      {
         COLLADAImagePath *imagePath =
            [root.imagePaths objectForKey:imagePathKey];
         
         if(nil != imagePath.image)
         {
            [textureImages addObject:imagePath];
         }
         else
         {
            NSLog(@"Image Path <%@> has no image.",
               imagePathKey);
         }
      }
   }

   return textureImages;
}


/////////////////////////////////////////////////////////////////
//
const NSInteger CVMaximumNumberOfLargeImages = (8);
const NSInteger CVMaximumNumberOfMediumImages = (8);
const NSInteger CVMaximumNumberOfSmallImages = (16);
const NSSize CVLargeImageSize = {256.0f, 256.0f};
const NSSize CVMediumImageSize = {256.0f, 128.0f};
const NSSize CVSmallImageSize = {128.0f, 128.0f};
const size_t CVTextureAtlasWidth = 1024.0f;
const size_t CVTextureAtlasHeight = 1024.0f;


/////////////////////////////////////////////////////////////////
//
- (void)tileImagePaths:(NSArray *)imagePaths
   inContext:(CGContextRef)textureAtlasContext
   xOffset:(size_t)xOffset
   yOffset:(size_t)yOffset
   width:(size_t)width
   height:(size_t)height
{
   for(COLLADAImagePath *imagePath in imagePaths)
   {
      NSAssert((xOffset + width) <=
         CVTextureAtlasWidth, @"Invalid image offset.");
      NSAssert((yOffset + height) <=
         CVTextureAtlasHeight, @"Invalid image offset.");
      
      CGRect destinationRect =
         CGRectMake(xOffset, yOffset, width, height);
      
      CGContextDrawImage(
         textureAtlasContext,
         destinationRect,
         [imagePath.image CGImageForProposedRect:&destinationRect
            context:nil
            hints:nil]);
      
      // Set transform so that image path will use correct
      // part of atlas
      imagePath.textureTransform =
         GLKMatrix4Translate(imagePath.textureTransform,
            (float)xOffset / (float)CVTextureAtlasWidth,
            ((CVTextureAtlasHeight - height) - (float)yOffset) / (float)CVTextureAtlasHeight,
            0.0);
      imagePath.textureTransform =
         GLKMatrix4Scale(imagePath.textureTransform,
            (float)width / (float)CVTextureAtlasWidth,
            (float)height / (float)CVTextureAtlasHeight,
            1.0);
      
      yOffset += height;
      if(yOffset >= CVTextureAtlasHeight)
      {
         yOffset = 0.0f;
         xOffset += width;
      }
   }
}


/////////////////////////////////////////////////////////////////
//
- (NSImage *)textureAtlasForLargeImagePaths:(NSArray *)largeImagePaths
   mediumImagePaths:(NSArray *)mediumImagePaths
   smallImagePaths:(NSArray *)smallImagePaths
{
   // Build Texture Atlas image, update image paths to use atlas
   CGColorSpaceRef colorSpace =
      CGColorSpaceCreateDeviceRGB();
   CGContextRef textureAtlasContext =
      CGBitmapContextCreate(
         NULL,
         CVTextureAtlasWidth,
         CVTextureAtlasHeight,
         8, // bitsPerComponent
         4 * CVTextureAtlasWidth, // bytesPerRow
         colorSpace,
         kCGImageAlphaPremultipliedLast
      );
   CGColorSpaceRelease(colorSpace);

   {  // Layout large texture images
      [self tileImagePaths:largeImagePaths
         inContext:textureAtlasContext
         xOffset:0.0f
         yOffset:0.0f
         width:CVLargeImageSize.width
         height:CVLargeImageSize.height];
   }
   {  // Layout medium texture images
      [self tileImagePaths:mediumImagePaths
         inContext:textureAtlasContext
         xOffset:512.0f
         yOffset:0.0f
         width:CVMediumImageSize.width
         height:CVMediumImageSize.height];
   }
   {  // Layout small texture images
      [self tileImagePaths:smallImagePaths
         inContext:textureAtlasContext
         xOffset:512.0f + 256.0f
         yOffset:0.0f
         width:CVSmallImageSize.width
         height:CVSmallImageSize.height];
   }
   
   // Get image corresponding to new texture atlas
   CGImageRef textureAtlasImageRef =
      CGBitmapContextCreateImage(textureAtlasContext);
   
   NSImage *textureAtlasImage =
      [[NSImage alloc] initWithCGImage:textureAtlasImageRef
         size:NSMakeSize(CVTextureAtlasWidth,
            CVTextureAtlasHeight)];

   CGImageRelease(textureAtlasImageRef);
   CGContextRelease(textureAtlasContext);
   
   return textureAtlasImage;
}


/////////////////////////////////////////////////////////////////
//
NSComparator CVImagePathSizeComparator =
   ^NSComparisonResult(
      COLLADAImagePath *obj1,
      COLLADAImagePath *obj2)
   {
      NSSize obj1Size = obj1.image.size;
      NSSize obj2Size = obj2.image.size;
      
      if((obj1Size.width * obj1Size.height) >
         (obj2Size.width * obj2Size.height))
      {
         return NSOrderedDescending;
      }
      else if((obj1Size.width * obj1Size.height) <
         (obj2Size.width * obj2Size.height))
      {
         return NSOrderedAscending;
      }
      else
      {
         return NSOrderedSame;
      }
   };


/////////////////////////////////////////////////////////////////
//
- (void)consolidateTexturesIntoAtlas
{
   // Sort texture images by size. -allTextureImagePaths returns
   // a set, so we know each image path is unique and we won't
   // end up copying the same image into the atlas multiple times.
   NSArray *sortedTextureImagePaths =
      [[[self allTextureImagePaths] allObjects]
         sortedArrayUsingComparator:CVImagePathSizeComparator];

   // Collect imagePaths into bins by size
   NSMutableArray *largeImagePaths = [NSMutableArray array];
   NSMutableArray *mediumImagePaths = [NSMutableArray array];
   NSMutableArray *smallImagePaths = [NSMutableArray array];
   
   for(COLLADAImagePath *imagePath in sortedTextureImagePaths)
   {
      NSSize imageSize = imagePath.image.size;
      
      if(imageSize.width >= CVLargeImageSize.width)
      {
         if((imageSize.height >= CVLargeImageSize.height) &&
            (largeImagePaths.count < CVMaximumNumberOfLargeImages))
         { // Use large image slot
            [largeImagePaths addObject:imagePath];
         }
         else if((imageSize.height >= CVMediumImageSize.height) &&
            (mediumImagePaths.count < CVMaximumNumberOfMediumImages))
         { // Use medium image slot
            [mediumImagePaths addObject:imagePath];
         }
         else if(smallImagePaths.count < CVMaximumNumberOfSmallImages)
         { // Use small image slot
            [smallImagePaths addObject:imagePath];
         }
         else
         {
            NSLog(@"Txture image discarded: %@.",
               @"insufficient space in Texture Atlas");
         }
      }
      else if(imageSize.width >= CVMediumImageSize.width)
      {
         if((imageSize.height >= CVMediumImageSize.height) &&
            (mediumImagePaths.count < CVMaximumNumberOfMediumImages))
         { // Use medium image slot
            [mediumImagePaths addObject:imagePath];
         }
         else if(smallImagePaths.count < CVMaximumNumberOfSmallImages)
         { // Use small image slot
            [smallImagePaths addObject:imagePath];
         }
         else
         {
            NSLog(@"Txture image discarded: %@.",
               @"insufficient space in Texture Atlas");
         }
      }
      else if(smallImagePaths.count < CVMaximumNumberOfSmallImages)
      { // Use small image slot
         [smallImagePaths addObject:imagePath];
      }
      else
      {
         NSLog(@"Txture image discarded: %@.",
            @"insufficient space in Texture Atlas");
      }
   }
   
   NSImage *textureAtlasImage =
      [self textureAtlasForLargeImagePaths:largeImagePaths
         mediumImagePaths:mediumImagePaths
         smallImagePaths:smallImagePaths];
   
//#ifdef DEBUG_TEXTURE_ATLAS
   {
      NSString *path =
         [@"~/TextureAtlas.tiff" stringByExpandingTildeInPath];
      [[textureAtlasImage TIFFRepresentation]
         writeToFile:path
         atomically:NO];
   }
//#endif

   // Tell image paths to use textureAtlasImage
   for(COLLADAImagePath *imagePath in sortedTextureImagePaths)
   {
      imagePath.image = textureAtlasImage;
   }
   
   // Tell roots to use textureAtlasImage
   for(COLLADARoot *root in self.allRoots)
   {
      [root useTextureAtlasImage:textureAtlasImage];
   }
}

@end
