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
- (void)receivedData:(NSNotification *_Nullable)notif;
- (void)receivedErrorData:(NSNotification *_Nullable)notif;
@end


#endif /* ZBCommandDelegate_h */
