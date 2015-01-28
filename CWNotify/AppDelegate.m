//
//  Copyright (c) 2015 feedtailor Inc. All rights reserved.
//

#import "AppDelegate.h"
#import "FTDataStorage.h"

#import "NSMutableURLRequest+ChatWork.h"
#import "UpdateManager.h"
#import "FTKeychain.h"

@interface AppDelegate () <NSUserNotificationCenterDelegate>
{
    NSStatusItem* statusItem;
}

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    
    [[NSUserNotificationCenter defaultUserNotificationCenter] setDelegate:self];
    [[FTDataStorage sharedStorage] loadStore];
    
    NSStatusBar* bar = [NSStatusBar systemStatusBar];
    statusItem = [bar statusItemWithLength:NSSquareStatusItemLength];
    [statusItem setImage:[NSImage imageNamed:@"menu_b"]];
    [statusItem setAlternateImage:[NSImage imageNamed:@"menu_w"]];
    
    NSMenu* menu = [[NSMenu alloc] init];
    [statusItem setMenu:menu];
    
    [menu addItemWithTitle:@"アバウト" action:@selector(showAbout:) keyEquivalent:@""];
    [menu addItemWithTitle:@"設定" action:@selector(askToken:) keyEquivalent:@""];
    [menu addItemWithTitle:@"終了" action:@selector(terminate:) keyEquivalent:@""];
    
    if ([NSMutableURLRequest token]) {
        [[UpdateManager sharedManager] update];
    } else {
        [self performSelector:@selector(askToken:) withObject:nil afterDelay:0];
    }
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

-(void) askToken:(id)sender
{
    [NSApp activateIgnoringOtherApps:YES];
    NSString* token = [FTKeychain passwordForService:[[NSBundle mainBundle] bundleIdentifier] account:[[NSBundle mainBundle] bundleIdentifier] error:nil];

    NSTextField* fld = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 400, 30)];
    if (token) {
        fld.stringValue = token;
    }
    NSAlert* alert = [[NSAlert alloc] init];
    [alert setMessageText:@"API Tokenを入力してください"];
    [alert setInformativeText:@"Tokenは http://developer.chatwork.com/ja/index.html から取得できます"];
    [alert setAccessoryView:fld];
    [alert runModal];
    
    [FTKeychain setPassword:fld.stringValue forService:[[NSBundle mainBundle] bundleIdentifier] account:[[NSBundle mainBundle] bundleIdentifier] error:nil];
    [[UpdateManager sharedManager] update];
}

-(void) showAbout:(id)sender
{
    [NSApp activateIgnoringOtherApps:YES];
    [NSApp orderFrontStandardAboutPanel:sender];
}

-(void) terminate:(id)sender
{
    [NSApp terminate:sender];
}

#pragma mark -

-(void) userNotificationCenter:(NSUserNotificationCenter *)center didActivateNotification:(NSUserNotification *)notification
{
    if (notification.userInfo) {
        id roomId = [notification.userInfo objectForKey:@"rid"];
        if (roomId) {
            [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://www.chatwork.com/#!%@", roomId]]];
        }
    }
    
    [center removeDeliveredNotification:notification];
}

@end
