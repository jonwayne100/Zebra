#include <xpc/xpc.h>
#include "NSTask.h"

int main(int argc, char **argv, char **envp) {

    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    // Attempt to create the server, exit if fails
    xpc_connection_t connection = xpc_connection_create_mach_service("xyz.willy.supersling", NULL, XPC_CONNECTION_MACH_SERVICE_LISTENER);
    if (!connection) {
        HBLogDebug(@"[Supersling] Failed to create XPC server. Exiting.");
        [pool release];
        return 0;
    }

    // Configure event handler
    xpc_connection_set_event_handler(connection, ^(xpc_object_t object) {
        xpc_type_t type = xpc_get_type(object);
        if (type == XPC_TYPE_CONNECTION) {
            HBLogDebug(@"[Supersling] XPC server received incoming connection: %s", xpc_copy_description(object));

            HBLogInfo(@"[Supersling] Creating file");
            NSTask *injectionTask = [[NSTask alloc] init];
            NSArray *arguments = @[@"/var/root/hello-world.txt"];
            [injectionTask setLaunchPath:@"/bin/touch"];
            [injectionTask setArguments:arguments];

            [injectionTask launch];

            /**
             * This handler is simply a stub
             *
             * The connection should instead be passed to a controller object where
             * the controller can set it's own event handler and then resume the connection
            **/
            xpc_connection_set_event_handler(object, ^(xpc_object_t some_object) {
                HBLogDebug(@"[Supersling] XPC connection received object: %s", xpc_copy_description(some_object));
                xpc_object_t reply = xpc_dictionary_create_reply(some_object);
                if (reply) {
                    xpc_dictionary_set_string(reply, "message", "Pong");
                    HBLogDebug(@"[Supersling] XPC connection sending reply: %s", xpc_copy_description(reply));
                    xpc_connection_send_message(xpc_dictionary_get_remote_connection(some_object), reply);
                }
            });
            xpc_connection_resume(object);
        } else if (type == XPC_TYPE_ERROR) {
            HBLogDebug(@"[Supersling] XPC server error: %s", xpc_dictionary_get_string(object, XPC_ERROR_KEY_DESCRIPTION));
        } else {
            HBLogDebug(@"[Supersling] XPC server received unknown object: %s", xpc_copy_description(object));
        }
    });

    // Make connection live
    xpc_connection_resume(connection);

    // Execute run loop
    [[NSRunLoop currentRunLoop] run];

    [pool release];

    return 0;
}
