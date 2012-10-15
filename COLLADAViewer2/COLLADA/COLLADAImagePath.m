//
//  COLLADAImagePath.m
//  COLLADAViewer2
//
//  Created by Erik Buck on 9/30/12.
//  Copyright (c) 2012 Erik Buck. All rights reserved.
//

#import "COLLADAImagePath.h"

@interface COLLADAImagePath ()
{
   md5_byte_t _digest[16];
}

@end


@implementation COLLADAImagePath

/////////////////////////////////////////////////////////////////
//
- (id)init
{
    self = [super init];
    if (self)
    {
       self.textureTransform = GLKMatrix4Identity;
    }
   
    return self;
}


/////////////////////////////////////////////////////////////////
//
- (NSDictionary *)plistRepresentation
{
   return [NSDictionary dictionaryWithObjectsAndKeys:
      [self.image TIFFRepresentation],
      @"imageData", 
      [NSNumber numberWithUnsignedInteger:self.image.size.width],
      @"width", 
      [NSNumber numberWithUnsignedInteger:self.image.size.height],
      @"height", 
      nil];
}


/////////////////////////////////////////////////////////////////
//
- (const md5_byte_t *)digest
{
   return _digest;
}


/////////////////////////////////////////////////////////////////
//
- (void)updateDigest;
{
   NSData *imageData = [self.image TIFFRepresentation];
   
   if(nil != imageData)
   {
      md5_state_t pms;
      
      md5_init(&pms);
      md5_append(&pms, (const md5_byte_t *)[imageData bytes],
         (int)[imageData length]);
      md5_finish(&pms, _digest);
   }
}


/////////////////////////////////////////////////////////////////
// If the receiver has loaded image data, the hash is based on
// the loaded image data. Otherwise, the superclass hash
// is returned.
- (NSUInteger)hash;
{
   if(nil == self.image)
   {  // Image is not initialized yet
      return [super hash];
   }
   
   if(_digest[0] == 0 &&
      _digest[1] == 0 &&
      _digest[2] == 0 &&
      _digest[3] == 0)
   {  // Digest is not initialized yet
      [self updateDigest];
   }

   // Base hash on digest
   NSUInteger result =
      (((NSUInteger)_digest[0]) << 24) |
      (((NSUInteger)_digest[1]) << 16) |
      (((NSUInteger)_digest[2]) << 8) |
      (((NSUInteger)_digest[3]) << 0);
   
   return result;
}


/////////////////////////////////////////////////////////////////
// If the receiver and "object" have identical image data then
// the receiver and "object" equal.
// If the receiver's image data has not been initailized, this
// method returns [super isEqual:object]
- (BOOL)isEqual:(COLLADAImagePath *)object;
{
   BOOL result = NO;
   
   if(nil == self.image)
   {  // Image is not initialized yet
      result = [super isEqual:object];
   }
   else if(self == object)
   {  // We are the same object so equal
      result = YES;
   }
   else if([self hash] == [object hash])
   {  // We have the same hash so MAY be equal
      if([object isKindOfClass:[self class]] &&
         _digest[0] == object->_digest[0] &&
         _digest[1] == object->_digest[1] &&
         _digest[2] == object->_digest[2] &&
         _digest[3] == object->_digest[3] &&
         _digest[4] == object->_digest[4] &&
         _digest[5] == object->_digest[5] &&
         _digest[6] == object->_digest[6] &&
         _digest[7] == object->_digest[7] &&
         _digest[8] == object->_digest[8] &&
         _digest[9] == object->_digest[9] &&
         _digest[10] == object->_digest[10] &&
         _digest[11] == object->_digest[11] &&
         _digest[12] == object->_digest[12] &&
         _digest[13] == object->_digest[13] &&
         _digest[14] == object->_digest[14] &&
         _digest[15] == object->_digest[15])
      {  // Our digests equal
         result = YES;
      }
   }

   return result;
}

@end
