//
//  Copyright (c) 2015 feedtailor Inc. All rights reserved.
//

#import "UpdateManager.h"

#import "DBRoom.h"
#import "NSMutableURLRequest+ChatWork.h"
#import "FTKeychain.h"

#import "AFNetworking.h"
#import "FTNSDictionary+TypeCheckKeyPath.h"
#import "FTDataStorage.h"

static UpdateManager* s_self = nil;

@interface UpdateManager ()

@property (nonatomic, strong) NSNumber* accountId;

@end

@implementation UpdateManager

+(instancetype) sharedManager
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!s_self) {
            s_self = [[self alloc] init];
        }
    });
    
    return s_self;
}

-(void) update
{
    NSLog(@"update");
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:_cmd object:nil];
    
    NSString* token = [FTKeychain passwordForService:[[NSBundle mainBundle] bundleIdentifier] account:[[NSBundle mainBundle] bundleIdentifier] error:nil];
    if (!token) {
        return;
    }
    [NSMutableURLRequest setToken:token];
    
    [self getUser];
}

-(void) getUser
{
    AFHTTPRequestOperationManager* mgr = [AFHTTPRequestOperationManager manager];
    NSMutableURLRequest* req = [NSMutableURLRequest requestWithPath:@"me"];
    AFHTTPRequestOperation* op = [mgr HTTPRequestOperationWithRequest:req success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        self.accountId = [responseObject ft_numberForKeyPath:@"account_id"];
        
        [self getRooms];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [self performSelector:@selector(update) withObject:nil afterDelay:60];
    }];
    [mgr.operationQueue addOperation:op];

}

-(void) getRooms
{
    AFHTTPRequestOperationManager* mgr = [AFHTTPRequestOperationManager manager];
    NSMutableURLRequest* req = [NSMutableURLRequest requestWithPath:@"rooms"];
    AFHTTPRequestOperation* op = [mgr HTTPRequestOperationWithRequest:req success:^(AFHTTPRequestOperation *operation, id responseObject) {
        FTDataStorage* storage = [FTDataStorage sharedStorage];
        NSMutableArray* oldRooms = [[storage execPredicate:nil entity:@"Room" sortDescriptors:nil] mutableCopy];
        [storage beginTransaction];
        
        for (NSDictionary* dic in responseObject) {
            if (![[dic ft_boolForKeyPath:@"sticky"] boolValue]) {
                continue;
            }
            
            NSNumber* roomId = [dic ft_numberForKeyPath:@"room_id"];
            DBRoom* room = [storage uniqueObjectForKey:@"roomId" uniqueValue:roomId entity:@"Room"];
            if (room) {
                [oldRooms removeObject:room];
            } else {
                room = [NSEntityDescription insertNewObjectForEntityForName:@"Room" inManagedObjectContext:storage.managedObjectContext];
                room.roomId = roomId;
            }
            room.name = [dic ft_stringForKeyPath:@"name"];
            NSDate* date = [NSDate dateWithTimeIntervalSince1970:[[dic ft_numberForKeyPath:@"last_update_time"] integerValue]];
            NSLog(@"%@ %@", roomId, [date description]);
            if (!room.lastUpdate || [room.lastUpdate compare:date] == NSOrderedAscending) {
                [self updateRoom:room date:date];
            }
        }
        
        if ([oldRooms count] > 0) {
            for (DBRoom* room in oldRooms) {
                [storage.managedObjectContext deleteObject:room];
            }
        }
        
        [storage commitTransaction];
        
        [self performSelector:@selector(update) withObject:nil afterDelay:60];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [self performSelector:@selector(update) withObject:nil afterDelay:60];
    }];
    [mgr.operationQueue addOperation:op];
}

-(void) updateRoom:(DBRoom*)room date:(NSDate*)date
{
    NSLog(@"update room %@ (%@)", room.roomId, [date description]);

    AFHTTPRequestOperationManager* mgr = [AFHTTPRequestOperationManager manager];
    NSMutableURLRequest* req = [NSMutableURLRequest requestWithPath:[NSString stringWithFormat:@"rooms/%@/messages?force=1", room.roomId]];
    AFHTTPRequestOperation* op = [mgr HTTPRequestOperationWithRequest:req success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if ([responseObject count] == 0) {
            return;
        }
        if (!room.lastUpdate) {
            // 初回は最新のものだけ使う
            for (NSDictionary* dic in [responseObject reverseObjectEnumerator]) {
                if ([[dic ft_numberForKeyPath:@"account.account_id"] isEqualToNumber:self.accountId]) {
                    continue;
                }
                [self notifyMessage:dic room:room];
                break;
            }
        } else {
            for (NSDictionary* dic in responseObject) {
                if ([[dic ft_numberForKeyPath:@"account.account_id"] isEqualToNumber:self.accountId]) {
                    continue;
                }
                
                NSDate* sendTime = [NSDate dateWithTimeIntervalSince1970:[[dic ft_numberForKeyPath:@"send_time"] integerValue]];
                if ([room.lastUpdate compare:sendTime] == NSOrderedAscending) {
                    [self notifyMessage:dic room:room];
                }
            }
        }
        room.lastUpdate = date;
        
        [[FTDataStorage sharedStorage] save];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
    }];
    [mgr.operationQueue addOperation:op];
}

-(void) notifyMessage:(NSDictionary*)message room:(DBRoom*)room
{
    NSMutableString* body = [[message ft_stringForKeyPath:@"body"] mutableCopy];
    NSRegularExpression* regex;
    {
        regex = [NSRegularExpression regularExpressionWithPattern:@"\\[To.*\\]" options:0 error:nil];
        [regex replaceMatchesInString:body options:0 range:NSMakeRange(0, [body length]) withTemplate:@""];
    }
    {
        regex = [NSRegularExpression regularExpressionWithPattern:@"\\[rp.*\\]" options:0 error:nil];
        [regex replaceMatchesInString:body options:0 range:NSMakeRange(0, [body length]) withTemplate:@""];
    }
    {
        regex = [NSRegularExpression regularExpressionWithPattern:@"\\[info\\].*\\[/info\\]" options:0 error:nil];
        [regex replaceMatchesInString:body options:0 range:NSMakeRange(0, [body length]) withTemplate:@""];
    }
    
    NSUserNotification* not = [[NSUserNotification alloc] init];
    not.title = room.name;
    not.subtitle = [message ft_stringForKeyPath:@"account.name"];
    not.informativeText = body;
    not.userInfo = @{@"rid": room.roomId};
    
    [[NSUserNotificationCenter defaultUserNotificationCenter] scheduleNotification:not];
}


@end
