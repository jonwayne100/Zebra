//
//  ZBSlingshot.h
//  Zebra
//
//  Created by Wilson Styres on 2/29/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

@class NSTask;

#ifndef ZBSlingshot_h
#define ZBSlingshot_h

NS_ASSUME_NONNULL_BEGIN

@protocol ZBSlingshotServer

- (void)executeCommands:(NSArray <NSArray <NSString *> *> *)commands;

@end

@protocol ZBSlingshotClient

- (void)receivedData:(NSString *_Nullable)notif;
- (void)receivedErrorData:(NSString *_Nullable)notif;

- (void)task:(NSTask *)task failedWithReason:(NSString *)reason;
- (void)finishedAllTasks;

@end

@interface ZBSlingshot : NSObject <NSXPCListenerDelegate, ZBSlingshotServer>

@property (strong) NSXPCConnection *xpcConnection;
@property BOOL running;

@end

NS_ASSUME_NONNULL_END

#endif /* ZBSlingshotProtocol_h */
