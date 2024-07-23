//
//  HelperTool.h
//
//  Created by 马治武 on 2024/7/23.
//

#import <Foundation/Foundation.h>
#import "HelperToolProtocol.h"

// This object implements the protocol which we have defined. It provides the actual behavior for the service. It is 'exported' by the service to make it available to the process hosting the service over an NSXPCConnection.
@interface HelperTool : NSObject <HelperToolProtocol>


@end
