//
//  COLLADAParser.m
//  COLLADAViewer
//

#import "COLLADAParser.h"
#import "COLLADAParser+geometry.h"
#import "COLLADARoot.h"
#import "COLLADAImagePath.h"
#import "COLLADAInstanceGeometry.h"
#import "COLLADANode.h"
#import "COLLADAInstanceGeometry.h"
#import "COLLADAEffect.h"
#import "AGLKMesh.h"
#import <GLKit/GLKMath.h>


/////////////////////////////////////////////////////////////////
//
static const float COLLADAParserMetersPerInch = 0.0254f;


@implementation COLLADAParser

@synthesize root = _root;


/////////////////////////////////////////////////////////////////
//
- (COLLADARoot *)root;
{
   if(nil == _root)
   {
      _root = [[COLLADARoot alloc] init];
   }
   
   return _root;
}


#pragma mark - asset Element

/////////////////////////////////////////////////////////////////
// This method sets the roots's axisCorrectionMatrix property
// based on element or a defualt value if neccessary. 
- (void)extractUpAxisFromAssetElement:(NSXMLElement *)element
{
   NSArray *upAxisElements = 
   [element elementsForName:@"up_axis"];
   NSString *elementValue = 
   [[upAxisElements lastObject] stringValue];
   
   if([@"X_UP" isEqualToString:elementValue])
   {  // Rotate 90 deg about Z
      self.root.transform =
         GLKMatrix4Rotate(
            self.root.transform,
            M_PI/2.0f,
            0.0f,
            0.0f,
            1.0f);
   }
   else if([@"Y_UP" isEqualToString:elementValue])
   {  // Nothing required for this case
   }
   else 
   {  // Assume Z_UP: Rotate -90 deg about X
      self.root.transform =
         GLKMatrix4Rotate(
            self.root.transform,
            -M_PI/2.0f,
            1.0f,
            0.0f,
            0.0f);
   }
}


/////////////////////////////////////////////////////////////////
// This method sets the root's axisCorrectionMatrix property
// based on element or a defualt value if neccessary. 
- (void)extractUnitFromAssetElement:(NSXMLElement *)element
{
   NSArray *unitElements = 
   [element elementsForName:@"unit"];
   
   NSXMLElement *unit = [unitElements lastObject];
   NSXMLNode *meterNode = [unit attributeForName:@"meter"];
   NSString *metersPerUnit = [meterNode objectValue];
   
   if(nil != metersPerUnit && 0.0f < [metersPerUnit floatValue])
   {
      float metersPerUnitFactor = [metersPerUnit floatValue];
      
      self.root.transform = 
         GLKMatrix4Scale(
            self.root.transform,
            metersPerUnitFactor,
            metersPerUnitFactor,
            metersPerUnitFactor);
   }
   else
   {
      self.root.transform = 
         GLKMatrix4Scale(
            self.root.transform,
            COLLADAParserMetersPerInch,
            COLLADAParserMetersPerInch,
            COLLADAParserMetersPerInch);
   }
}


/////////////////////////////////////////////////////////////////
// Extracts the values of interest from the COLLADA asset 
// element and updates receiver's internal state accordingly.
- (void)parseAssetElements:(NSArray *)elements
{
   // We only care about at most one asset element
   NSXMLElement *element = [elements lastObject];
   
   if(nil != element)
   {
      [self extractUpAxisFromAssetElement:element];
      [self extractUnitFromAssetElement:element];
   }
   else
   {
      NSLog(@"No \"asset\" found: %@",
            @"Using defualt Z up and Inches converted to Meters.");
      
      // Set default values
      {  // Rotate -90 deg about X
         self.root.transform = 
            GLKMatrix4MakeRotation(
               -M_PI/2.0f,
               1.0f,
               0.0f,
               0.0f);
         self.root.transform =
            GLKMatrix4Scale(
               self.root.transform,
               COLLADAParserMetersPerInch,
               COLLADAParserMetersPerInch,
               COLLADAParserMetersPerInch);
      }
   }
}


#pragma mark - library_images

/////////////////////////////////////////////////////////////////
//  
- (void)extractPathFromLibraryImagesElement:(NSXMLElement *)element
{
   NSArray *imageElements = 
      [element elementsForName:@"image"];
   
   for(NSXMLElement *imageElement in imageElements)
   {
      NSString *imageID =
         [[imageElement attributeForName:@"id"] objectValue];
      imageID =
         [@"#" stringByAppendingString:imageID];
      
      NSArray *pathElements = 
         [imageElement elementsForName:@"init_from"];
      if(1 != pathElements.count)
      {
         NSLog(@"Attempt to initialize image path with more than one path.");
      }
      
      NSXMLElement *pathElement = [pathElements lastObject];
      NSString *path = [pathElement stringValue];
      
      if(nil == path || nil == imageID)
      {
         NSLog(@"Failed extracting texture image path.");
      }
      else if(nil != [self.root.imagePaths objectForKey:imageID])
      {
         NSLog(@"Replacing image ID:%@ path:%@.",
            imageID, path);
      }
      
      COLLADAImagePath *imagePath =
         [[COLLADAImagePath alloc] init];
      imagePath.uid = imageID;
      imagePath.path = path;
      
      [self.root.imagePaths
         setObject:imagePath forKey:imageID];
   }
}


/////////////////////////////////////////////////////////////////
// Extracts the values of interest from the COLLADA 
// library_images element and updates receiver's internal state 
// accordingly.
- (void)parseLibraryImagesElements:(NSArray *)elements
{
   if(0 == elements.count)
   {
      NSLog(@"No \"library_images\" found: %@",
            @"No texture image has been identified.");
   }
   
   for(NSXMLElement *element in elements )
   {
     [self extractPathFromLibraryImagesElement:element];
   }   
}


#pragma mark - library_geometries

/////////////////////////////////////////////////////////////////
//  
- (void)parseGeometryElement:(NSXMLElement *)element
{  // element is <geometry>
   NSString *geometryID = [[element attributeForName:@"id"]
                           objectValue];
   
   if(nil != geometryID)
   {
      COLLADAGeometry *geometry = 
         [self extractGeometryFromGeometryElement:element];
      
      // Remember the geometry for future look-up when assembling
      // nodes etc.
      (self.root.geometries)[[@"#" stringByAppendingString:geometryID]] =
         geometry;
   }
   else
   {
      NSLog(@"Geometry found without ID and can't be used.");
   }
}


/////////////////////////////////////////////////////////////////
// Extracts the values of interest from the COLLADA 
// library_geometries element and updates receiver's internal 
// state accordingly.
- (void)parseLibraryGeometriesElements:(NSArray *)elements
{  
   if(1 != elements.count)
   {
      NSLog(@"Incorrect number of \"library_geometries\" found");
   }
   
   for(NSXMLElement *element in elements )
   {
      NSArray *geometries =
         [element elementsForName:@"geometry"];

      if(0 < [geometries count])
      {
         for(NSXMLElement *element in geometries)
         { // Each element is a "geometry"
            [self parseGeometryElement:element];
         }
      }
      else
      {
         NSLog(@"No \"geometry\" found: %@",
               @"No geometry (meshes) loaded.");
      }
   }   
}


#pragma mark - node

/////////////////////////////////////////////////////////////////
//  
- (GLKMatrix4)cumulativeTransformsForNodeElement:
   (NSXMLElement *)element
{
   // Collect transforms IN ORDER and apply to newNode
   // matrix
   GLKMatrix4 cumulativeTransforms = 
      GLKMatrix4Identity;
   
   for(NSXMLElement *subElement in [element children])
   {
      if([subElement.name isEqualToString:@"translate"])
      {
         NSString *arguments = [subElement stringValue];
         NSArray *separateArgumnts = 
         [arguments componentsSeparatedByString:@" "];
         if(3 != [separateArgumnts count])
         {
            NSLog(@"Incorrect number of <translate> values.");
         }
         else
         {
            float x = [separateArgumnts[0]
                       floatValue];
            float y = [separateArgumnts[1]
                       floatValue];
            float z = [separateArgumnts[2]
                       floatValue];
            
            cumulativeTransforms = 
            GLKMatrix4Translate(cumulativeTransforms, 
                                    x, 
                                    y, 
                                    z);
         }
      }
      else if([subElement.name isEqualToString:@"rotate"])
      {
         NSString *arguments = [subElement stringValue];
         NSArray *separateArgumnts = 
         [arguments componentsSeparatedByString:@" "];
         if(4 != [separateArgumnts count])
         {
            NSLog(@"Incorrect number of <rotate> values.");
         }
         else
         {
            float x = [separateArgumnts[0]
                       floatValue];
            float y = [separateArgumnts[1]
                       floatValue];
            float z = [separateArgumnts[2]
                       floatValue];
            float angleDeg = [separateArgumnts[3]
                              floatValue];
            
            cumulativeTransforms = 
            GLKMatrix4Rotate(
                                 cumulativeTransforms,
                                 GLKMathDegreesToRadians(angleDeg),
                                 x, 
                                 y, 
                                 z);
         }
      }
      else if([subElement.name isEqualToString:@"scale"])
      {
         NSString *arguments = [subElement stringValue];
         NSArray *separateArgumnts = 
         [arguments componentsSeparatedByString:@" "];
         if(3 != [separateArgumnts count])
         {
            NSLog(@"Incorrect number of <scale> values.");
         }
         else
         {
            float x = [separateArgumnts[0]
                       floatValue];
            float y = [separateArgumnts[1]
                       floatValue];
            float z = [separateArgumnts[2]
                       floatValue];
            
            cumulativeTransforms = 
            GLKMatrix4Scale(
                                cumulativeTransforms, 
                                x, 
                                y, 
                                z);
         }
      }
      else if([subElement.name isEqualToString:@"matrix"])
      {
         NSString *arguments = [subElement stringValue];
         NSArray *separateArgumnts = 
         [arguments componentsSeparatedByString:@" "];
         if(16 != [separateArgumnts count])
         {
            NSLog(@"Incorrect number of <matrix> values.");
         }
         else
         {
            float  matrixFloats[16];
            for(int i = 0; i < 16; i++)
            {
               matrixFloats[i] = [separateArgumnts[i]
                       floatValue];
            }
            GLKMatrix4 matrix = 
               GLKMatrix4MakeWithArray(matrixFloats);
            
            // COLLADA stores matrices transposed from openGL
            matrix = GLKMatrix4Transpose(matrix);
            
            cumulativeTransforms = 
               GLKMatrix4Multiply(
                  cumulativeTransforms, 
                  matrix);
         }
      }
   }
   
   return cumulativeTransforms;
}


/////////////////////////////////////////////////////////////////
//  
- (void)appendInstanceNodesForElement:(NSXMLElement *)element
   toNode:(COLLADANode *)aNode
{
   NSArray *instanceNodes =
      [element elementsForName:@"instance_node"];
   
   for(NSXMLElement *instanceNodeElement in instanceNodes)
   {  
      COLLADAInstance *newInstanceNode =
         [[COLLADAInstance alloc] init];
      
      // URL
      NSXMLNode *urlNode =
         [instanceNodeElement attributeForName:@"url"];
      NSString *urlID = [urlNode objectValue];      
      newInstanceNode.url = urlID;

      // Name
      NSXMLNode *nameNode =
         [instanceNodeElement attributeForName:@"name"];
      NSString *name = [nameNode objectValue];
      newInstanceNode.name = name;
      
      // Add to aNode
      aNode.instances =
         [aNode.instances setByAddingObject:newInstanceNode];
   }
}


/////////////////////////////////////////////////////////////////
//  
- (void)appendInstanceGeometriesForElement:(NSXMLElement *)element
   toNode:(COLLADANode *)aNode
{
   NSArray *instanceGeometries = 
      [element elementsForName:@"instance_geometry"];
   
   for(NSXMLElement *instanceGeometryElement in instanceGeometries)
   {  
      COLLADAInstanceGeometry *newInstanceGeometry =
         [[COLLADAInstanceGeometry alloc] init];
      
      // URL
      NSXMLNode *urlNode =
         [instanceGeometryElement attributeForName:@"url"];
      NSString *urlID = [urlNode objectValue];      
      newInstanceGeometry.url = urlID;

      // Name
      NSXMLNode *nameNode =
         [instanceGeometryElement attributeForName:@"name"];
      NSString *name = [nameNode objectValue];
      newInstanceGeometry.name = name;
      
      // Add to aNode
      aNode.instances =
         [aNode.instances setByAddingObject:newInstanceGeometry];

      // Material
      NSArray *materials =
        [instanceGeometryElement elementsForName:@"bind_material"];
      
      if(1 < materials.count)
      {
         NSLog(@"More than 1 material binding for instance geometry");
         return;
      }
      
      COLLADAInstance *newBindMaterial =
         [[COLLADAInstance alloc] init];
      
      for(NSXMLElement *materialElement in materials)
      {  
         NSArray *techniques =
            [materialElement elementsForName:@"technique_common"];
         
         if(1 < techniques.count)
         {
            NSLog(@"More than 1 material binding technique_common");
            return;
         }
      
         for(NSXMLElement *techniqueElement in techniques)
         {  
            NSArray *instanceMaterials =
               [techniqueElement elementsForName:@"instance_material"];
            
            if(1 < materials.count)
            {
               NSLog(@"More than 1 instance material for material binding");
               return;
            }
      
            for(NSXMLElement *instanceMaterialElement in instanceMaterials)
            {
               NSXMLNode *targetNode =
                  [instanceMaterialElement attributeForName:@"target"];
               NSString *targetID = [targetNode objectValue];               
               newBindMaterial.url = targetID;
            }
         }
      }
      
      // Add bind material
      newInstanceGeometry.bindMaterials =
         [newInstanceGeometry.bindMaterials setByAddingObject:newBindMaterial];
   }
}


/////////////////////////////////////////////////////////////////
//  
- (COLLADANode *)parseNodeElement:(NSXMLElement *)element
   parentNode:(COLLADANode *)parent;
{ // element is <node>
   COLLADANode *newNode =
      [[COLLADANode alloc] init];
   
   // Add as subnode to parent
   parent.subnodes =
      [parent.subnodes setByAddingObject:newNode];
   newNode.parent = parent;
   
   NSXMLNode *nodeIDNode = [element attributeForName:@"id"];
   NSString *idString = [nodeIDNode objectValue];
   if(nil != idString)
   {
      newNode.uid = [@"#" stringByAppendingString:idString];
   }
   
   NSXMLNode *nodeNameNode = [element attributeForName:@"name"];
   NSString *nodeName = [nodeNameNode objectValue];
   
   if(nil == nodeName)
   {
      nodeName = idString;
   
      if(nil == nodeName)
      {
         NSLog(@"<node> has no name or id");
      }
      else
      {
         nodeName = @"<ANONYMOUS>";
      }
   }
   newNode.name = nodeName;
   
   [self appendInstanceGeometriesForElement:element
      toNode:newNode];
   [self appendInstanceNodesForElement:element
      toNode:newNode];

   // Recursively add subnodes to newNode
   NSArray *subNodes = 
     [element elementsForName:@"node"];
   
   for(NSXMLElement *subNode in subNodes)
   {
      [self parseNodeElement:subNode
        parentNode:newNode];
   }
   
   newNode.transform =
      [self cumulativeTransformsForNodeElement:element];
   
   return newNode;
}


#pragma mark - library_visual_scenes

/////////////////////////////////////////////////////////////////
// Extracts the values of interest from the COLLADA 
// library_visual_scenes element and updates receiver's internal 
// state accordingly.
- (void)parseLibraryVisualScenesElements:(NSArray *)elements;
{  
   if(1 != elements.count)
   {
      NSLog(@"Incorrect number of \"library_visual_scenes\" found");
   }
   
   for(NSXMLElement *element in elements )
   {
      NSArray *visualScenes =
         [element elementsForName:@"visual_scene"];
      
      for(NSXMLElement *visualSceneElement in visualScenes)
      {
         COLLADANode *newScene =
            [[COLLADANode alloc] init];
         
         // URL
         NSXMLNode *idNode =
            [visualSceneElement attributeForName:@"id"];
         NSString *idString = [idNode objectValue];
         newScene.uid = [@"#" stringByAppendingString:idString];
         
         [self.root.visualScenes setObject:newScene forKey:newScene.uid];

         // Name
         NSXMLNode *nameNode =
            [visualSceneElement attributeForName:@"name"];
         NSString *name = [nameNode objectValue];
         newScene.name = name;
         
         NSArray *nodes =
            [visualSceneElement elementsForName:@"node"];
         
         for(NSXMLElement *nodeEelement in nodes)
         {
            [self parseNodeElement:nodeEelement parentNode:newScene];
         }
      }
   }
}


#pragma mark - library_materials

- (void)parseLibraryMaterialsElements:(NSArray *)elements;
{
   if(1 != elements.count)
   {
      NSLog(@"Incorrect number of \"library_materials\" found");
   }
   
   for(NSXMLElement *element in elements )
   {
      NSArray *materialElements =
         [element elementsForName:@"material"];
   
      for(NSXMLElement *materialElement in materialElements)
      {  
         COLLADAResource *newMaterial =
            [[COLLADAResource alloc] init];
         
         // URL
         NSXMLNode *idNode =
            [materialElement attributeForName:@"id"];
         NSString *idString = [idNode objectValue];
         newMaterial.uid = [@"#" stringByAppendingString:idString];

         [self.root.materials setObject:newMaterial forKey:newMaterial.uid];

         // Name
         NSXMLNode *nameNode =
            [materialElement attributeForName:@"name"];
         NSString *name = [nameNode objectValue];
         newMaterial.name = name;
         
         // Instance Effects
         NSArray *instanceEffects =
            [materialElement elementsForName:@"instance_effect"];
      
         for(NSXMLElement *instanceEffectElement in instanceEffects)
         {  
            COLLADAInstance *newInstanceEffect =
               [[COLLADAInstance alloc] init];
            
            // URL
            NSXMLNode *urlNode =
               [instanceEffectElement attributeForName:@"url"];
            NSString *urlID = [urlNode objectValue];      
            newInstanceEffect.url = urlID;
            newMaterial.instances =
               [newMaterial.instances setByAddingObject:newInstanceEffect];
         }
      }
   }
}


#pragma mark - library_effects

- (void)parseLibraryEffectsElements:(NSArray *)elements;
{
   if(1 != elements.count)
   {
      NSLog(@"Incorrect number of \"library_effects\" found");
      return;
   }
   
   for(NSXMLElement *element in elements )
   {
      NSArray *effectElements =
         [element elementsForName:@"effect"];
   
      for(NSXMLElement *effectElement in effectElements)
      {  
         COLLADAEffect *newEffect =
            [[COLLADAEffect alloc] init];
         
         // URL
         NSXMLNode *idNode =
            [effectElement attributeForName:@"id"];
         NSString *idString = [idNode objectValue];
         newEffect.uid = [@"#" stringByAppendingString:idString];

         [self.root.effects setObject:newEffect forKey:newEffect.uid];
         
         // Name
         NSXMLNode *nameNode =
            [effectElement attributeForName:@"name"];
         NSString *name = [nameNode objectValue];
         newEffect.name = name;
         
         // profile_COMMON
         NSArray *profileElements =
            [effectElement elementsForName:@"profile_COMMON"];
      
         if(1 != profileElements.count)
         {
            NSLog(@"Incorrect number of \"profile_COMMON\" found");
            return;
         }
         
         for(NSXMLElement *profileElement in profileElements)
         {  
            NSArray *newParamElements =
               [profileElement elementsForName:@"newparam"];
            
            for(NSXMLElement *newParamElement in newParamElements)
            {  
               NSArray *surfaceElements =
                  [newParamElement elementsForName:@"surface"];
               
               for(NSXMLElement *surfaceElement in surfaceElements)
               {  
                  NSArray *initFromElements =
                     [surfaceElement elementsForName:@"init_from"];
                  
                  for(NSXMLElement *initFromElement in initFromElements)
                  {
                     newEffect.diffuseTextureImagePathURL =
                        [@"#" stringByAppendingString:initFromElement.objectValue];
                  }
               }
            }
        }
      }
   }
}


#pragma mark - library_nodes

- (void)parseLibraryNodesElements:(NSArray *)elements;
{
   if(1 < elements.count)
   {
      NSLog(@"Incorrect number of \"library_nodes\" found");
   }
   
   for(NSXMLElement *element in elements )
   {
      NSArray *nodes = [element elementsForName:@"node"];
      
      for(NSXMLElement *nodeEelement in nodes)
      {
         COLLADANode *node =
            [self parseNodeElement:nodeEelement parentNode:nil];
         [self.root.nodes setObject:node forKey:node.uid];
      }
   }
}


#pragma mark - Document Level

/////////////////////////////////////////////////////////////////
// Extracts each top level elemement of interest.
- (void)parseXMLDocument:(NSXMLDocument *)xmlDoc
{
   NSXMLElement *rootElement = [xmlDoc rootElement]; 
   
   {
      NSArray *assetElements = 
         [rootElement elementsForName:@"asset"];
      [self parseAssetElements:assetElements];
   }
   {   
      NSArray *libraryImages = 
         [rootElement elementsForName:@"library_images"];
      [self parseLibraryImagesElements:libraryImages];
   }
   {
      NSArray *libraryGeometries = 
         [rootElement elementsForName:@"library_geometries"];
      [self parseLibraryGeometriesElements:libraryGeometries];
   }
   {
      NSArray *libraryVisualScenes = 
         [rootElement elementsForName:@"library_visual_scenes"];
      [self parseLibraryVisualScenesElements:libraryVisualScenes];
   }
   {
      NSArray *libraryMaterials = 
         [rootElement elementsForName:@"library_materials"];
      [self parseLibraryMaterialsElements:libraryMaterials];
   }
   {
      NSArray *libraryEffects =
         [rootElement elementsForName:@"library_effects"];
      [self parseLibraryEffectsElements:libraryEffects];
   }
   {
      NSArray *libraryNodes =
         [rootElement elementsForName:@"library_nodes"];
      [self parseLibraryNodesElements:libraryNodes];
   }
   
   //NSArray *libraryAnimations = 
   //   [rootElement elementsForName:@"library_animations"];
   //NSArray *libraryLights = 
   //   [rootElement elementsForName:@"library_lights"];   
   //NSArray *libraryControllers = 
   //   [rootElement elementsForName:@"library_controllers"];
   //NSArray *scene = 
   //   [rootElement elementsForName:@"scene"];
   
   //NSLog(@"%@", libraryAnimations);
   //NSLog(@"%@", libraryLights);
   //NSLog(@"%@", libraryImages);
   //NSLog(@"%@", libraryMaterials);
   //NSLog(@"%@", libraryEffects);
   //NSLog(@"%@", libraryNodes);
   //NSLog(@"%@", libraryGeometries);
   //NSLog(@"%@", libraryControllers);
   //NSLog(@"%@", libraryVisualScenes);
   //NSLog(@"%@", scene);
}


/////////////////////////////////////////////////////////////////
//
- (void)parseCOLLADAFileAtURL:(NSURL *)aURL
{
   NSParameterAssert(aURL);
   
   NSError *error = nil;
   NSXMLDocument *xmlDoc = 
   [[NSXMLDocument alloc] 
     initWithContentsOfURL:aURL
     options:(NSXMLNodePreserveWhitespace|NSXMLNodePreserveCDATA)
     error:&error];
   
   if (nil == xmlDoc) 
   {
      xmlDoc = 
      [[NSXMLDocument alloc] 
       initWithContentsOfURL:aURL
       options:NSXMLDocumentTidyXML
       error:&error];
   }
   
   if (nil != error) 
   {
      NSLog(@"Unrecoverable parsing error: %@", error);
   }
   else
   {
      [self parseXMLDocument:xmlDoc];
      self.root.path = [aURL.path stringByDeletingLastPathComponent];
      self.root.name =
         [[aURL.path lastPathComponent] stringByDeletingPathExtension];
      
      for(COLLADAImagePath *imagePath in self.root.imagePaths.allValues)
      {
         [imagePath loadImageFromBasePath:self.root.path];
      }
   }
}

@end
