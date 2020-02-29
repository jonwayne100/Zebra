#include <Foundation/Foundation.h>
#include <Foundation/NSXPCListener.h>
#include <Foundation/NSXPCInterface.h>
#include "../Zebra/Commands/ZBSlingshot.h"

@implementation ZBSlingshot

- (void)runCommandAtPath:(NSString *)path arguments:(NSArray *)arguments asRoot:(BOOL)root {
    NSLog(@"[Supersling] Running %@ as %@ with arguments %@", path, root ? @"root" : @"mobile", arguments);
}

-(BOOL)listener:(NSXPCListener *)listener shouldAcceptNewConnection:(NSXPCConnection *)newConnection {
    NSLog(@"[Supersling] Should I accept this new connection?");
    NSXPCInterface *interface = [NSXPCInterface interfaceWithProtocol:@protocol(ZBSlingshotServer)];
    newConnection.exportedInterface = interface;
    newConnection.exportedObject = self;
    [newConnection resume];

    return YES;
}

@end

int main(int argc, char **argv, char **envp) {
    @autoreleasepool {
        ZBSlingshot *server = [[ZBSlingshot alloc] init];
        NSXPCListener *listener = [[NSXPCListener alloc] initWithMachServiceName:@"xyz.willy.supersling"];
        listener.delegate = server;

        if (server && listener) {
            NSLog(@"[Supersling] Created server and listener");
        }

        [listener resume];
        [[NSRunLoop currentRunLoop] run];

        return 0;
    }
}
