/*
 
 File: SMJobBlessAppController.m
 Abstract: The main application controller. When the application has finished
 launching, the helper tool will be installed.
 Version: 1.5
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2013 Apple Inc. All Rights Reserved.
 
 
 */

#import "SMJobBlessAppController.h"

#import <ServiceManagement/ServiceManagement.h>
#import <Security/Authorization.h>
#import "HelperToolProtocol.h"
#import "AppSignatureChecker.h"


@implementation SMJobBlessAppController


- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
    [self->_helperInfoText setHidden:false];
    
#pragma unused(notification)
    NSError *error = nil;
    OSStatus status = AuthorizationCreate(NULL, kAuthorizationEmptyEnvironment, kAuthorizationFlagDefaults, &self->_authRef);
    if (status != errAuthorizationSuccess) {
        /* AuthorizationCreate really shouldn't fail. */
        assert(NO);
        self->_authRef = NULL;
    }
    
    // 安装 helper
    if (![self blessHelperWithLabel:@"com.apple.bsd.SMJobBlessHelper" error:&error]) {
        NSLog(@">>>>>> bless helper went wrong! %@ / %d", [error domain], (int) [error code]);
    } else {
        /* At this point, the job is available. However, this is a very
         * simple sample, and there is no IPC infrastructure set up to
         * make it launch-on-demand. You would normally achieve this by
         * using XPC (via a MachServices dictionary in your launchd.plist).
         */
        NSLog(@">>>>>> Helper is available!");
        
        // [self->_textField setHidden:false];
        [self->_helperInfoText setStringValue:[NSString stringWithFormat:@"Helper is available!"]];
        
        
        // 1. 先 XPC 应用建立连接
        [self connectToHelperTool];
        
        
        
        // 3 获取到 XPC 应用的 exportedObject，因为方法返回的是实现了这个协议的对象，所以协议的匹配很关键
        id<HelperToolProtocol> service = [self.helperToolConnection remoteObjectProxyWithErrorHandler:^(NSError * _Nonnull error) {
            NSLog(@">>>>>> get remote object proxy error: %@", error);
            dispatch_async(dispatch_get_main_queue(), ^{
                [self->_helperInfoText
                 setStringValue:[NSString stringWithFormat:@"Failed to connect to HelperTool : %@", [error domain]]
                ];
            });
        }];
        
        
        
        // 4. 远程调用
        [service performCalculationWithNumber:@1 andNumber:@2 withReply:^(NSNumber *number)  {
            NSLog(@">>>>>> performCalculationWithNumber %@",number);
            dispatch_async(dispatch_get_main_queue(), ^{
                [self->_helperInfoText setStringValue:@"Successfully connected to HelperTool"];
            });
            
            // 检查 helper
        }];
    }
    
    // 检查 APP 签名信息
    NSDictionary *appSignatureInfo = [AppSignatureChecker checkSignatureInfoForAppAtPath: [[NSBundle mainBundle] bundlePath] error:&error];
    

}


- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
#pragma unused(sender)
    return YES;
}

- (BOOL)blessHelperWithLabel:(NSString *)label error:(NSError **)errorPtr;
{
    // 1 构造申请权限所需要的参数，官方例子中没有这一步
    AuthorizationItem authItem = { kSMRightBlessPrivilegedHelper, 0, NULL, 0 };
    AuthorizationRights authRights = { 1, &authItem };
    AuthorizationFlags flags = kAuthorizationFlagDefaults | kAuthorizationFlagInteractionAllowed | kAuthorizationFlagPreAuthorize | kAuthorizationFlagExtendRights;
    
    AuthorizationRef authRef = NULL;
    // 2 申请权限，如果这一步失败了，那我们的应用就不能做任何需要用户授权的操作了；官方例子中因为少了构造参数的步骤，所以这里会变成 AuthorizationCreate(NULL, NULL, 0, &authRef)
    OSStatus status = AuthorizationCreate(&authRights, kAuthorizationEmptyEnvironment, flags, &authRef);
    if (status != errAuthorizationSuccess) {
        NSLog(@">>>>>> Failed to create AuthorizationRef, return code %i", status);
        return NO;
    } else {
        CFErrorRef error;
        // 3 使用题外话里讲到的 API 来安装我们的 XPC 应用，其中，kSMDomainSystemLaunchd 表示我们要使用 launchd 服务（这也是目前仅有的可选项），第二个参数是我们之前设置的 XPC 应用的 label
        Boolean success = SMJobBless(kSMDomainSystemLaunchd, (__bridge CFStringRef)@"com.apple.bsd.SMJobBlessHelper", authRef, &error);
        if (success) {
            NSLog(@">>>>>> job bless success");
            return YES;
        } else {
            NSLog(@">>>>>> job bless error: %@", (__bridge NSError *)error);
            CFRelease(error);
            return NO;
        }
    }
}
- (void)connectToHelperTool
// Ensures that we're connected to our helper tool.
{
    [self->_helperInfoText setStringValue:[NSString stringWithFormat:@"connecting to HelperTool"]];
    
    assert([NSThread isMainThread]);
    if (self.helperToolConnection == nil) {
        // 1 通过 label 找到特定 XPC 应用并建立连接，建议把这个连接实例保存起来，避免重复创建带来别的问题
        self.helperToolConnection = [[NSXPCConnection alloc] initWithMachServiceName:@"com.apple.bsd.SMJobBlessHelper" options:NSXPCConnectionPrivileged];
        // 2 这一步参数里的协议就是我们在 XPC 应用中声明的协议，两边的协议要对得上才能拿到 XPC 应用中暴露出来的正确对象
        self.helperToolConnection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(HelperToolProtocol)];
        // 3 大段注释是在解释为什么这里不需要担心循环引用的问题；要注意的是如果我们把连接实例存了起来，最好是像这样在 invalidationHandler 里置空，在其他地方通过 [connection invalidate]来实现断连
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-retain-cycles"
        // We can ignore the retain cycle warning because a) the retain taken by the
        // invalidation handler block is released by us setting it to nil when the block
        // actually runs, and b) the retain taken by the block passed to -addOperationWithBlock:
        // will be released when that operation completes and the operation itself is deallocated
        // (notably self does not have a reference to the NSBlockOperation).
        self.helperToolConnection.invalidationHandler = ^{
            NSLog(@">>>>>> connection invalidated");
        };
        
        self.helperToolConnection.interruptionHandler = ^{
            // Handle the connection interruption
            NSLog(@">>>>>> connection interrupted");
        };
        
        
        
#pragma clang diagnostic pop
        // 4 手动调用 resume 来建立连接，调用后 XPC 应用那边才会收到 -[listener:shouldAcceptNewConnection:] 回调
        [self.helperToolConnection resume];
    }
}


@end
