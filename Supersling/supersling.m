#include <Foundation/Foundation.h>
#include <Foundation/NSXPCListener.h>
#include <Foundation/NSXPCInterface.h>
#include <sys/stat.h>

#include "../Zebra/Commands/ZBSlingshot.h"
#include "../Zebra/Headers/NSTask.h"

int proc_pidpath(int pid, void * buffer, uint32_t buffersize);

@implementation ZBSlingshot

@synthesize outputPipe;
@synthesize errorPipe;

- (void)executeCommands:(NSArray <NSArray <NSString *> *> *)commands {
    NSMutableArray *tasks = [NSMutableArray new];
    for (NSArray *command in commands) {
        NSLog(@"[Supersling] Command Received: %@", command);

        NSTask *task = [[NSTask alloc] init];
        [task setLaunchPath:command[0]];
        [task setArguments:[command subarrayWithRange:NSMakeRange(1, command.count - 1)]];
                            
        if (!outputPipe) outputPipe = [[NSPipe alloc] init];
        NSFileHandle *output = [outputPipe fileHandleForReading];
        [output waitForDataInBackgroundAndNotify];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receivedData:) name:NSFileHandleDataAvailableNotification object:output];
                                
        if (!errorPipe) errorPipe = [[NSPipe alloc] init];
        NSFileHandle *error = [errorPipe fileHandleForReading];
        [error waitForDataInBackgroundAndNotify];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receivedErrorData:) name:NSFileHandleDataAvailableNotification object:error];
                        
        [task setStandardOutput:outputPipe];
        [task setStandardError:errorPipe];

        [tasks addObject:task];
    }

    for (NSTask *task in tasks) {
        @try {
            [task launch];
            [task waitUntilExit];

            int terminationStatus = [task terminationStatus];
            if (terminationStatus != 0) {
                NSString *message = [NSString stringWithFormat:@"ERROR: Task failed with error code %d", terminationStatus];
                [[self.xpcConnection remoteObjectProxy] receivedErrorData:message];
            }
        }
        @catch (NSException *e) {
            NSString *message = [NSString stringWithFormat:@"ERROR: Task failed with reason: %@", e.reason];
            [[self.xpcConnection remoteObjectProxy] receivedErrorData:message];
        }
    }

    [[self.xpcConnection remoteObjectProxy] finished];
}

- (void)receivedData:(NSNotification *)notif {
    NSFileHandle *fh = [notif object];
    NSData *data = [fh availableData];

    if (data.length) {
        [fh waitForDataInBackgroundAndNotify];
        NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

        [[self.xpcConnection remoteObjectProxy] receivedData:str];
    }
}

- (void)receivedErrorData:(NSNotification *)notif {
    NSFileHandle *fh = [notif object];
    NSData *data = [fh availableData];

    if (data.length) {
        [fh waitForDataInBackgroundAndNotify];
        NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

        if ([str containsString:@"stable CLI interface"]) return;

        NSArray *segments = [str componentsSeparatedByString:@"\n"];
        for (NSString *segment in segments) {
            [[self.xpcConnection remoteObjectProxy] receivedErrorData:segment];
        }
    }
}

-(BOOL)listener:(NSXPCListener *)listener shouldAcceptNewConnection:(NSXPCConnection *)newConnection {
    newConnection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(ZBSlingshotServer)];
    newConnection.exportedObject = self;
    newConnection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(ZBSlingshotClient)];
    self.xpcConnection = newConnection;

    struct stat template;
    if (lstat("/Applications/Zebra.app/Zebra", &template) == -1) { //Make sure the Zebra binary actually exists, and get our template
        NSLog(@"[Supersling] THE TRUE AND NEO CHAOS!");
        [[self.xpcConnection remoteObjectProxy] receivedData:@"THE TRUE AND NEO CHAOS"];

        return NO;
    }
    else {
        pid_t pid = newConnection.processIdentifier; //Get the process identifier

        char buffer[PATH_MAX];
        int ret = proc_pidpath(pid, buffer, sizeof(buffer)); //Get the executable path of the parent process

        struct stat response;
        lstat(buffer, &response); //Use the process path and get stat information from that

        if (ret < 1 || (template.st_dev != response.st_dev || template.st_ino != response.st_ino)) { //If the files are identical, we can execute the command
            NSLog(@"[Supersling] CHAOS, CHAOS!");
            [[self.xpcConnection remoteObjectProxy] receivedData:@"CHAOS, CHAOS!"]  ;

            return NO;
        }

        [newConnection resume];
        return YES;
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
