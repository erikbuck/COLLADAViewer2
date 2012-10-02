//
//  CVDocument.h
//  COLLADAViewer2
//
//  Created by Erik Buck on 9/30/12.
//  Copyright (c) 2012 Erik Buck. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class AGLKView;


@interface CVDocument : NSPersistentDocument

@property (weak, nonatomic, readwrite)
   IBOutlet AGLKView *aglkView;

@property (strong, nonatomic, readonly)
   NSArray *allRoots;

- (IBAction)importCOLLADA:(id)sender;

@end
