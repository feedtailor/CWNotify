//
//  Copyright (c) 2015 feedtailor Inc. All rights reserved.
//

#import "NSMutableURLRequest+ChatWork.h"
#import "FTKeychain.h"

static NSString* s_token = nil;

@implementation NSMutableURLRequest (ChatWork)

+(void) initialize
{
    s_token = [FTKeychain passwordForService:[[NSBundle mainBundle] bundleIdentifier] account:[[NSBundle mainBundle] bundleIdentifier] error:nil];
}

+(void) setToken:(NSString*)token
{
    s_token = token;
}

+(NSString*) token
{
    return s_token;
}


+(instancetype) requestWithPath:(NSString*)path
{
    NSURL* url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@", CHATWORK_ENDPOINT, path]];
    NSMutableURLRequest* req = [NSMutableURLRequest requestWithURL:url];
    NSString* token = [self token];
    [req setValue:token forHTTPHeaderField:@"X-ChatWorkToken"];
    return req;
}

@end
