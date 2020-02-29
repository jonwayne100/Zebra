//
//  ZBCommand.m
//  Zebra
//
//  Created by Wilson Styres on 2/29/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import "ZBCommand.h"

@implementation ZBCommand

- (id)init {
    self = [super init];
    
    if (self) {
        NSLog(@"[Zebra] Create command instance");
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
    
    [xpcConnection.remoteObjectProxy runCommandAtPath:path arguments:arguments asRoot:root];
}

- (void)receivedData:(NSString *)data {
    NSLog(@"[Zebra] Received Data from su/sling: %@", data);
}

- (void)receivedErrorData:(NSString *)data {
    if ([data rangeOfString:@"warning"].location != NSNotFound) {
        data = [data stringByReplacingOccurrencesOfString:@"dpkg: " withString:@""];
            
        NSLog(@"[Zebra] Received Warning Data from su/sling: %@", data);
    } else if ([data rangeOfString:@"error"].location != NSNotFound) {
        data = [data stringByReplacingOccurrencesOfString:@"dpkg: " withString:@""];

        NSLog(@"[Zebra] Received Error Data from su/sling: %@", data);
    }
}

@end
