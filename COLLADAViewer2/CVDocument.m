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
#import "AGLKMesh.h"
#import "AGLKModel.h"


@implementation CVDocument

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
- (IBAction)exportModelplist:(id)sender;
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

@end
