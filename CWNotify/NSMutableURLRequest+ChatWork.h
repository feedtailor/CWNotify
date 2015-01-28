//
//  Copyright (c) 2015 feedtailor Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#define CHATWORK_HOST   @"api.chatwork.com"
#define CHATWORK_VERSION   @"v1"
#define CHATWORK_ENDPOINT   [NSString stringWithFormat:@"https://%@/%@", CHATWORK_HOST, CHATWORK_VERSION]


@interface NSMutableURLRequest (ChatWork)

+(void) setToken:(NSString*)token;
+(NSString*) token;

+(instancetype) requestWithPath:(NSString*)path;

@end
