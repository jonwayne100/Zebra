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
                        
    NSPipe *outputPipe = [[NSPipe alloc] init];
    NSFileHandle *output = [outputPipe fileHandleForReading];
    [output waitForDataInBackgroundAndNotify];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receivedData:) name:NSFileHandleDataAvailableNotification object:output];
                            
    NSPipe *errorPipe = [[NSPipe alloc] init];
    NSFileHandle *error = [errorPipe fileHandleForReading];
    [error waitForDataInBackgroundAndNotify];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receivedErrorData:) name:NSFileHandleDataAvailableNotification object:error];
                            
    [task setStandardOutput:outputPipe];
    [task setStandardError:errorPipe];

    [task launch];
    [task waitUntilExit];

    [[self.xpcConnection remoteObjectProxy] finished];
}

-(BOOL)listener:(NSXPCListener *)listener shouldAcceptNewConnection:(NSXPCConnection *)newConnection {
    newConnection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(ZBSlingshotServer)];
    newConnection.exportedObject = self;
    newConnection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(ZBSlingshotClient)];
    self.xpcConnection = newConnection;

    [newConnection resume];

    return YES;
}

- (void)receivedData:(NSNotification *)notif {
    NSLog(@"[Supersling] Received Data, forwarding to Zebra");
    
    NSFileHandle *fh = [notif object];
    NSData *data = [fh availableData];

    if (data.length) {
        [fh waitForDataInBackgroundAndNotify];
        NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

        [[self.xpcConnection remoteObjectProxy] receivedData:str];
    }
}

- (void)receivedErrorData:(NSNotification *)notif {
    NSLog(@"[Supersling] Received Error Data, forwarding to Zebra");
    
    NSFileHandle *fh = [notif object];
    NSData *data = [fh availableData];

    if (data.length) {
        [fh waitForDataInBackgroundAndNotify];
        NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

        [[self.xpcConnection remoteObjectProxy] receivedErrorData:str];
    }
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
