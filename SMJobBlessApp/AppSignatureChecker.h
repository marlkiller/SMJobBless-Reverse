#import <Foundation/Foundation.h>

@interface AppSignatureChecker : NSObject

+ (NSDictionary *)checkSignatureInfoForAppAtPath:(NSString *)appPath error:(NSError **)error;
//+ (NSDictionary *)checkSignatureInfoForHelperWithMachServiceName:(NSString *)machServiceName error:(NSError **)error;

@end
