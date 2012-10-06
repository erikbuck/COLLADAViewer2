//
//  COLLADARoot+modelConsolidation.h
//  COLLADAViewer2
//
//  Created by Erik Buck on 10/5/12.
//  Copyright (c) 2012 Erik Buck. All rights reserved.
//

#import "COLLADARoot.h"

@class AGLKModel;
@class AGLKMesh;

@interface COLLADARoot (modelConsolidation)

- (AGLKModel *)consolidatedModelWithMesh:(AGLKMesh *)consolidatedMesh;

@end
