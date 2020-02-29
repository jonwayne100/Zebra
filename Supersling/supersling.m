#include <Foundation/Foundation.h>
#include <Foundation/NSXPCListener.h>
#include <Foundation/NSXPCInterface.h>
#include "../Zebra/Commands/ZBSlingshot.h"
#include "../Zebra/Headers/NSTask.h"

@implementation ZBSlingshot

- (void)runCommandAtPath:(NSString *)path arguments:(NSArray *)arguments asRoot:(BOOL)root {
    NSLog(@"[Supersling] Running %@ as %@ with arguments %@", path, root ? @"root" : @"mobile", arguments);

    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:path];
    [task setArguments:arguments];

    [task launch];
}

-(BOOL)listener:(NSXPCListener *)listener shouldAcceptNewConnection:(NSXPCConnection *)newConnection {
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
