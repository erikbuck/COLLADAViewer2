//
//  AGLKEffect.h
//  SPEditor
//
//  Created by Erik Buck on 9/11/12.
//  Copyright (c) 2012 Erik Buck. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKMath.h>

/////////////////////////////////////////////////////////////////
// This type identifies the vertex attributes used to render 
// models, terrain, and billboard particles. Not all effects use
// all attributes.
typedef enum
{
   AGLKVertexAttribPosition, // == GLKVertexAttribPosition
   AGLKVertexAttribNormal, // == GLKVertexAttribNormal,
   AGLKVertexAttribColor, // == GLKVertexAttribColor,
   AGLKVertexAttribTexCoord0, // == GLKVertexAttribTexCoord0,
   AGLKVertexAttribTexCoord1, // == GLKVertexAttribTexCoord1,
   AGLKVertexAttribOpacity,
   AGLKVertexAttribJointMatrixIndices,
   AGLKVertexAttribJointNormalizedWeights,
   AGLKVertexNumberOfAttributes,
} AGLKVertexAttribute;


@class GLKEffectPropertyTransform;
@class GLKEffectPropertyLight;
@class GLKEffectPropertyTexture;


@protocol AGLKNamedEffect

@required
- (void) prepareToDraw;

@end


@interface AGLKEffect : NSObject
<AGLKNamedEffect>

@property (assign, nonatomic, readonly)
GLuint program;
           
@property (nonatomic, readonly)
GLKEffectPropertyTransform *transform;

@property (nonatomic, readonly)
GLKEffectPropertyLight *light0; 

@property (nonatomic, assign)
GLKVector4 lightModelAmbientColor; 

@property (nonatomic, readonly)
GLKEffectPropertyTexture *texture2d0;

@property (nonatomic, readonly)
GLKEffectPropertyTexture *texture2d1;

@property (nonatomic, copy)
NSString *label;              

- (void)prepareOpenGL;
- (void)updateUniformValues;

// Required overrides
- (void)bindAttribLocations;
- (void)configureUniformLocations;

- (BOOL)loadShadersWithName:(NSString *)aShaderName;

@end
