//
//  AGLKModel.h
//  COLLADAViewer2
//
//  Created by Erik Buck on 10/6/12.
//  Copyright (c) 2012 Erik Buck. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AGLKMesh;


@interface AGLKModel : NSObject

@property (strong, nonatomic, readonly) AGLKMesh
   *mesh;
@property (copy, nonatomic, readwrite) NSString
   *name;
@property (copy, nonatomic, readonly) NSString
   *axisAlignedBoundingBox;
@property (strong, nonatomic, readonly) NSNumber
   *numberOfVertices;
@property (strong, nonatomic, readonly) NSDictionary
   *plistRepresentation;

- (id)initWithName:(NSString *)aName 
   mesh:(AGLKMesh *)aMesh
   indexOfFirstCommand:(NSUInteger)aFirstIndex
   numberOfCommands:(NSUInteger)count;

- (id)initWithPlistRepresentation:(NSDictionary *)aDictionary
   mesh:(AGLKMesh *)aMesh;

@end
