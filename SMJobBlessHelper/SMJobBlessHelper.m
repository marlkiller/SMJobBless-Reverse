//
//  SMJobBlessHelper.m
//
//  Created by voidm on 2024/7/23.
//

#import <Foundation/Foundation.h>
#import "HelperTool.h"
#import <Security/Security.h>
#import "ConnectionVerifier.h"

@interface ServiceDelegate : NSObject <NSXPCListenerDelegate>

@property (nonatomic, readonly) audit_token_t auditToken;

@end

@implementation ServiceDelegate


- (BOOL)listener:(NSXPCListener *)listener shouldAcceptNewConnection:(NSXPCConnection *)newConnection {
    
    NSLog(@">>>>>> shouldAcceptNewConnection");
    
    if ([ConnectionVerifier isValid:newConnection] == NO) {
        return NO;
    }
    
    
    // This method is where the NSXPCListener configures, accepts, and resumes a new incoming NSXPCConnection.
    
    // Configure the connection.
    // First, set the interface that the exported object implements.
    newConnection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(HelperToolProtocol)];
    
    // Next, set the object that the connection exports. All messages sent on the connection to this service will be sent to the exported object to handle. The connection retains the exported object.
    HelperTool *exportedObject = [HelperTool new];
    newConnection.exportedObject = exportedObject;
    
    // Resuming the connection allows the system to deliver more incoming messages.
    [newConnection resume];
    
    // Returning YES from this method tells the system that you have accepted this connection. If you want to reject the connection for some reason, call -invalidate on the connection and return NO.
    return YES;
}

@end



int main(int argc, const char *argv[])
{
    // https://davidleee.com/2020/07/20/ipc-for-macOS/
    
    NSLog(@">>>>>> help started");
    // Create the delegate for the service.
    ServiceDelegate *delegate = [ServiceDelegate new];
    
    // Set up the one NSXPCListener for this service. It will handle all incoming connections.
    
    NSXPCListener *listener = [[NSXPCListener alloc] initWithMachServiceName:@"com.apple.bsd.SMJobBlessHelper"];
    // The latter is only useful for regular XPC service (which would be stored in the App's bundle, not in /Library/.... If you mix it up, you'll get a crash report in Console.app that will say:
    // NSXPCListener *listener = [NSXPCListener serviceListener];
    
    listener.delegate = delegate;
    
    // Resuming the serviceListener starts this service. This method does not return.
    [listener resume];
    
    [[NSRunLoop currentRunLoop] run];
    return 0;
}
