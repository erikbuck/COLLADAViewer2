//
//  CVViewController.h
//  COLLADAViewer2
//
//  Created by Erik Buck on 9/30/12.
//  Copyright (c) 2012 Erik Buck. All rights reserved.
//

#import "AGLKViewController.h"

@protocol CVCOLLADASource;


@interface CVViewController : AGLKViewController

@property (weak, nonatomic, readwrite)
   id <CVCOLLADASource>colladaSource;

@end


@protocol CVCOLLADASource
<NSObject>

@required
- (NSArray *)roots;

@end
