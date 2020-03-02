//
//  ZBCommandDelegate.h
//  Zebra
//
//  Created by Thatchapon Unprasert on 18/6/2019
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

@class NSTask;

#ifndef ZBCommandDelegate_h
#define ZBCommandDelegate_h

@protocol ZBCommandDelegate
- (void)receivedMessage:(NSString *_Nonnull)notif;
- (void)receivedWarning:(NSString *_Nonnull)notif;
- (void)receivedError:(NSString *_Nonnull)notif;

- (void)task:(NSTask *_Nonnull)task failedWithReason:(NSString *_Nonnull)reason;
- (void)finishedAllTasks;
@end


#endif /* ZBCommandDelegate_h */
