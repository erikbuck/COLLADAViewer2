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
//
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
      NSLog(@"%@", [sPanel URL]);
      AGLKMesh *consolidatedMesh =
         [[AGLKMesh alloc] init];
      COLLADARoot *anyRoot =
         [self.allRoots lastObject];
      COLLADAImagePath *anyImagePath =
         [[anyRoot.imagePaths allValues] lastObject];
      NSDictionary *textureImageInfo =
         [NSDictionary dictionary];
      
      if(nil != anyImagePath)
      {
         textureImageInfo = [anyImagePath plistRepresentation];
      }
      
      NSData *modelPlist =
         [NSKeyedArchiver archivedDataWithRootObject:
            [NSDictionary dictionaryWithObjectsAndKeys:
               textureImageInfo,
               @"textureImageInfo",
               [self allModelsPlistRepresentationWithMesh:consolidatedMesh],
               @"models",
               consolidatedMesh.plistRepresentation,
               @"mesh",
               nil]];
      [modelPlist writeToURL:[sPanel URL] atomically:YES];
	};
	
   [sPanel beginSheetModalForWindow:[self windowForSheet] 
      completionHandler:savePanelHandler];
}

@end
