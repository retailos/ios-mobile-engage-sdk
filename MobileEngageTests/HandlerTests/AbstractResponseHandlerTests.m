//
// Copyright (c) 2017 Emarsys. All rights reserved.
//

#import <CoreSDK/EMSTimestampProvider.h>
#import "Kiwi.h"
#import "FakeResponseHandler.h"

SPEC_BEGIN(AbstractResponseHandlerTests)

        __block EMSTimestampProvider *timestampProvider;

        beforeEach(^{
            timestampProvider = [EMSTimestampProvider new];
        });

        describe(@"AbstractResponseHandler", ^{

            it(@"should call handleResponse: when shouldHandleResponse: returns true", ^{
                FakeResponseHandler *fakeResponseHandler = [FakeResponseHandler new];
                fakeResponseHandler.shouldHandle = YES;

                EMSResponseModel *response = [[EMSResponseModel alloc] initWithStatusCode:200
                                                                                  headers:@{}
                                                                                     body:nil
                                                                             requestModel:[EMSRequestModel mock]
                                                                                timestamp:[NSDate date]];

                [fakeResponseHandler processResponse:response];

                [[fakeResponseHandler.handledResponseModel should] equal:response];
            });

            it(@"should not call handleResponse: when shouldHandleResponse: returns false", ^{
                FakeResponseHandler *fakeResponseHandler = [FakeResponseHandler new];
                fakeResponseHandler.shouldHandle = NO;

                EMSResponseModel *response = [[EMSResponseModel alloc] initWithStatusCode:200
                                                                                  headers:@{}
                                                                                     body:nil
                                                                             requestModel:[EMSRequestModel mock]
                                                                                timestamp:[NSDate date]];
                [fakeResponseHandler processResponse:response];

                [[fakeResponseHandler.handledResponseModel should] beNil];
            });

        });

SPEC_END