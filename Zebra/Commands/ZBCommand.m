//
//  ZBCommand.m
//  Zebra
//
//  Created by Wilson Styres on 2/29/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import "ZBCommand.h"
#import <ZBAppDelegate.h>

@implementation ZBCommand

@synthesize delegate;

- (id)initWithDelegate:(id <ZBCommandDelegate> _Nullable)delegate {
    self = [super init];
    
    if (self && delegate) {
        self.delegate = delegate;
    }
    
    return self;
}

- (void)runCommandAtPath:(NSString *_Nonnull)path arguments:(NSArray *)arguments asRoot:(BOOL)root {
    NSXPCConnection *xpcConnection = [[NSXPCConnection alloc] initWithMachServiceName:@"xyz.willy.supersling" options:NSXPCConnectionPrivileged];
    
    NSXPCInterface *remoteInterface = [NSXPCInterface interfaceWithProtocol:@protocol(ZBSlingshotServer)];
    xpcConnection.remoteObjectInterface = remoteInterface;
    
    xpcConnection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(ZBSlingshotClient)];
    xpcConnection.exportedObject = self;
    
    xpcConnection.interruptionHandler = ^{
        NSLog(@"[Zebra] Communication with Supersling terminated");
    };

    xpcConnection.invalidationHandler = ^{
        NSLog(@"[Zebra] Communication with Supersling invalidated");
    };
    
    [xpcConnection resume];
    
    id<ZBSlingshotServer> slingshot = [xpcConnection remoteObjectProxyWithErrorHandler:^(NSError * _Nonnull error) {
        [ZBAppDelegate sendErrorToTabController:error.localizedDescription];
    }];
    
    [slingshot runCommandAtPath:path arguments:arguments];
}

- (void)receivedData:(NSString *)message {
    NSLog(@"[Zebra] Received Data from su/sling: %@", message);
    [delegate receivedMessage:message];
}

- (void)receivedErrorData:(NSString *)message {
    NSLog(@"[Zebra] Received Error Data from su/sling: %@", message);
    if ([[message lowercaseString] rangeOfString:@"warning"].location != NSNotFound || [[message lowercaseString] rangeOfString:@"w: "].location != NSNotFound) {
        [delegate receivedWarning:message];
    }
    else { //We apparently never logged errors before this...
        [delegate receivedError:message];
    }
}

- (void)finished {
    [delegate receivedMessage:@"Finished Command"];
}

@end
