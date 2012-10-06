//
//  AGLKMesh.h
//  
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKMath.h>
#import "AGLKAxisAllignedBoundingBox.h"

@class GLKTextureInfo;


#define AGLKMeshMaximumNumberOfVertices (65535)

/////////////////////////////////////////////////////////////////
// Type used to store mesh vertex attribues
typedef struct
{
   GLKVector3 position;
   GLKVector3 normal;
   GLKVector2 texCoords0;
   GLKVector2 texCoords1;
}
AGLKMeshVertex;


@interface AGLKMesh : NSObject
<NSCoding>
{
   GLuint indexBufferID_;
   GLuint vertexBufferID_;
   GLuint vertexExtraBufferID_;
   GLuint vertexArrayID_;
}

@property (strong, nonatomic, readonly) NSData
   *vertexData;
@property (strong, nonatomic, readonly) NSData
   *indexData;
@property (strong, nonatomic, readonly) NSMutableData
   *extraVertexData;
@property (assign, nonatomic, readonly) NSUInteger
   numberOfIndices;
@property (assign, nonatomic, readonly) NSUInteger
   numberOfVertices;
@property (strong, nonatomic, readonly) NSArray
   *commands;
@property (strong, nonatomic, readonly) NSDictionary
   *plistRepresentation;
@property (copy, nonatomic, readonly) NSString
   *axisAlignedBoundingBoxString;
@property (assign, nonatomic, readwrite) BOOL
   shouldUseVAOExtension;

- (id)initWithPlistRepresentation:(NSDictionary *)aDictionary;

- (AGLKMeshVertex)vertexAtIndex:(NSUInteger)anIndex;
- (GLushort)indexAtIndex:(NSUInteger)anIndex;

- (AGLKAxisAllignedBoundingBox)axisAlignedBoundingBoxForCommandsInRange:
   (NSRange)aRange;

- (NSString *)axisAlignedBoundingBoxStringForCommandsInRange:
   (NSRange)aRange;

- (id)copyWithTransform:(GLKMatrix4)transforms
   textureTransform:(GLKMatrix3)textureTransform;
- (void)appendVertex:(AGLKMeshVertex)aVertex;
- (void)appendIndex:(GLushort)index;
- (void)appendCommand:(GLenum)command 
   firstIndex:(size_t)firstIndex
   numberOfIndices:(size_t)numberOfIndices
   materialName:(NSString *)materialName;
- (void)appendMesh:(AGLKMesh *)aMesh;

- (BOOL)canAppendMesh:(AGLKMesh *)aMesh;

- (NSUInteger)numberOfVerticesForCommandsInRange:(NSRange)aRange;

@end

/////////////////////////////////////////////////////////////////
// Constants used to access properties from a drawing
// command dictionary.
extern NSString *const AGLKMeshCommandNumberOfIndices;
extern NSString *const AGLKMeshCommandFirstIndex;
