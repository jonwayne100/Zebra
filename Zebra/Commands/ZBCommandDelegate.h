//
//  ZBCommandDelegate.h
//  Zebra
//
//  Created by Thatchapon Unprasert on 18/6/2019
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#ifndef ZBCommandDelegate_h
#define ZBCommandDelegate_h

@protocol ZBCommandDelegate
- (void)receivedMessage:(NSString *_Nonnull)notif;
- (void)receivedWarning:(NSString *_Nonnull)notif;
- (void)receivedError:(NSString *_Nonnull)notif;
@end


#endif /* ZBCommandDelegate_h */
