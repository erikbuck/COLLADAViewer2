//
//  AGLKMesh+viewAdditions.h
//  
//

#import "AGLKMesh.h"

@interface AGLKMesh (viewAdditions)

- (void)prepareToDraw;
- (void)prepareToPick;
- (void)drawAllCommands;
- (void)drawCommandsInRange:(NSRange)aRange;
- (void)drawBoundingBoxForCommandsInRange:
   (NSRange)aRange;
- (void)drawNormalsAllCommandsLength:(GLfloat)lineLength;
- (void)drawNormalsCommandsInRange:(NSRange)aRange
   length:(GLfloat)lineLength;

@end
