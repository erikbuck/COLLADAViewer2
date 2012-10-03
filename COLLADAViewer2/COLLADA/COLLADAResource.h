//
//  COLLADAResource.h
//  COLLADAViewer2
//
//  Created by Erik Buck on 9/30/12.
//  Copyright (c) 2012 Erik Buck. All rights reserved.
//

#import <Foundation/Foundation.h>

@class COLLADARoot;


@interface COLLADAResource : NSObject

@property (nonatomic, retain) NSString *uid;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSSet *instances;

- (NSUInteger)calculateNumberOfTrianglesWithRoot:
   (COLLADARoot *)aRoot;

@end
