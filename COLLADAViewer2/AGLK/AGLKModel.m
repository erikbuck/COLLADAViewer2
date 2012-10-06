//
//  AGLKModel.m
//  COLLADAViewer2
//
//  Created by Erik Buck on 10/6/12.
//  Copyright (c) 2012 Erik Buck. All rights reserved.
//

#import "AGLKModel.h"
#import "AGLKMesh.h"

@interface AGLKModel ()

@property (strong, nonatomic, readwrite) AGLKMesh
   *mesh;
@property (strong, nonatomic, readwrite) NSNumber
   *numberOfVertices;
@property (assign, nonatomic, readwrite) NSUInteger
   indexOfFirstCommand;
@property (assign, nonatomic, readwrite) NSUInteger
   numberOfCommands;

- (NSNumber *)calculateNumberOfVertices;

@end


@implementation AGLKModel

@synthesize mesh;
@synthesize name;
@synthesize numberOfVertices;
@synthesize indexOfFirstCommand;
@synthesize numberOfCommands;


/////////////////////////////////////////////////////////////////
//
- (id)init
{
   self = nil;
   
   NSAssert(NO, @"Invalid initializer");
   return self;
}


/////////////////////////////////////////////////////////////////
//
- (id)initWithName:(NSString *)aName 
   mesh:(AGLKMesh *)aMesh
   indexOfFirstCommand:(NSUInteger)aFirstIndex
   numberOfCommands:(NSUInteger)count;
{
   NSParameterAssert(nil != aName);
   NSParameterAssert(nil != aMesh);
   NSParameterAssert(0 < count);
   
   if(nil != (self=[super init]))
   {
      self.mesh = aMesh;
      self.name = aName;
      self.indexOfFirstCommand = aFirstIndex;
      self.numberOfCommands = count;
      self.numberOfVertices = [self calculateNumberOfVertices];
   }
   
   return self;
}


/////////////////////////////////////////////////////////////////
//
- (id)initWithPlistRepresentation:(NSDictionary *)aDictionary
   mesh:(AGLKMesh *)aMesh;
{
   NSParameterAssert(nil != aMesh);
   
   NSString *aName = [aDictionary objectForKey:@"name"];
   NSNumber *aFirstIndex = 
      [aDictionary objectForKey:@"indexOfFirstCommand"];
   NSNumber *aNumberOfCommands = 
      [aDictionary objectForKey:@"numberOfCommands"];
   
   if(nil != aName && 
      nil != aFirstIndex && 
      nil != aNumberOfCommands &&
      0 < [aNumberOfCommands unsignedIntegerValue])
   {
      if(nil != (self = [self initWithName:aName
         mesh:aMesh
         indexOfFirstCommand:[aFirstIndex unsignedIntegerValue] 
         numberOfCommands:[aNumberOfCommands unsignedIntegerValue]]))
      {
         NSLog(@"<%@> Failed to initialize from pList.", aName);
      }
   }
   else
   {
      self = nil;
   }
   
   return self;
}


/////////////////////////////////////////////////////////////////
//
- (NSDictionary *)plistRepresentation;
{
   return [NSDictionary dictionaryWithObjectsAndKeys:
      self.name, 
         @"name", 
      [NSNumber numberWithUnsignedInteger:self.indexOfFirstCommand], 
      @"indexOfFirstCommand", 
      [NSNumber numberWithUnsignedInteger:self.numberOfCommands], 
      @"numberOfCommands", 
      [self axisAlignedBoundingBox], 
      @"axisAlignedBoundingBox", 
      nil];
}


/////////////////////////////////////////////////////////////////
//
- (NSNumber *)calculateNumberOfVertices;
{
   NSRange commandsRange = {
      self.indexOfFirstCommand, self.numberOfCommands};

   NSUInteger numberOfVerticesUsed = 
      [self.mesh numberOfVerticesForCommandsInRange:commandsRange];
   
   return [NSNumber numberWithUnsignedInteger:
      numberOfVerticesUsed];
}


/////////////////////////////////////////////////////////////////
//
- (NSString *)axisAlignedBoundingBox;
{
   NSRange commandsRange = {
      self.indexOfFirstCommand, self.numberOfCommands};
   
   return [self.mesh 
      axisAlignedBoundingBoxStringForCommandsInRange:
         commandsRange];
}

@end
