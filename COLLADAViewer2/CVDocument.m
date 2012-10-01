//
//  CVDocument.m
//  COLLADAViewer2
//
//  Created by Erik Buck on 9/30/12.
//  Copyright (c) 2012 Erik Buck. All rights reserved.
//

#import "CVDocument.h"
#import "COLLADAParser.h"
#import "COLLADARoot.h"


@interface CVDocument ()

@property (strong, nonatomic, readwrite)
   CVViewController *viewController;
@property (strong, nonatomic, readwrite)
   NSArray *allRoots;

@end


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
- (void)windowControllerDidLoadNib:(NSWindowController *)aController
{
   [super windowControllerDidLoadNib:aController];

   self.viewController =
      [[CVViewController alloc] initWithNibName:nil bundle:nil];
   self.viewController.view = self.aglkView;
   self.viewController.colladaSource = self;
   
   // Make view the first responder to receive events
   [self.aglkView.window makeFirstResponder:self.aglkView];
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
      const NSUInteger startNumRoots = [self.allRoots count];
      NSArray *urlsToOpen = [oPanel URLs];
      
      for (NSURL *aURL in urlsToOpen)
      {
         [self appendRootParsedFromCOLLADAFileAtURL:aURL];
      }
      
      // Select all newly added roots
      const NSUInteger numRoots = [self.allRoots count];
      NSRange selectionRange = 
         {startNumRoots, numRoots - startNumRoots};
      self.selectedRoots =
         [NSIndexSet indexSetWithIndexesInRange:selectionRange];
	};
	
   [oPanel beginSheetModalForWindow:[self windowForSheet] 
      completionHandler:openPanelHandler];
}

@end
