//
//  ZBSlingshot.h
//  Zebra
//
//  Created by Wilson Styres on 2/29/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#ifndef ZBSlingshot_h
#define ZBSlingshot_h

@protocol ZBSlingshotServer

- (void)runCommandAtPath:(NSString *_Nonnull)path arguments:(NSArray *_Nonnull)arguments asRoot:(BOOL)root;

@end

@protocol ZBSlingshotClient

- (void)receivedData:(NSString *_Nullable)notif;
- (void)receivedErrorData:(NSString *_Nullable)notif;

@end

@interface ZBSlingshot : NSObject <NSXPCListenerDelegate, ZBSlingshotServer>

@property (strong) NSXPCConnection *_Nullable xpcConnection;

@end

#endif /* ZBSlingshotProtocol_h */
