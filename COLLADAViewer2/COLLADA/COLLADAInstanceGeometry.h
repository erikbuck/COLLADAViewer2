//
//  COLLADAInstanceGeometry.h
//  COLLADAViewer2
//
//  Created by Erik Buck on 9/30/12.
//  Copyright (c) 2012 Erik Buck. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "COLLADAInstance.h"

@class COLLADABindMaterial;
@class COLLADARoot;
@class COLLADAImagePath;


@interface COLLADAInstanceGeometry : COLLADAInstance

@property (nonatomic, retain)
   NSSet *bindMaterials;

//@property (nonatomic, strong)
//   GLKTextureInfo *textureInfo;


- (COLLADAImagePath *)imagePathForMaterialBinding:
   (COLLADAInstance *)bindMaterial
   root:(COLLADARoot *)aRoot;

@end
