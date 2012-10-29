//
//  COLLADAParser+geometry.h
//  SPEditor
//
//  Created by Erik Buck on 9/29/12.
//  Copyright (c) 2012 Erik Buck. All rights reserved.
//

#import "COLLADAParser.h"

@class COLLADAGeometry;


@interface COLLADAParser (geometry) 

- (COLLADAGeometry *)extractGeometryFromGeometryElement:
   (NSXMLElement *)element;

@end


@interface NSXMLNode (COLLADAParser)

- (NSString *)trimmedStringValue;

@end
