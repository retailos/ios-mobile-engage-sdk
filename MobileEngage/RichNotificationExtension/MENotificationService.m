//
//  Copyright © 2017. Emarsys. All rights reserved.
//

#import <CoreSDK/EMSDictionaryValidator.h>
#import "MENotificationService.h"
#import "UNNotificationAttachment+MobileEngage.h"

#define IMAGE_URL @"image_url"

@interface MENotificationService ()

@property(nonatomic, strong) void (^contentHandler)(UNNotificationContent *contentToDeliver);
@property(nonatomic, strong) UNMutableNotificationContent *bestAttemptContent;

@end

@implementation MENotificationService

#pragma mark - UNNotificationServiceExtension

- (void)didReceiveNotificationRequest:(UNNotificationRequest *)request
                   withContentHandler:(void (^)(UNNotificationContent *_Nonnull))contentHandler {
    self.contentHandler = contentHandler;
    self.bestAttemptContent = [self mutableCopyOfContent:request];

    UNMutableNotificationContent *content = [self mutableCopyOfContent:request];
    if (!content) {
        contentHandler(request.content);
        return;
    }

    NSDictionary *actionsDict = [self extractActionsDictionaryFromContent:content];
    if (actionsDict) {
        NSMutableArray *actions = [NSMutableArray array];
        [actionsDict enumerateKeysAndObjectsUsingBlock:^(NSString *actionId, NSDictionary *actionDict, BOOL *stop) {
            UNNotificationAction *action = [self createActionFromActionDictionary:actionDict
                                                                         actionId:actionId];
            if (action) {
                [actions addObject:action];
            }
        }];
        NSString *const categoryIdentifier = [NSUUID UUID].UUIDString;
        UNNotificationCategory *category = [UNNotificationCategory categoryWithIdentifier:categoryIdentifier
                                                                                  actions:actions
                                                                        intentIdentifiers:@[]
                                                                                  options:0];
        content.categoryIdentifier = categoryIdentifier;

        [[UNUserNotificationCenter currentNotificationCenter] setNotificationCategories:[NSSet setWithArray:@[category]]];
    }

    NSArray<UNNotificationAttachment *> *attachments = [self attachmentsForContent:request.content];
    if (attachments) {
        content.attachments = attachments;
    }

    contentHandler(content.copy);
}

- (void)serviceExtensionTimeWillExpire {
    self.contentHandler(self.bestAttemptContent);
}

- (UNMutableNotificationContent *)mutableCopyOfContent:(UNNotificationRequest *)request {
    return (UNMutableNotificationContent *) [request.content mutableCopy];
}

- (NSArray<UNNotificationAttachment *> *)attachmentsForContent:(UNNotificationContent *)content {
    NSURL *mediaUrl = [NSURL URLWithString:content.userInfo[IMAGE_URL]];
    NSArray<UNNotificationAttachment *> *attachments;
    if (mediaUrl) {
        UNNotificationAttachment *attachment = [UNNotificationAttachment attachmentWithMediaUrl:mediaUrl
                                                                                        options:nil];
        if (attachment) {
            attachments = @[attachment];
        }
    }
    return attachments;
}

- (UNNotificationAction *)createActionFromActionDictionary:(NSDictionary *)actionDictionary
                                                  actionId:(NSString *)actionId {
    UNNotificationAction *result;
    NSArray *commonKeyErrors = [actionDictionary validate:^(EMSDictionaryValidator *validate) {
        [validate valueExistsForKey:@"title" withType:[NSString class]];
        [validate valueExistsForKey:@"type" withType:[NSString class]];
    }];
    if ([commonKeyErrors count] == 0) {
        NSArray *typeSpecificErrors;
        NSString *type = actionDictionary[@"type"];
        if ([type isEqualToString:@"MEAppEvent"]) {
            typeSpecificErrors = [actionDictionary validate:^(EMSDictionaryValidator *validate) {
                [validate valueExistsForKey:@"name" withType:[NSString class]];
            }];
        } else if ([type isEqualToString:@"OpenExternalUrl"]) {
            typeSpecificErrors = [actionDictionary validate:^(EMSDictionaryValidator *validate) {
                [validate valueExistsForKey:@"url" withType:[NSString class]];
            }];
        }
        if (typeSpecificErrors && [typeSpecificErrors count] == 0) {
            result = [UNNotificationAction actionWithIdentifier:actionId
                                                          title:actionDictionary[@"title"]
                                                        options:UNNotificationActionOptionNone];
        }
    }
    return result;
}

- (NSDictionary *)extractActionsDictionaryFromContent:(UNMutableNotificationContent *)content {
    NSDictionary *actionsDict;
    NSArray *emsErrors = [content.userInfo validate:^(EMSDictionaryValidator *validate) {
        [validate valueExistsForKey:@"ems"
                           withType:[NSDictionary class]];
    }];
    if ([emsErrors count] == 0) {
        NSDictionary *ems = content.userInfo[@"ems"];
        NSArray *actionsErrors = [ems validate:^(EMSDictionaryValidator *validate) {
            [validate valueExistsForKey:@"actions"
                               withType:[NSDictionary class]];
        }];
        if ([actionsErrors count] == 0) {
            actionsDict = content.userInfo[@"ems"][@"actions"];
        }
    }
    return actionsDict;
}

@end
