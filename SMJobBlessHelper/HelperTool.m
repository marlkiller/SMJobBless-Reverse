//
//  HelperTool.m
//
//

#import "HelperTool.h"

@implementation HelperTool


// This implements the example protocol. Replace the body of this class with the implementation of this service's protocol.
- (void)performCalculationWithNumber:(NSNumber *)firstNumber andNumber:(NSNumber *)secondNumber withReply:(void (^)(NSNumber *))reply {
    NSInteger result = firstNumber.integerValue + secondNumber.integerValue;
    NSLog(@">>>>>> performCalculationWithNumber %@,%@",firstNumber,secondNumber);
    reply(@(result));
}



@end

