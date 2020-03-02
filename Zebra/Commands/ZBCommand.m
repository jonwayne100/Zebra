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
    
    if (self) {
        if (delegate) self.delegate = delegate;
        self.finished = NO;
        
        NSXPCConnection *connection = [[NSXPCConnection alloc] initWithMachServiceName:@"xyz.willy.supersling" options:NSXPCConnectionPrivileged];
        
        NSXPCInterface *remoteInterface = [NSXPCInterface interfaceWithProtocol:@protocol(ZBSlingshotServer)];
        connection.remoteObjectInterface = remoteInterface;
        
        connection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(ZBSlingshotClient)];
        connection.exportedObject = self;
        
        [connection setInterruptionHandler:^{
            if (!self.finished) {
                [self.delegate receivedError:@"Communication with su/sling interrupted."];
                
                [self finishedAllTasks];
            }
        }];

        [connection setInvalidationHandler:^{
            if (!self.finished) {
                [self.delegate receivedError:@"Communication with su/sling invalidated."];
                
                [self finishedAllTasks];
            }
        }];
        
        [connection resume];
        
        id<ZBSlingshotServer> slingshot = [connection remoteObjectProxyWithErrorHandler:^(NSError * _Nonnull error) {
            [self.delegate receivedError:error.localizedDescription];
        }];
        
        self.slingshot = slingshot;
    }
    
    return self;
}

- (void)executeCommands:(NSArray <NSArray <NSString *> *> *)commands asRoot:(BOOL)root {
    if (root) {
        [self.slingshot executeCommands:commands];
    }
}

- (void)receivedData:(NSString *)message {
    [delegate receivedMessage:message];
}

- (void)receivedErrorData:(NSString *)message {
    if ([[message lowercaseString] rangeOfString:@"warning"].location != NSNotFound || [[message lowercaseString] rangeOfString:@"w: "].location != NSNotFound) {
        [delegate receivedWarning:message];
    }
    else { //We apparently never logged errors before this...
        [delegate receivedError:message];
    }
}

- (void)task:(NSTask *)task failedWithReason:(NSString *)reason {
    [delegate task:task failedWithReason:reason];
    [delegate finishedAllTasks];
}

- (void)finishedAllTasks {
    self.finished = YES;
    
    [delegate finishedAllTasks];
}

@end
