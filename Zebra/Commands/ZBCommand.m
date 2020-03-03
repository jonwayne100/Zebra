//
//  ZBCommand.m
//  Zebra
//
//  Created by Wilson Styres on 2/29/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

@import Crashlytics;

#import "ZBCommand.h"
#import <ZBAppDelegate.h>
#import <NSTask.h>

@implementation ZBCommand

@synthesize delegate;

#pragma mark - Initializers

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

#pragma mark - Executing Commands

- (void)executeCommands:(NSArray <NSArray <NSString *> *> *)commands asRoot:(BOOL)root {
    if (root) {
        [self.slingshot executeCommands:commands];
    }
    else {
        for (NSArray *command in commands) {
            int status = [self executeCommand:command];
            if (status != 0) {
                if (self.delegate) [self.delegate receivedError:[NSString stringWithFormat:@"Task failed with error code %d", status]];
                break;
            }
        }
    }
}

- (int)executeCommand:(NSArray <NSString *> *)command {
    NSString *binary = [self locateCommandInPath:command[0]];
    if (!binary) {
        if (self.delegate) [self.delegate receivedError:[NSString stringWithFormat:@"Unable to find %@ in your PATH. Is it installed?", command[0]]];
        return 5478;
    }
    
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:binary];
    [task setArguments:[command subarrayWithRange:NSMakeRange(1, command.count - 1)]];

    if (self.delegate) {
        NSPipe *outputPipe = [[NSPipe alloc] init];
        NSFileHandle *output = [outputPipe fileHandleForReading];
        [output waitForDataInBackgroundAndNotify];
        [[NSNotificationCenter defaultCenter] addObserver:self.delegate selector:@selector(receivedData:) name:NSFileHandleDataAvailableNotification object:output];
        
        NSPipe *errorPipe = [[NSPipe alloc] init];
        NSFileHandle *error = [errorPipe fileHandleForReading];
        [error waitForDataInBackgroundAndNotify];
        [[NSNotificationCenter defaultCenter] addObserver:self.delegate selector:@selector(receivedErrorData:) name:NSFileHandleDataAvailableNotification object:error];

        [task setStandardOutput:outputPipe];
        [task setStandardError:errorPipe];
    }

    @try {
        [task launch];
        [task waitUntilExit];
        
        return [task terminationStatus];
    }
    @catch (NSException *e) {
        NSString *message = [NSString stringWithFormat:@"%@ Could not spawn %@. Reason: %@", e.name, binary, e.reason];
        CLS_LOG(@"%@", message);
        NSLog(@"[Zebra] %@", message);
        
        if (self.delegate) [self.delegate receivedError:message];
        
        return 3333;
    }
}

- (NSString *_Nullable)locateCommandInPath:(NSString *)command {
    if ([command containsString:@"/"] && [[NSFileManager defaultManager] fileExistsAtPath:command]) { //If the file exists then just return it
        return command;
    }
    
    NSDictionary *environmentDict = [[NSProcessInfo processInfo] environment];
    NSArray *PATH = [[environmentDict objectForKey:@"PATH"] componentsSeparatedByString:@":"];
    
    for (NSString *path in PATH) {
        NSString *commandPath = [path stringByAppendingPathComponent:command];
        if ([[NSFileManager defaultManager] fileExistsAtPath:commandPath]) {
            return commandPath;
        }
    }
    
    return NULL;
}

#pragma mark - Slingshot Client

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
