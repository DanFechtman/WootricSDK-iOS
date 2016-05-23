//
//  WTRApiClientTests.m
//  WootricSDK
//
//  Created by Diego Serrano on 5/11/16.
//  Copyright © 2016 Wootric. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "WTRApiClient.h"

@interface WTRApiClientTests : XCTestCase

@property (nonatomic, strong) WTRApiClient *apiClient;

@end


@interface WTRApiClient (Tests)

@property (nonatomic, strong) NSString *baseAPIURL;
@property (nonatomic, strong) NSString *surveyServerURL;
@property (nonatomic, strong) NSString *accessToken;
@property (nonatomic, strong) NSURLSession *wootricSession;
@property (nonatomic, strong) NSNumber *userID;
@property (nonatomic, strong) NSNumber *accountID;
@property (nonatomic, strong) NSString *uniqueLink;
@property (nonatomic, assign) BOOL endUserAlreadyUpdated;
@property (nonatomic) int priority;

- (NSMutableURLRequest *)requestWithURL:(NSURL *)url HTTPMethod:(NSString *)httpMethod andHTTPBody:(NSString *)httpBody;
- (NSString *)percentEscapeString:(NSString *)string;
- (void)createEndUser:(void (^)(NSInteger endUserID))endUserWithID;
- (void)getEndUserWithEmail:(void (^)(NSInteger endUserID))endUserWithID;
- (void)authenticate:(void (^)())authenticated;
- (NSString *)paramsWithScore:(NSInteger)score endUserID:(long)endUserID userID:(NSNumber *)userID accountID:(NSNumber *)accountID uniqueLink:(nonnull NSString *)uniqueLink priority:(int)priority text:(nullable NSString *)text;
- (NSString *)randomString;
- (NSString *)buildUniqueLinkAccountToken:(NSString *)accountToken endUserEmail:(NSString *)endUserEmail date:(NSTimeInterval)date randomString:(NSString *)randomString;

@end

@implementation WTRApiClientTests

- (void)setUp {
  [super setUp];
  
  _apiClient = [WTRApiClient sharedInstance];
}

- (void)tearDown {
  [super tearDown];
  _apiClient.settings.externalCreatedAt = nil;
  _apiClient.settings.surveyImmediately = NO;
  _apiClient.settings.firstSurveyAfter = @0;
  _apiClient.priority = 0;
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  [defaults setBool:NO forKey:@"surveyed"];
  [defaults setDouble:0 forKey:@"lastSeenAt"];
}

-(void)testInstance {
  XCTAssertNotNil(_apiClient, "WTRApiClient instance should not have been nil.");
  
  XCTAssertEqualObjects(_apiClient.baseAPIURL, @"https://api.wootric.com", @"baseAPIURL should have been equal to https://api.wootric.com");
  
  XCTAssertEqualObjects(_apiClient.surveyServerURL, @"https://survey.wootric.com/eligible.json", @"surveyServerURL should have been equal to https://survey.wootric.com/eligible.json");
  
  XCTAssertNotNil(_apiClient.wootricSession, "wootricSession should not have been nil.");
  
  XCTAssertNotNil(_apiClient.settings, "settings should not have been nil.");
  
  XCTAssertEqualObjects(_apiClient.apiVersion, @"api/v1", @"apiVersion should have been equal to api/v1");
  
  XCTAssertEqual(_apiClient.priority, 0, @"priority should have been equal to 0");
}

- (void)testCheckConfiguration {
  
  _apiClient.clientID = @"";
  _apiClient.clientSecret = @"";
  _apiClient.accountToken = @"";
  
  XCTAssertFalse([_apiClient checkConfiguration]);
  
  _apiClient.clientID = @"clientIDtestString";
  _apiClient.clientSecret = @"clientSecretTestString";
  _apiClient.accountToken = @"";
  XCTAssertFalse([_apiClient checkConfiguration]);
  
  _apiClient.clientID = @"";
  _apiClient.clientSecret = @"clientSecretTestString";
  _apiClient.accountToken = @"";
  XCTAssertFalse([_apiClient checkConfiguration]);
  
  _apiClient.clientID = @"";
  _apiClient.clientSecret = @"";
  _apiClient.accountToken = @"NPS-token";
  XCTAssertFalse([_apiClient checkConfiguration]);
  
  _apiClient.clientID = @"clientIDtestString";
  _apiClient.clientSecret = @"clientSecretTestString";
  _apiClient.accountToken = @"";
  XCTAssertFalse([_apiClient checkConfiguration]);
  
  _apiClient.clientID = @"clientIDtestString";
  _apiClient.clientSecret = @"";
  _apiClient.accountToken = @"NPS-token";
  XCTAssertFalse([_apiClient checkConfiguration]);
  
  
  _apiClient.clientID = @"";
  _apiClient.clientSecret = @"clientSecretTestString";
  _apiClient.accountToken = @"NPS-token";
  XCTAssertFalse([_apiClient checkConfiguration]);
  
  _apiClient.clientID = @"clientIDtestString";
  _apiClient.clientSecret = @"clientSecretTestString";
  _apiClient.accountToken = @"NPS-token";
  XCTAssertTrue([_apiClient checkConfiguration]);
}

- (void)testRandomStringLength {
  XCTAssertEqual([[_apiClient randomString] length], 16);
}

- (void)testBuildUniqueLink {
  _apiClient.accountToken = @"testAccountToken";
  _apiClient.settings.endUserEmail = @"test@example.com";
  NSString *randomString = @"16charrandstring";
  NSTimeInterval date = 1234567890;
  
  XCTAssertEqualObjects([_apiClient buildUniqueLinkAccountToken:_apiClient.accountToken
                                            endUserEmail:_apiClient.settings.endUserEmail
                                                    date:date
                                            randomString:randomString],
                 @"1ed9f1c96018e2d577b3f864dc59dffe2baccc7103f6dcdadc40c3b6ec98cb0b");
}

- (void)testResponseParams {
  static NSString *expectedResponse = @"origin_url=com.wootric.WootricSDK-Demo&end_user[id]=12345678&survey[channel]=mobile&survey[unique_link]=5d8220d5b96ec1e0c4389a0a5951c05c3b1b998e53abbb11b14b9da5c2c0a81e&priority=0&score=9";
  static NSString *expectedResponseAccountId = @"origin_url=com.wootric.WootricSDK-Demo&end_user[id]=12345678&survey[channel]=mobile&survey[unique_link]=5d8220d5b96ec1e0c4389a0a5951c05c3b1b998e53abbb11b14b9da5c2c0a81e&priority=0&score=9&account_id=1234";
  
  static NSString *expectedResponseAccountIdText = @"origin_url=com.wootric.WootricSDK-Demo&end_user[id]=12345678&survey[channel]=mobile&survey[unique_link]=5d8220d5b96ec1e0c4389a0a5951c05c3b1b998e53abbb11b14b9da5c2c0a81e&priority=0&score=9&text=test&account_id=1234";
  
  _apiClient.settings.originURL = @"com.wootric.WootricSDK-Demo";
  NSInteger score = 9;
  NSInteger endUserID = 12345678;
  NSNumber *userID = nil;
  NSNumber *accountID = nil;
  NSString *uniqueLink = @"5d8220d5b96ec1e0c4389a0a5951c05c3b1b998e53abbb11b14b9da5c2c0a81e";
  NSString *text = nil;
  int priority = 0;
  
  NSString *params = [_apiClient paramsWithScore:score endUserID:endUserID userID:userID accountID:accountID uniqueLink:uniqueLink priority:priority text:nil];
  XCTAssertEqualObjects(params, expectedResponse, "Should not have account_id nor text in params");
  
  params = [_apiClient paramsWithScore:score endUserID:endUserID userID:userID accountID:accountID uniqueLink:uniqueLink priority:priority text:text];
  XCTAssertEqualObjects(params, expectedResponse, "Should not have account_id nor text in params");
  
  accountID = @1234;
  params = [_apiClient paramsWithScore:score endUserID:endUserID userID:userID accountID:accountID uniqueLink:uniqueLink priority:priority text:text];
  XCTAssertEqualObjects(params, expectedResponseAccountId);
  
  text = @"test";
  params = [_apiClient paramsWithScore:score endUserID:endUserID userID:userID accountID:accountID uniqueLink:uniqueLink priority:priority text:text];
  XCTAssertEqualObjects(params, expectedResponseAccountIdText);
}


- (void)testDeclineParams {
  static NSString *expectedResponse = @"origin_url=com.wootric.WootricSDK-Demo&end_user[id]=12345678&survey[channel]=mobile&survey[unique_link]=5d8220d5b96ec1e0c4389a0a5951c05c3b1b998e53abbb11b14b9da5c2c0a81e&priority=0";
  static NSString *expectedResponseAccountId = @"origin_url=com.wootric.WootricSDK-Demo&end_user[id]=12345678&survey[channel]=mobile&survey[unique_link]=5d8220d5b96ec1e0c4389a0a5951c05c3b1b998e53abbb11b14b9da5c2c0a81e&priority=0&account_id=1234";
  
  _apiClient.settings.originURL = @"com.wootric.WootricSDK-Demo";
  NSInteger endUserID = 12345678;
  NSNumber *userID = nil;
  NSNumber *accountID = nil;
  NSString *uniqueLink = @"5d8220d5b96ec1e0c4389a0a5951c05c3b1b998e53abbb11b14b9da5c2c0a81e";
  int priority = 0;
  
  NSString *params = [_apiClient paramsWithScore:-1 endUserID:endUserID userID:userID accountID:accountID uniqueLink:uniqueLink priority:priority text:nil];
  XCTAssertEqualObjects(params, expectedResponse);
  
  accountID = @1234;
  params = [_apiClient paramsWithScore:-1 endUserID:endUserID userID:userID accountID:accountID uniqueLink:uniqueLink priority:priority text:nil];
  XCTAssertEqualObjects(params, expectedResponseAccountId);
}

- (void)testPriorityIncreases {
  
  _apiClient.settings.originURL = @"com.wootric.WootricSDK-Demo";
  NSInteger score = 9;
  NSInteger endUserID = 12345678;
  NSNumber *userID = nil;
  NSNumber *accountID = nil;
  NSString *uniqueLink = @"5d8220d5b96ec1e0c4389a0a5951c05c3b1b998e53abbb11b14b9da5c2c0a81e";
  _apiClient.priority = 0;
  
  NSString *params = [_apiClient paramsWithScore:score endUserID:endUserID userID:userID accountID:accountID uniqueLink:uniqueLink priority:_apiClient.priority text:nil];
  XCTAssertEqual(_apiClient.priority, 1, "priority should be 1");
  params = [_apiClient paramsWithScore:score endUserID:endUserID userID:userID accountID:accountID uniqueLink:uniqueLink priority:_apiClient.priority text:nil];
  params = [_apiClient paramsWithScore:score endUserID:endUserID userID:userID accountID:accountID uniqueLink:uniqueLink priority:_apiClient.priority text:nil];
  XCTAssertEqual(_apiClient.priority, 3, "priority should be 3");
}

@end
