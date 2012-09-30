//
//  COLLADAMeshGeometry.h
//  COLLADAViewer2
//
//  Created by Erik Buck on 9/30/12.
//  Copyright (c) 2012 Erik Buck. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "COLLADAResource.h"

@class AGLKMesh;


@interface COLLADAMeshGeometry : COLLADAResource

@property (nonatomic, retain) AGLKMesh *mesh;

@end
