//
//  COLLADAParser+geometry.m
//  SPEditor
//
//  Created by Erik Buck on 9/29/12.
//  Copyright (c) 2012 Erik Buck. All rights reserved.
//

#import "COLLADAParser+geometry.h"
#import "COLLADAMeshGeometry.h"
#import "COLLADARoot.h"
#import "AGLKMesh.h"


/////////////////////////////////////////////////////////////////
//  
typedef struct
{
   GLushort positionIndex;
   GLushort normalIndex;
   GLushort texCoord0Index;
   GLushort texCoord1Index;
}
COLLADAIndexGroup;


/////////////////////////////////////////////////////////////////
//  
typedef struct
{
   const GLKVector3 *positionCoordsPtr;
   const GLKVector3 *normalCoordsPtr;
   const GLKVector2 *texCoord0Ptr;
   const GLKVector2 *texCoord1Ptr;
}
COLLADAVertexAttributePointers;


/////////////////////////////////////////////////////////////////
//  
@interface COLLADATrianglesInfo : NSObject

@property (retain, nonatomic) NSString *materialID;
@property (retain, nonatomic) NSString *vertexSourceID;
@property (retain, nonatomic) NSString *normalSourceID;
@property (retain, nonatomic) NSString *texCoordSourceID;
@property (assign, nonatomic) NSInteger positionOffset;
@property (assign, nonatomic) NSInteger normalOffset;
@property (assign, nonatomic) NSInteger texCoordOffset;
@property (retain, nonatomic) NSMutableData *indices;
@property (assign, nonatomic) NSInteger indexStridePerVertex;

- (NSUInteger)numberOfIndexGroups;
- (COLLADAIndexGroup)indexGroupAtIndex:(NSUInteger)anIndex;

@end


/////////////////////////////////////////////////////////////////
//  
@interface COLLADAVertexInfo : NSObject

@property (retain, nonatomic) NSString *verticesID;
@property (retain, nonatomic) NSString *positionSourceID;
@property (retain, nonatomic) NSString *normalSourceID;
@property (retain, nonatomic) NSString *texCoordSourceID;
@property (retain, nonatomic) NSString *vertexSourceID;

@end


/////////////////////////////////////////////////////////////////
//  
@interface COLLADASourceInfo : NSObject

@property (retain, nonatomic) NSData *floatData;
@property (copy, nonatomic) NSString *sourceID;
@property (assign, nonatomic) NSUInteger stride;

@end


@interface COLLADAMeshGeometry (parsing)

- (void)appendTriangles:(COLLADATrianglesInfo *)trianglesInfo
   sources:(NSDictionary *)sources
   vertices:(NSDictionary *)vertices;

@end


@implementation COLLADAParser (geometry)

/////////////////////////////////////////////////////////////////
//  
- (NSUInteger)extractStrideFromElement:(NSXMLElement *)element
{ // element is <source>
   NSUInteger result = 1;  // Default value
   
   NSArray *techniqueArrays = [element elementsForName:
      @"technique_common"];

   if(1 < [techniqueArrays count])
   {
      NSLog(@"More than one technique_common in source: %@",
         @"Extra data discarded.");
   }
   
   // element changed to <technique_common>
   element = [techniqueArrays lastObject];
   
   NSArray *accessorArrays = [element elementsForName:
      @"accessor"];

   if(1 < [accessorArrays count])
   {
      NSLog(@"More than one accessor in source: %@",
         @"Extra data discarded.");
   }
   
   // element changed to <accessor>
   element = [accessorArrays lastObject];
   
   NSXMLNode *strideNode = [element attributeForName:@"stride"];   
   NSString *strideString = [strideNode objectValue];
   
   if(nil == strideString)
   {
      NSLog(@"Unable to extract stride from source");
   }
   else
   {
      result = (NSUInteger)[strideString integerValue];
   }
   
   return result;
}


/////////////////////////////////////////////////////////////////
//  
- (NSData *)extractFloatArrayFromElement:(NSXMLElement *)element
{  // element is <source>
   NSArray *floatArrays = [element elementsForName:
      @"float_array"];

   if(1 < [floatArrays count])
   {
      NSLog(@"More than one float_array in source: %@",
         @"Extra data discarded.");
   }
   
   // element changed to <float_array>
   element = [floatArrays lastObject];
   
   NSArray *values = [[element stringValue] 
      componentsSeparatedByString:@" "];
   NSMutableData *floatData = [NSMutableData data];
      
   for(NSString *value in values)
   {
      float floatValue = [value floatValue];
      
      [floatData appendBytes:&floatValue 
         length:sizeof(floatValue)];
   }
   
   return floatData;
}


/////////////////////////////////////////////////////////////////
//  
- (COLLADASourceInfo *)extractSourceFromElement:
   (NSXMLElement *)source
{  // source is <source>
   COLLADASourceInfo *newSource = 
      [[COLLADASourceInfo alloc] init];

   // <source id=
   NSXMLNode *sourceIDNode = [source attributeForName:@"id"];   
   NSString *sourceIDString = [sourceIDNode objectValue];
   
   if(nil == sourceIDString)
   {
      NSLog(@"Unable to extract ID from <source>");
   }
   else
   {
      newSource.sourceID = sourceIDString;
   }

   // <float_array>
   NSData *floatData = [self extractFloatArrayFromElement:
      source];
   newSource.floatData = floatData;

   // <accessor stride=
   NSUInteger stride = [self extractStrideFromElement:
      source];
   NSAssert(0 < stride, @"Invalid souce stride");
   newSource.stride = stride;
   
   return newSource;
}


/////////////////////////////////////////////////////////////////
//  
- (COLLADAVertexInfo *)extractVertexInfoFromElement:
   (NSXMLElement *)vertexInfo
{  // source is <source>
   COLLADAVertexInfo *newVertexInfo = 
      [[COLLADAVertexInfo alloc] init];

   // <vertices id=
   NSXMLNode *verticesIDNode = 
      [vertexInfo attributeForName:@"id"];   
   NSString *verticesIDString = [verticesIDNode objectValue];
   
   if(nil == verticesIDString)
   {
      NSLog(@"Unable to extract ID from <vertices>");
   }
   else
   {
      newVertexInfo.verticesID = verticesIDString;
   }

   // <input>
   NSArray *inputs = [vertexInfo elementsForName:@"input"];
   for(NSXMLElement *input in inputs)
   {
      NSXMLNode *semanticNode = 
         [input attributeForName:@"semantic"];   
      NSString *semanticString = [semanticNode objectValue];
      NSXMLNode *sourceIDNode = 
         [input attributeForName:@"source"];   
      NSString *sourceIDString = [sourceIDNode objectValue];
      NSAssert(nil != sourceIDString && nil != semanticString,
          @"<vertices> missing essential attribtes.");
      
      if([@"POSITION" isEqualToString:semanticString])
      {
         newVertexInfo.positionSourceID = sourceIDString;
      }
      else if([@"NORMAL" isEqualToString:semanticString])
      {
         newVertexInfo.normalSourceID = sourceIDString;
      }
      else if([@"TEXCOORD" isEqualToString:semanticString])
      {
         newVertexInfo.texCoordSourceID = sourceIDString;
      }
      else if([@"VERTEX" isEqualToString:semanticString])
      {
         newVertexInfo.vertexSourceID = sourceIDString;
      }
      else
      {
         NSLog(@"Unrecognized <input semantic=>: %@",
            semanticString);
      }
   }
   
   return newVertexInfo;
}


/////////////////////////////////////////////////////////////////
//  
- (COLLADATrianglesInfo *)extractTrianglesInfoFromElement:
   (NSXMLElement *)triangle;
{  // source is <triangles>
   COLLADATrianglesInfo *newTriangleInfo = 
      [[COLLADATrianglesInfo alloc] init];

   NSXMLNode *materialIDNode = 
      [triangle attributeForName:@"material"];   
   NSString *materialIDString = [materialIDNode objectValue];
   newTriangleInfo.materialID = materialIDString;
   
   // <input>
   NSArray *inputs = [triangle elementsForName:@"input"];
   NSInteger maxInputIndexOffset = 0;

   for(NSXMLElement *input in inputs)
   {
      NSXMLNode *semanticNode = 
         [input attributeForName:@"semantic"];   
      NSString *semanticString = [semanticNode objectValue];
      NSXMLNode *sourceIDNode = 
         [input attributeForName:@"source"];   
      NSString *sourceIDString = [sourceIDNode objectValue];
      NSAssert(nil != sourceIDString && nil != semanticString,
          @"<triangles> missing essential attribtes.");
      NSXMLNode *offsetNode = 
         [input attributeForName:@"offset"];   
      NSString *offsetString = [offsetNode objectValue];
      
      NSInteger offesetIntegerValue =
         [offsetString integerValue];
      maxInputIndexOffset =
         MAX(offesetIntegerValue, maxInputIndexOffset);
      
      if([@"NORMAL" isEqualToString:semanticString])
      {
         newTriangleInfo.normalSourceID = sourceIDString;
         newTriangleInfo.normalOffset = 
            offesetIntegerValue;
      }
      else if([@"TEXCOORD" isEqualToString:semanticString])
      {
         newTriangleInfo.texCoordSourceID = sourceIDString;
         newTriangleInfo.texCoordOffset = 
            offesetIntegerValue;
      }
      else if([@"VERTEX" isEqualToString:semanticString])
      {
         newTriangleInfo.vertexSourceID = sourceIDString;
         newTriangleInfo.positionOffset = 
            offesetIntegerValue;
      }
      else
      {
         NSLog(@"Unrecognized <input semantic=>: %@",
            semanticString);
      }
   }
   
   // indexStridePerVertex is used to find indices for each vertex. The
   // indexStridePerVertex is NOT necessarily the same as the number of input
   // sources because some sources may share the same indices. For example, a
   // vertex my have three sources, (position, normal, and textCoord), but
   // only have an index stride of 2 because normal and texCoord always share
   // the same index.
   // The stride is therefore the maximum offset of all the sources plus 1
   // to account for the index at the maximum offset
   NSInteger maxOffset =
      MAX(newTriangleInfo.positionOffset,
         MAX(newTriangleInfo.normalOffset, newTriangleInfo.texCoordOffset));
   newTriangleInfo.indexStridePerVertex = maxOffset + 1;
   
   // <p>
   newTriangleInfo.indices = [NSMutableData data];
   NSArray *indices = [triangle elementsForName:@"p"];
   for(NSXMLElement *p in indices)
   {
      NSArray *values = [[p stringValue] 
         componentsSeparatedByString:@" "];
      
      for(NSString *value in values)
      {
         GLushort indexValue = (GLushort)[value intValue];
         
         [newTriangleInfo.indices appendBytes:&indexValue 
            length:sizeof(indexValue)];
      }
   }
   
   return newTriangleInfo;
}


/////////////////////////////////////////////////////////////////
// Only 3 sides polygons are supported so polylist is synonomous
// with triangles (hopefully!)
- (COLLADATrianglesInfo *)extractPolylistInfoFromElement:
   (NSXMLElement *)polylist;
{  // polylist is <polylist>
   COLLADATrianglesInfo *newTriangleInfo = 
      [[COLLADATrianglesInfo alloc] init];

   NSXMLNode *materialIDNode = 
      [polylist attributeForName:@"material"];   
   NSString *materialIDString = [materialIDNode objectValue];
   newTriangleInfo.materialID = materialIDString;
   newTriangleInfo.positionOffset = 0;
   newTriangleInfo.normalOffset = 0;
   newTriangleInfo.texCoordOffset = 0;
   
   // <input>
   NSArray *inputs = [polylist elementsForName:@"input"];
   for(NSXMLElement *input in inputs)
   {
      NSXMLNode *semanticNode = 
         [input attributeForName:@"semantic"];   
      NSString *semanticString = [semanticNode objectValue];
      NSXMLNode *sourceIDNode = 
         [input attributeForName:@"source"];   
      NSString *sourceIDString = [sourceIDNode objectValue];
      NSAssert(nil != sourceIDString && nil != semanticString,
          @"<polylist> missing essential attribtes.");
      NSXMLNode *offsetNode = 
         [input attributeForName:@"offset"];   
      NSString *offsetString = [offsetNode objectValue];
      
      if([@"NORMAL" isEqualToString:semanticString])
      {
         newTriangleInfo.normalSourceID = sourceIDString;
         newTriangleInfo.normalOffset = 
            [offsetString integerValue];
      }
      else if([@"TEXCOORD" isEqualToString:semanticString])
      {
         newTriangleInfo.texCoordSourceID = sourceIDString;
         newTriangleInfo.texCoordOffset = 
            [offsetString integerValue];
      }
      else if([@"VERTEX" isEqualToString:semanticString])
      {
         newTriangleInfo.vertexSourceID = sourceIDString;
         newTriangleInfo.positionOffset = 
            [offsetString integerValue];
      }
      else
      {
         NSLog(@"Unrecognized <input semantic=>: %@",
            semanticString);
      }
   }
   
   // <p>
   newTriangleInfo.indices = [NSMutableData data];
   NSArray *indices = [polylist elementsForName:@"p"];
   for(NSXMLElement *p in indices)
   {
      NSArray *values = [[p stringValue] 
         componentsSeparatedByString:@" "];

      for(NSString *value in values)
      {
         GLushort indexValue = (GLushort)[value intValue];
         
         [newTriangleInfo.indices appendBytes:&indexValue 
            length:sizeof(indexValue)];
      }
   }
   
   return newTriangleInfo;
}


/////////////////////////////////////////////////////////////////
//  
- (COLLADAMeshGeometry *)extractGeometryFromGeometryElement:
   (NSXMLElement *)element;
{  // element is <geometry>
   NSString *geometryID = [[element attributeForName:@"id"]
      objectValue];
   
   if(nil == geometryID)
   {
      NSLog(@"Geometry found without ID and can't be used.");
      return nil;
   }

   NSArray *meshes = [element elementsForName:@"mesh"];

   if(1 != meshes.count)
   {
      NSLog(@"Geometry found without mesh and can't be used.");
      return nil;
   }
   
   COLLADAMeshGeometry *meshGeometry =
      [[COLLADAMeshGeometry alloc] init];
   meshGeometry.uid = geometryID;
   
   NSXMLElement *mesh = [meshes lastObject];
   {  // mesh is <mesh>
      NSArray *sources = [mesh elementsForName:@"source"];
      NSArray *vertices = [mesh elementsForName:@"vertices"];
      NSArray *triangles = [mesh elementsForName:@"triangles"];
      NSArray *polylists = [mesh elementsForName:@"polylist"];
      NSArray *lines = [mesh elementsForName:@"lines"];
      NSMutableDictionary *mutableSourcesByID =
         [NSMutableDictionary dictionary];
      NSMutableDictionary *mutableVertexInfoByID =
         [NSMutableDictionary dictionary];
      COLLADATrianglesInfo *meshTrianglesInfo = nil;
      
      // Parse each <source>
      for(NSXMLElement *source in sources)
      {  // source is <source>
         COLLADASourceInfo *newSource = 
            [self extractSourceFromElement:source];
         NSAssert(nil != newSource && nil != newSource.sourceID,
            @"Invalid <source>");
               
         (mutableSourcesByID)[[@"#" stringByAppendingString:
            newSource.sourceID]] = newSource;
      }
      
      // Parse each <vertices> info element
      for(NSXMLElement *vertexInfo in vertices)
      {  // vertexInfo is <vertices>
         COLLADAVertexInfo *newVertexInfo = 
            [self extractVertexInfoFromElement:vertexInfo];
         NSAssert(nil != newVertexInfo && 
            nil != newVertexInfo.verticesID,
            @"Invalid <source>");
         
         (mutableVertexInfoByID)[[@"#" stringByAppendingString:
               newVertexInfo.verticesID]] = newVertexInfo;
      }
      
      if(nil != triangles && 0 < [triangles count])
      {
         // Parse each <triangles> element
         for(NSXMLElement *triangle in triangles)
         { // triangle is <triangles>
            meshTrianglesInfo = 
               [self extractTrianglesInfoFromElement:triangle];
            NSAssert(nil != meshTrianglesInfo,
               @"Invalid <triangles>");
            
            [meshGeometry appendTriangles:meshTrianglesInfo
               sources:mutableSourcesByID
               vertices:mutableVertexInfoByID];
         }
      }      
      else if(nil != polylists && 0 < [polylists count])
      {
         // Parse each <polylist> element
         for(NSXMLElement *polylist in polylists)
         { // polylist is <polylist>
            meshTrianglesInfo = 
               [self extractTrianglesInfoFromElement:polylist];
            NSAssert(nil != meshTrianglesInfo,
               @"Invalid <triangles>");
            
            [meshGeometry appendTriangles:meshTrianglesInfo
               sources:mutableSourcesByID
               vertices:mutableVertexInfoByID];
         }
      }
      else if(nil != lines && 0 < [lines count])
      { // Lines currently ignored
//         NSLog(@"Geometry <lines> ignored");
      }
      else
      {
         NSLog(@"Mesh has niether <triangles> nor <polylist>");
      }      
   } // <mesh>
   
   return meshGeometry;
}

@end


@implementation COLLADAMeshGeometry (parsing)

/////////////////////////////////////////////////////////////////
//  
- (void)appendTriangles:(COLLADATrianglesInfo *)trianglesInfo
   sources:(NSDictionary *)sources
   vertices:(NSDictionary *)vertices;
{
   if(nil == trianglesInfo.vertexSourceID ||
      nil == sources ||
      nil == vertices)
   {
      NSLog(@"No vertex source available.");
      return;
   }

   // Get the vertex positions source and by default get the 
   // other attributes from the same source
   COLLADAVertexInfo *positionVertexInfo = 
      (vertices)[trianglesInfo.vertexSourceID];
   COLLADAVertexInfo *normalVertexInfo = positionVertexInfo;
   COLLADAVertexInfo *texCoordVertexInfo = positionVertexInfo;
   COLLADASourceInfo *positionSource = nil;
   COLLADASourceInfo *normalSource = nil;
   COLLADASourceInfo *texCoordSource = nil;
   
   if(nil == positionVertexInfo)
   {
      NSLog(@"No vertex position available.");
      return;
   }

   positionSource = (sources)[positionVertexInfo.positionSourceID];
   
   if(nil != trianglesInfo.normalSourceID)
   {  // Override source for normals
      normalVertexInfo = (vertices)[trianglesInfo.normalSourceID];
      if(nil != normalVertexInfo)
      {  // There was a <vertices> for this attribute
         normalSource = (sources)[normalVertexInfo.normalSourceID];
      }
      else
      {  // There was no <vertices> so try accessing source 
         // directly
         normalSource = (sources)[trianglesInfo.normalSourceID];
      }
   }
   else
   {
      normalSource = (sources)[normalVertexInfo.normalSourceID];
   }
   
   if(nil != trianglesInfo.texCoordSourceID)
   {  // Override source for texCoords
      texCoordVertexInfo = (vertices)[trianglesInfo.texCoordSourceID];
      if(nil != texCoordVertexInfo)
      {  // There was a <vertices> for this attribute
         texCoordSource = (sources)[texCoordVertexInfo.texCoordSourceID];
      }
      else
      {  // There was no <vertices> so try accessing source 
         // directly
         texCoordSource = (sources)[trianglesInfo.texCoordSourceID];
      }
   }
   else
   {
      texCoordSource = (sources)[texCoordVertexInfo.texCoordSourceID];
   }
      
   if(nil == positionSource)
   {  //Last ditch: look for position in VERTEX element
      positionSource = (sources)[positionVertexInfo.vertexSourceID];
   } 
   
   if(nil == positionSource)
   {
      NSLog(@"No source for vertex positions.");
      return;
   }

   AGLKMesh *mesh = self.mesh;
   NSAssert(nil != mesh, @"Invalid mesh");
   
   // Save index for future command  
   const NSUInteger firstIndex =
      mesh.numberOfIndices;

   //Initialize the pointers to vertex attribute data
   COLLADAVertexAttributePointers pointers;
   pointers.positionCoordsPtr = 
      (GLKVector3 *)[positionSource.floatData bytes];
   pointers.normalCoordsPtr = 
      (GLKVector3 *)[normalSource.floatData bytes];
   pointers.texCoord0Ptr = 
      (GLKVector2 *)[texCoordSource.floatData bytes];
   pointers.texCoord1Ptr = NULL;

   const NSUInteger numberOfIndexGroups =
      [trianglesInfo numberOfIndexGroups];
      
   for(NSUInteger i = 0; i < numberOfIndexGroups; i++)
   {  // for each index group
      COLLADAIndexGroup indexGroup =
         [trianglesInfo indexGroupAtIndex:i];
   
      // Append corresponding vertex attributes
      GLushort currentIndex = [self appendIndexGroup:indexGroup
         attributePointers:pointers];
      [self.mesh appendIndex:currentIndex];
   }
   
   // Add command to draw the triangles just added 
   [self.mesh appendCommand:GL_TRIANGLES 
      firstIndex:firstIndex
      numberOfIndices:(mesh.numberOfIndices - firstIndex)
      materialName:trianglesInfo.materialID];
}


- (GLushort)appendIndexGroup:(COLLADAIndexGroup)anIndexGroup
   attributePointers:(COLLADAVertexAttributePointers)pointers;
{
   NSParameterAssert(NULL != pointers.positionCoordsPtr);
   
   AGLKMesh *mesh = self.mesh;
   NSAssert(nil != mesh, @"Invalid mesh");
   
   // Save index for future command  
   NSUInteger currentIndex =
      mesh.numberOfIndices;

   if(currentIndex >= 0xFFFF)
   {
      NSLog(@"Attempt to overflow 16 bit index range: %@",
         @"vertex data discarded");
      return currentIndex;
   }
   else
   {
      // Initialize the new vertex attributes from separate
      // arrays using separate indices
      AGLKMeshVertex newVertex;
      newVertex.position.x = NAN;
      newVertex.position.y = NAN;
      newVertex.position.z = NAN;
      newVertex.normal.x = NAN;
      newVertex.normal.y = NAN;
      newVertex.normal.z = NAN;
      newVertex.texCoords0.x = 0;
      newVertex.texCoords0.y = 0;
      newVertex.texCoords1.x = 0;
      newVertex.texCoords1.y = 0;
      
      {  // Store position
         GLKVector3 position = 
            pointers.positionCoordsPtr[anIndexGroup.positionIndex];
               
         newVertex.position = position;
      }
      
      if(NULL != pointers.normalCoordsPtr)
      {
         // Store normal vector (renormalize just in case)
         GLKVector3 normal =
            pointers.normalCoordsPtr[anIndexGroup.normalIndex];
            
         newVertex.normal = GLKVector3Normalize(normal);
      }
      if(NULL != pointers.texCoord0Ptr)
      {
         newVertex.texCoords0 = 
            pointers.texCoord0Ptr[anIndexGroup.texCoord0Index];
      }
      if(NULL != pointers.texCoord1Ptr)
      {
         newVertex.texCoords1 = 
            pointers.texCoord1Ptr[anIndexGroup.texCoord1Index];
      }
      
      // Add the new combination of vertex attributes to the mesh
      [self.mesh appendVertex:newVertex];
   }
   
   return currentIndex;
}

@end


/////////////////////////////////////////////////////////////////
//  
@implementation COLLADATrianglesInfo

- (NSUInteger)numberOfIndexGroups;
{
   NSAssert(0 < self.indexStridePerVertex, @"No sources for index groups");
   return [self.indices length] / (self.indexStridePerVertex * sizeof(GLushort));
}


- (COLLADAIndexGroup)indexGroupAtIndex:(NSUInteger)anIndex;
{
   NSAssert(anIndex < [self numberOfIndexGroups],
      @"Index out of range");
   GLushort *indexPtr = (GLushort *)[self.indices bytes];
   indexPtr += (anIndex * self.indexStridePerVertex);
//   indexPtr += (anIndex * (maxOffset + 1));
   NSAssert(self.indices.length >
      (sizeof(GLushort) * (anIndex * self.indexStridePerVertex)),
      @"Pointer out of range");
   
   COLLADAIndexGroup result;
   result.positionIndex = indexPtr[self.positionOffset];
   result.normalIndex = indexPtr[self.normalOffset];
   result.texCoord0Index = indexPtr[self.texCoordOffset];
   result.texCoord1Index = 0;
   
   return result;
}

@end


/////////////////////////////////////////////////////////////////
//  
@implementation COLLADAVertexInfo

@end


/////////////////////////////////////////////////////////////////
//  
@implementation COLLADASourceInfo


@end
