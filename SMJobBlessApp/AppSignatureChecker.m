#import "AppSignatureChecker.h"
#import <Security/Security.h>

@implementation AppSignatureChecker

+ (NSDictionary *)checkSignatureInfoForAppAtPath:(NSString *)appPath error:(NSError **)error {
    SecStaticCodeRef staticCode = NULL;
    CFDictionaryRef signingInfo = NULL;
    
    NSURL *appURL = [NSURL fileURLWithPath:appPath];
    OSStatus status = SecStaticCodeCreateWithPath((__bridge CFURLRef)appURL, kSecCSDefaultFlags, &staticCode);
    if (status != errSecSuccess) {
        if (error) {
            *error = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:@{NSLocalizedDescriptionKey : @"Failed to create static code"}];
        }
        return nil;
    }
    
    status = SecCodeCopySigningInformation(staticCode, kSecCSSigningInformation, &signingInfo);
    if (status != errSecSuccess) {
        if (error) {
            *error = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:@{NSLocalizedDescriptionKey : @"Failed to copy signing information"}];
        }
        return nil;
    }
    NSString *teamID = (__bridge NSString *)CFDictionaryGetValue(signingInfo, kSecCodeInfoTeamIdentifier);
    NSString *signName = (__bridge NSString *)CFDictionaryGetValue(signingInfo, kSecCodeInfoIdentifier);
    NSLog(@"%@", [NSString stringWithFormat:@">>>>>> Team ID: %@, Sign Name: %@", teamID, signName]);
    
    // designated => anchor apple generic and identifier "com.nssurge.surge-mac" and (certificate leaf[field.1.2.840.113635.100.6.1.9] /* exists */ or certificate 1[field.1.2.840.113635.100.6.2.6] /* exists */ and certificate leaf[field.1.2.840.113635.100.6.1.13] /* exists */ and certificate leaf[subject.OU] = YCKFLA6N72)
    NSDictionary *result = ( NSDictionary *)signingInfo;
    return result;
}

//+ (NSDictionary *)checkSignatureInfoForHelperWithMachServiceName:(NSString *)machServiceName error:(NSError **)error {
//    NSXPCConnection *connection = [[NSXPCConnection alloc] initWithMachServiceName:machServiceName options:0];
//    [connection resume];
////
//    audit_token_t auditToken;
//    [connection getAuditToken:&auditToken];
//
//    pid_t pid;
//    audit_token_to_au32(auditToken, NULL, NULL, NULL, NULL, NULL, &pid, NULL, NULL);
//
//    SecCodeRef code = NULL;
//    SecCodeCopyGuestWithAttributes(NULL, (__bridge CFDictionaryRef)@{(__bridge NSString *)kSecGuestAttributePid: @(pid)}, kSecCSDefaultFlags, &code);
//
//    if (!code) {
//        if (error) {
//            *error = [NSError errorWithDomain:NSOSStatusErrorDomain code:errSecParam userInfo:@{NSLocalizedDescriptionKey : @"Failed to copy guest code"}];
//        }
//        return nil;
//    }
//
//    CFDictionaryRef signingInfo = NULL;
//    OSStatus status = SecCodeCopySigningInformation(code, kSecCSSigningInformation, &signingInfo);
//    if (status != errSecSuccess) {
//        if (error) {
//            *error = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:@{NSLocalizedDescriptionKey : @"Failed to copy signing information"}];
//        }
//        return nil;
//    }
//
//    NSDictionary *result = (__bridge_transfer NSDictionary *)signingInfo;
//    return result;
//
//}

@end
