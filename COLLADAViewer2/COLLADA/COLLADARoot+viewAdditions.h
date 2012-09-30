//
//  COLLADARoot+viewAdditions.h
//  SPEditor
//
//  Created by Erik Buck on 9/29/12.
//  Copyright (c) 2012 Erik Buck. All rights reserved.
//

#import "COLLADARoot.h"

@class AGLKEffect;


@interface COLLADARoot (viewAdditions)

- (void)prepareToDrawWithEffect:(AGLKEffect *)anEffect;
- (void)drawWithEffect:(AGLKEffect *)anEffect;

@end
