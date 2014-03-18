//
//  AGLKMesh.m
//  
//

#import "AGLKMesh+viewAdditions.h"

#undef __gl_h_
#import <GLKit/GLKit.h>


@implementation AGLKMesh (viewAdditions)

- (void)deleteGLResources;
{
   glBindVertexArray(0);
   glBindBuffer(GL_ARRAY_BUFFER, 0);
   glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
   
   if(0 != vertexArrayID_)
   {
      glDeleteVertexArrays(1, &vertexArrayID_);
      vertexArrayID_ = 0;
   }
   
   if(0 != vertexBufferID_)
   {
      glDeleteBuffers(1, &vertexBufferID_);
      vertexBufferID_ = 0;
   }

   if(0 != vertexExtraBufferID_)
   {
      glDeleteBuffers(1, &vertexExtraBufferID_);
      vertexExtraBufferID_ = 0;
   }

   if(0 != indexBufferID_)
   {
      glDeleteBuffers(1, &indexBufferID_);
      indexBufferID_ = 0;
   }
}


/////////////////////////////////////////////////////////////////
// This method prepares the current OpenGL ES 2.0 context for
// drawing with the receiver's vertex attributes and indices.
- (void)prepareToDraw;
{
   if(0 != vertexArrayID_)
   {
      glBindVertexArray(vertexArrayID_);
   }
   else if(0 < [self.vertexData length])
   {
      if(self.shouldUseVAOExtension)
      {
         glGenVertexArrays(1, &vertexArrayID_);
         NSAssert(0 != vertexArrayID_, @"Unable to create VAO");
         glBindVertexArray(vertexArrayID_);
      }
      
      if(0 == vertexBufferID_)
      {  // Vertices haven't been sent to GPU yet
         // Create an element array buffer for mesh indices
         glGenBuffers(1, &vertexBufferID_);
         NSAssert(0 != vertexBufferID_, 
            @"Failed to generate vertex array buffer");
             
         glBindBuffer(GL_ARRAY_BUFFER, vertexBufferID_);
         glBufferData(GL_ARRAY_BUFFER, 
            [self.vertexData length], 
            [self.vertexData bytes], 
            GL_STATIC_DRAW);      
      }
      else
      {
         glBindBuffer(GL_ARRAY_BUFFER, vertexBufferID_);
      }

      // Set pointers
      glEnableVertexAttribArray(GLKVertexAttribPosition); 
      glVertexAttribPointer(
         GLKVertexAttribPosition,
         3, 
         GL_FLOAT,
         GL_FALSE, 
         sizeof(AGLKMeshVertex), 
         (GLbyte *)NULL + 
            offsetof(AGLKMeshVertex, position));
      
      glEnableVertexAttribArray(GLKVertexAttribNormal); 
      glVertexAttribPointer(
         GLKVertexAttribNormal,
         3, 
         GL_FLOAT,
         GL_FALSE, 
         sizeof(AGLKMeshVertex), 
         (GLbyte *)NULL + 
            offsetof(AGLKMeshVertex, normal));
      
      glEnableVertexAttribArray(GLKVertexAttribTexCoord0); 
      glVertexAttribPointer(
         GLKVertexAttribTexCoord0,
         2,
         GL_FLOAT, 
         GL_FALSE, 
         sizeof(AGLKMeshVertex), 
         (GLbyte *)NULL + 
            offsetof(AGLKMeshVertex, texCoords0));

      glEnableVertexAttribArray(GLKVertexAttribTexCoord1); 
      glVertexAttribPointer(
         GLKVertexAttribTexCoord1,
         2,
         GL_FLOAT, 
         GL_FALSE, 
         sizeof(AGLKMeshVertex), 
         (GLbyte *)NULL + 
            offsetof(AGLKMeshVertex, texCoords1));
   }

   if(0 != indexBufferID_)
   {
      glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBufferID_);
   }   
   else if(0 < [self.indexData length])
   {  // Indices haven't been sent to GPU yet
      // Create an element array buffer for mesh indices
      glGenBuffers(1, &indexBufferID_);
      NSAssert(0 != indexBufferID_, 
         @"Failed to generate element array buffer");
          
      glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 
         indexBufferID_);
      glBufferData(GL_ELEMENT_ARRAY_BUFFER, 
         [self.indexData length], 
         [self.indexData bytes], 
         GL_STATIC_DRAW);      
   }
}


/////////////////////////////////////////////////////////////////
// This method prepares the current OpenGL ES 2.0 context for
// picking with the receiver's vertex attributes and indices.
- (void)prepareToPick;
{
   if(0 == vertexBufferID_ && 0 < [self.vertexData length])
   {  // Vertices haven't been sent to GPU yet
      // Create an element array buffer for mesh indices
      glGenBuffers(1, &vertexBufferID_);
      NSAssert(0 != vertexBufferID_, 
         @"Failed to generate vertex array buffer");
          
      glBindBuffer(GL_ARRAY_BUFFER, vertexBufferID_);
      glBufferData(GL_ARRAY_BUFFER, 
         [self.vertexData length], 
         [self.vertexData bytes], 
         GL_STATIC_DRAW);      
   }
   else
   {
      glBindBuffer(GL_ARRAY_BUFFER, vertexBufferID_);
   }

   // Set pointers
   glEnableVertexAttribArray(GLKVertexAttribPosition); 
   glVertexAttribPointer(
      GLKVertexAttribPosition,
      3, 
      GL_FLOAT,
      GL_FALSE, 
      sizeof(AGLKMeshVertex), 
      (GLbyte *)NULL + 
         offsetof(AGLKMeshVertex, position));
   
   glDisableVertexAttribArray(GLKVertexAttribNormal); 
   glDisableVertexAttribArray(GLKVertexAttribTexCoord0); 

   if(0 == indexBufferID_ && 0 < [self.indexData length])
   {  // Indices haven't been sent to GPU yet
      // Create an element array buffer for mesh indices
      glGenBuffers(1, &indexBufferID_);
      NSAssert(0 != indexBufferID_, 
         @"Failed to generate element array buffer");
          
      glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, vertexBufferID_);
      glBufferData(GL_ELEMENT_ARRAY_BUFFER, 
         [self.indexData length], 
         [self.indexData bytes], 
         GL_STATIC_DRAW);      
   }
   else
   {
      glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, vertexBufferID_);
   }
}


/////////////////////////////////////////////////////////////////
//
- (void)drawAllCommands;
{
   NSRange allCommandsRange = {0, [self.commands count]};
   
   [self drawCommandsInRange:allCommandsRange];
}


/////////////////////////////////////////////////////////////////
// After the receiver has been prepared for drawing or picking, 
// call this method to draw the portions of the mesh described
// by the specified range of the receiver's commands.
- (void)drawCommandsInRange:(NSRange)aRange;
{
   if(0 < aRange.length)
   {
      const NSUInteger lastCommandIndex = 
         (aRange.location + aRange.length) - 1;

      NSParameterAssert(aRange.location < [self.commands count]);
      NSParameterAssert(lastCommandIndex < [self.commands count]);

      for(NSUInteger i = aRange.location; 
         i <= lastCommandIndex; i++)
      {
         NSDictionary *currentCommand = 
            [self.commands objectAtIndex:i];
         const GLsizei  numberOfIndices = (GLsizei)[[currentCommand 
            objectForKey:@"numberOfIndices"] 
            unsignedIntegerValue];
         const GLsizei  firstIndex = (GLsizei)[[currentCommand 
            objectForKey:@"firstIndex"] unsignedIntegerValue];
         GLenum mode = (GLenum)[[currentCommand 
            objectForKey:@"command"] unsignedIntegerValue];
           
         glDrawElements(mode,
            (GLsizei)numberOfIndices,
            GL_UNSIGNED_SHORT,
            ((GLushort *)NULL + firstIndex));      
      }
   }
}


/////////////////////////////////////////////////////////////////
//
- (void)drawNormalsCommandsInRange:(NSRange)aRange
   length:(GLfloat)lineLength;
{
   if(0 < aRange.length)
   {
      const NSUInteger lastCommandIndex = 
         (aRange.location + aRange.length) - 1;
      const NSUInteger numberOfCommands = 
         [self.commands count];

      NSParameterAssert(aRange.location < numberOfCommands);
      NSParameterAssert(lastCommandIndex < numberOfCommands);

      AGLKMeshVertex *vertexAttributes = (AGLKMeshVertex *)
         [self.vertexData bytes];
               
      glDisable(GL_TEXTURE_2D);
      
      glDisableVertexAttribArray(GLKVertexAttribPosition);
      glDisableVertexAttribArray(GLKVertexAttribNormal);
      glDisableVertexAttribArray(GLKVertexAttribTexCoord0);
      
      for(NSUInteger i = aRange.location; 
         i <= lastCommandIndex; i++)
      {
         NSDictionary *currentCommand = 
            [self.commands objectAtIndex:i];
         size_t  numberOfIndices = (size_t)[[currentCommand 
            objectForKey:@"numberOfIndices"] unsignedIntegerValue];
         size_t  firstIndex = (size_t)[[currentCommand 
            objectForKey:@"firstIndex"] unsignedIntegerValue];
         GLushort *indices = (GLushort *)
            [self.indexData bytes];
        
         for(int j = 0; j < numberOfIndices; j++)
         {
            GLushort  index = indices[j + firstIndex];
            AGLKMeshVertex currentVertex = vertexAttributes[index];
            GLfloat   vertexBuffer[6];
            
            vertexBuffer[0] = currentVertex.position.x;
            vertexBuffer[1] = currentVertex.position.y;
            vertexBuffer[2] = currentVertex.position.z;
            vertexBuffer[3] = vertexBuffer[0] + 
               (lineLength * currentVertex.normal.x);
            vertexBuffer[4] = vertexBuffer[1] + 
               (lineLength * currentVertex.normal.y);
            vertexBuffer[5] = vertexBuffer[2] + 
               (lineLength * currentVertex.normal.z);
            
            glEnableVertexAttribArray(GLKVertexAttribPosition);
            glVertexAttribIPointer(GLKVertexAttribPosition,
               3 * sizeof(GLfloat),
               GL_FLOAT, 
               3 * sizeof(GLfloat), 
               vertexBuffer);
            glDrawArrays(GL_LINES, 0, 2);
         }
      }
   }
}


/////////////////////////////////////////////////////////////////
//
- (void)drawNormalsAllCommandsLength:(GLfloat)lineLength
{
   NSRange allCommandsRange = {0, [self.commands count]};
   
   [self drawNormalsCommandsInRange:allCommandsRange
      length:lineLength];
}


/////////////////////////////////////////////////////////////////
// After the receiver has been prepared for drawing, 
// call this method to draw lines defining a box containing
// all portions of the mesh described by the specified range of 
// the receiver's commands. This provides a quick visual way to 
// see the volume occupied by portions of the mesh.
- (void)drawBoundingBoxForCommandsInRange:
   (NSRange)aRange;
{
   if(0 < aRange.length)
   {
      const NSUInteger lastCommandIndex = 
         (aRange.location + aRange.length) - 1;

      NSParameterAssert(aRange.location < [self.commands count]);
      NSParameterAssert(lastCommandIndex < [self.commands count]);

      const GLushort *indices = (const GLushort *)
         [self.indexData bytes];
                
      for(NSUInteger i = aRange.location; 
         i <= lastCommandIndex; i++)
      {
         NSDictionary *currentCommand = 
            [self.commands objectAtIndex:i];
         size_t  numberOfIndices = (size_t)[[currentCommand 
            objectForKey:AGLKMeshCommandNumberOfIndices] 
            unsignedIntegerValue];
         size_t  firstIndex = (size_t)[[currentCommand 
            objectForKey:AGLKMeshCommandFirstIndex] 
               unsignedIntegerValue];
           
         glDrawElements(
            GL_LINE_STRIP,
            (GLsizei)numberOfIndices,
            GL_UNSIGNED_SHORT,
            indices + firstIndex);      
      }
   }
}

@end
