//
// Copyright (c) 2017 Emarsys. All rights reserved.
//

#import "MEIAMOpenExternalLink.h"
#import <UIKit/UIKit.h>
#import "MEOsVersionUtils.h"

#define kExternalLink @"url"

@implementation MEIAMOpenExternalLink

+ (NSString *)commandName {
    return @"openExternalLink";
}

- (void)handleMessage:(NSDictionary *)message
          resultBlock:(MEIAMJSResultBlock)resultBlock {
    UIApplication *application = [UIApplication sharedApplication];
    NSString *externalLink = message[kExternalLink];
    NSURL *url = [NSURL URLWithString:externalLink];
    NSString *eventId = message[@"id"];
    
    if ([application canOpenURL:url]) {
        if (SYSTEM_VERSION_LESS_THAN(@"10.0")) {
            resultBlock(@{@"success": @([application openURL:url])});
        } else {
            [application openURL:url
                         options:nil
               completionHandler:^(BOOL success) {
                   resultBlock(@{@"success": @(success), @"id": eventId});
               }];
        }
    } else {
        resultBlock(@{@"success": @NO, @"id": eventId});
    }
}

@end
