
//  ConnectionVerifier.m
//  TCCKronosExtension




#import "ConnectionVerifier.h"


#define CS_VALID 0x00000001
#define CS_RUNTIME 0x00010000

@interface NSXPCConnection(PrivateAuditToken)

@property (nonatomic, readonly) audit_token_t auditToken;

@end

@implementation ConnectionVerifier

// ref : https://github.com/PhorionTech/Kronos/blob/0d176e19d702e01d6bcc1f1ff7681b946dc9ee6f/TCCKronosExtension/XPC/ConnectionVerifier.m
// ref : https://developer.apple.com/documentation/security/1395809-seccodecopysigninginformation

+ (NSString *)auditTokenToString:(audit_token_t)auditToken {
    // 501 501 20 501 20 28737 100004 538096
    NSMutableString *result = [NSMutableString string];
    for (int i = 0; i < 8; i++) {
        [result appendFormat:@"%u ", auditToken.val[i]];
    }
    return [result stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}

+ (BOOL)isValid:(NSXPCConnection*)connection {
    
    
    //status
    OSStatus status = !errSecSuccess;
    CFErrorRef error = nil;

    // 审计令牌 这个结构体通常在进程间通信或系统调用时由内核提供。
    audit_token_t auditToken = {0};
    auditToken = connection.auditToken;
    SecTaskRef taskRef = 0;
    
    //code ref
    SecCodeRef codeRef = NULL;
    //code signing info
    CFDictionaryRef csInfo = NULL;
    //cs flags
    // uint32_t csFlags = 0;
    
    // NSString* requirement = [NSString stringWithFormat:@"identifier \"com.apple.bsd.SMJobBlessApp\""];
    NSString* requirement = [NSString stringWithFormat:@"identifier \"com.apple.bsd.SMJobBlessApp\" and anchor apple generic and certificate leaf[subject.CN] = \"Apple Development: marlkiller@vip.qq.com (L79ZQ6T579)\" and certificate 1[field.1.2.840.113635.100.6.2.1] /* exists */"];
    
    NSLog(@">>>>>> auditTokenToString = %@",[self auditTokenToString:auditToken]);
    
    
    // 用于根据指定的属性创建或获取一个代码对象,这里根据主应用程序的审计令牌获取到的主应用程序的 SecCodeRef
    status = SecCodeCopyGuestWithAttributes(NULL, (__bridge CFDictionaryRef)(@{
        (NSString *)kSecGuestAttributeAudit : [NSData dataWithBytes:&auditToken length:sizeof(audit_token_t)]
    }), kSecCSDefaultFlags, &codeRef);
    
    if(errSecSuccess != status)
    {
        NSLog(@">>>>>>> SecCodeCopyGuestWithAttributes failed with status = %d", (int)status);
        return NO;
    }
    
    // 从一个动态代码对象 (SecCodeRef) 创建一个静态代码对象 (SecStaticCodeRef)
    // SecCodeRef : 表示正在运行的进程或已加载的可执行文件的代码签名,包含动态属性，如进程的当前状态、安全性上下文等。
    // SecStaticCodeRef : 表示一个不可变的、静态的代码签名。通常用于代码签名验证、签名信息提取等静态操作。
    SecStaticCodeRef staticCodeRef = NULL;
    status = SecCodeCopyStaticCode(codeRef, kSecCSDefaultFlags, &staticCodeRef);
    if (status != errSecSuccess) {
        NSLog(@">>>>>> SecCodeCopyStaticCode failed with status = %d", (int)status);
        return NO;
    }

    // 检查静态代码对象 (SecStaticCodeRef) 的签名有效性
    status = SecStaticCodeCheckValidity(staticCodeRef, 0xd, 0);
    if (status != errSecSuccess) {
        NSLog(@">>>>>> SecStaticCodeCheckValidity failed with status = %d", (int)status);
        return NO;
    }
    
    
    // un used validate code
    // status = SecCodeCheckValidity(codeRef, kSecCSDefaultFlags, NULL);
    // if(errSecSuccess != status)
    // {
    //     NSLog(@">>>>>>> SecCodeCheckValidity failed with status = %d", (int)status);
    //     return NO;
    // }
    
    // 获取代码对象的签名信息。通过调用这个函数，你可以提取代码签名的详细信息，例如签名证书、签名时间等
    status = SecCodeCopySigningInformation(staticCodeRef, kSecCSSigningInformation, &csInfo);
    if(errSecSuccess != status)
    {
        NSLog(@">>>>>>> SecCodeCopySigningInformation failed with status = %d", (int)status);
        return NO;
    }
    
    
    // 检查签名是否有效 flags [patch fix]
    SecCSFlags flags;
    CFNumberRef flagsNumber = (CFNumberRef)CFDictionaryGetValue(csInfo, kSecCodeInfoFlags);
   if (flagsNumber == NULL) {
       NSLog(@">>>>>>> kSecCodeInfoFlags is nil");
        return NO;
   }
    CFNumberGetValue(flagsNumber, kCFNumberSInt32Type, &flags);
    NSLog(@">>>>>> flags %d",flags);
    

    if( !(CS_VALID & flags) &&
        !(CS_RUNTIME & flags) )
    {
        NSLog(@">>>>>> Client app does not have hardened runtime");
        return NO;
    }
    

    
    // [patch fix]
    CFDictionaryRef entitlementsDict = (CFDictionaryRef)CFDictionaryGetValue(csInfo, kSecCodeInfoEntitlementsDict);
    if (entitlementsDict != NULL) {
        NSDictionary *entitlements = (__bridge NSDictionary *)entitlementsDict;
//        >>>>>> Entitlements: {
//            "com.apple.security.cs.allow-dyld-environment-variables" = 1;
//            "com.apple.security.cs.allow-jit" = 1;
//            "com.apple.security.cs.allow-unsigned-executable-memory" = 1;
//            "com.apple.security.cs.disable-executable-page-protection" = 1;
//            "com.apple.security.cs.disable-library-validation" = 1;
//            "com.apple.security.get-task-allow" = 1;
//        }
        NSLog(@">>>>>> Entitlements: %@", entitlements);
    } else {
        NSLog(@">>>>>> Entitlements dictionary not found");
    }

        
//    NSString *teamIdentifier = nil;
//    CFStringRef teamIdRef = (CFStringRef)CFDictionaryGetValue(csInfo, kSecCodeInfoTeamIdentifier);
//    if (teamIdRef) {
//        teamIdentifier = (__bridge_transfer NSString *)teamIdRef;
//        NSLog(@">>>>>>> kSecCodeInfoTeamIdentifier = %@", teamIdentifier);
//    }else {
//        NSLog(@">>>>>>> kSecCodeInfoTeamIdentifier is nil");
//        return NO;
//    }
//    
//    NSString *identifier = nil;
//    CFStringRef identifierRef = (CFStringRef)CFDictionaryGetValue(csInfo, kSecCodeInfoIdentifier);
//    if (identifierRef) {
//        identifier = (__bridge_transfer NSString *)identifierRef;
//        NSLog(@">>>>>>> kSecCodeInfoIdentifier = %@", identifier);
//    }else {
//        NSLog(@">>>>>>> kSecCodeInfoIdentifier is nil");
//        return NO;
//    }
        

    CFPropertyListRef plist = CFDictionaryGetValue(csInfo, kSecCodeInfoPList);
    CFStringRef shortVersionString = CFDictionaryGetValue(plist, CFSTR("CFBundleShortVersionString"));

//    NSData *plistData = CFPropertyListCreateXMLData(kCFAllocatorDefault, plist);
//    NSString *plistString = [[NSString alloc] initWithData:plistData encoding:NSUTF8StringEncoding];
//                NSLog(@">>>>>> Info.plist content:\n%@", plistString);

    
    
    // 验证代码的签名是否符合指定的条件
    // requirement = @"anchor apple generic and certificate leaf[subject.CN] = \"Apple Development: marlkiller@vip.qq.com (L79ZQ6T579)\"";
    SecRequirementRef requirement_ref = NULL;
    status = SecRequirementCreateWithString((__bridge CFStringRef)requirement, kSecCSDefaultFlags, &requirement_ref);
    if (status != errSecSuccess) {
        NSLog(@">>>>>> SecRequirementCreateWithString failed with status = %d", (int)status);
        return NO;
    }
    NSLog(@">>>>>> requirement_ref = %@",requirement_ref);
    
    // 验证代码的签名是否符合特定的要求，并返回详细的错误信息 [patch fix]
    status = SecCodeCheckValidityWithErrors(codeRef, kSecCSDefaultFlags, requirement_ref,&error);
    if (status != errSecSuccess) {
        NSLog(@">>>>>> SecCodeCheckValidityWithErrors failed with status = %d", (int)status);
        return NO;
    }
    
    
    //step 1: create task ref
    // uses NSXPCConnection's (private) 'auditToken' iVar
//    taskRef = SecTaskCreateWithAuditToken(NULL, connection.auditToken);
//    if(NULL == taskRef)
//    {
//        NSLog(@">>>>>>> Failed to create task ref");
//        return NO;
//    }
    
    //step 2: validate
    // check that client is signed with Objective-See's and it's LuLu
//    if(errSecSuccess != (status = SecTaskValidateForRequirement(taskRef, (__bridge CFStringRef)(requirement))))
//    {
//        NSLog(@">>>>>>> SecTaskValidateForRequirement failed with status = %d", (int)status);
//        return NO;
//    }
    
    return YES;
}

@end
