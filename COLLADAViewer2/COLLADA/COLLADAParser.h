//
//  COLLADAParser.h
//  COLLADAViewer
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKMath.h>


@class COLLADARoot;
@class NSManagedObjectContext;


@interface COLLADAParser : NSObject <NSXMLParserDelegate>

@property (retain, nonatomic, readonly)
   COLLADARoot *root;

- (void)parseCOLLADAFileAtURL:(NSURL *)aURL;
 
@end
