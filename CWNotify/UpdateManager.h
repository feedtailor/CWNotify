//
//  Copyright (c) 2015 feedtailor Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UpdateManager : NSObject

+(instancetype) sharedManager;

-(void) update;

@end
