//
//  ZBCommand.m
//  Zebra
//
//  Created by Wilson Styres on 2/29/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import "ZBCommand.h"
#import "ZBSlingshot.h"

@implementation ZBCommand

- (id)init {
    self = [super init];
    
    if (self) {
        NSLog(@"[Zebra] Create command instance");
    }
    
    return self;
}

- (void)runCommandAtPath:(NSString *)path arguments:(NSArray *)arguments asRoot:(BOOL)root {
    NSXPCInterface *remoteInterface = [NSXPCInterface interfaceWithProtocol:@protocol(ZBSlingshotServer)];
    NSXPCConnection *xpcConnection = [[NSXPCConnection alloc] initWithMachServiceName:@"xyz.willy.supersling" options:NSXPCConnectionPrivileged];
    
    xpcConnection.remoteObjectInterface = remoteInterface;
    
    xpcConnection.interruptionHandler = ^{
        NSLog(@"[Zebra] Communication with Supersling terminated");
    };

    xpcConnection.invalidationHandler = ^{
        NSLog(@"[Zebra] Communication with Supersling invalidated");
    };
    
    [xpcConnection resume];
    
    [xpcConnection.remoteObjectProxy runCommandAtPath:path arguments:arguments asRoot:root];
}

@end
