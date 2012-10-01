//
//  CVDocument.h
//  COLLADAViewer2
//
//  Created by Erik Buck on 9/30/12.
//  Copyright (c) 2012 Erik Buck. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CVViewController.h"


@class AGLKView;


@interface CVDocument : NSPersistentDocument
<CVCOLLADASource>

@property (weak, nonatomic, readwrite)
   IBOutlet AGLKView *aglkView;

@property (strong, nonatomic, readonly) NSArray
   *allRoots;
@property (strong, nonatomic, readwrite) NSIndexSet 
   *selectedRoots;

- (IBAction)importCOLLADA:(id)sender;

@end
