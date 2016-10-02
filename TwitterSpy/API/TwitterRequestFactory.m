//
//  TwitterRequestFactory.m
//  TwitterSpy
//
//  Created by William on 02/10/16.
//  Copyright © 2016 William. All rights reserved.
//

#import "TwitterRequestFactory.h"
#import "NSString+Encoding.h"
#import "NSString+Random.h"
#include <CommonCrypto/CommonDigest.h>
#include <CommonCrypto/CommonHMAC.h>

static NSString *OauthConsumerKey = @"W00ULN9obGuYDyJuwNHLFtBML";
static NSString *OauthConsumerSecret = @"emRx8zZRIl7WQa2zc26Ok8g1TGAE52qcRJ76bHAiu8RljL63Lb";
static NSString *OauthAccessToken = @"780458254476402688-HR8X5UybNp8pC03ikPGxESnKwwVEvqH";
static NSString *OauthAccessTokenSecret = @"9Vq78O4nSfIFl9YvNk34vRzZhZ7ikriO7ib5TsUpzMbyI";
static NSString *OauthSignatureMethod = @"HMAC-SHA1";
static NSString *OauthVersion = @"1.0";
static NSString *StatusesPath = @"/1.1/statuses/sample.json";
static NSString *FilterStatusesPath = @"/1.1/statuses/filter.json";
static NSString *Host = @"stream.twitter.com";
static NSString *Scheme = @"https";
static NSString *HTTPMethodGet = @"GET";
static NSString *HTTPMethodPost = @"POST";

@implementation TwitterRequestFactory

#pragma mark -
#pragma mark - Request
- (NSURLRequest *)formRequestForType:(GetStatusesType)type SearchText:(NSString *)searchText
{
    NSMutableDictionary *parameters = @{ [@"oauth_consumer_key" percentEncodedString] : [OauthConsumerKey percentEncodedString] ,
                                         [@"oauth_nonce" percentEncodedString] : [[NSString randomString] percentEncodedString] ,
                                         [@"oauth_signature_method" percentEncodedString] : [OauthSignatureMethod percentEncodedString] ,
                                         [@"oauth_timestamp" percentEncodedString] : [[self oauthTimestamp] percentEncodedString] ,
                                         [@"oauth_token" percentEncodedString] : [OauthAccessToken percentEncodedString] ,
                                         [@"oauth_version" percentEncodedString] : [OauthVersion percentEncodedString] }.mutableCopy;
    
    NSString *url = [self URLWithType:type SearchText:searchText];
    NSAssert(url != nil, ([NSString stringWithFormat:@"GetStatusesTypeNone passed into %s", __PRETTY_FUNCTION__]));
    
    NSString *oauthSignature = [[self oauthSignatureFromParameters:parameters URL:url GetStatusesType:type SearchText:searchText] percentEncodedString];
    [parameters setValue:oauthSignature forKey:@"oauth_signature"];
    
    NSString *headerString = [self oauthHeaderForParameters:parameters];
    
    /*if (type == GetStatusesTypeFilter) {
        url = [NSString stringWithFormat:@"%@&track=%@", url, searchText];
    }*/
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    [request addValue:headerString forHTTPHeaderField:@"Authorization"];
    
    if (type == GetStatusesTypeNormal) {
        [request setHTTPMethod:HTTPMethodGet];
    }
    else if (type == GetStatusesTypeFilter) {
        [request setHTTPMethod:HTTPMethodPost];
        [request setHTTPBody:[[NSString stringWithFormat:@"track=%@", searchText] dataUsingEncoding:NSUTF8StringEncoding]];
    }
    
    return request;
}

#pragma mark -
#pragma mark - Helpers
- (NSArray *)sortedKeysForDictionary:(NSDictionary *)dictionary
{
    NSArray *keys = [dictionary allKeys];
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"description" ascending:YES];
    NSArray *sortedKeys = [keys sortedArrayUsingDescriptors:@[sort]];
    return sortedKeys;
}

- (NSString *)hmacsha1:(NSString *)data secret:(NSString *)key {
    
    const char *cKey  = [key cStringUsingEncoding:NSASCIIStringEncoding];
    const char *cData = [data cStringUsingEncoding:NSASCIIStringEncoding];
    
    unsigned char cHMAC[CC_SHA1_DIGEST_LENGTH];
    
    CCHmac(kCCHmacAlgSHA1, cKey, strlen(cKey), cData, strlen(cData), cHMAC);
    
    NSData *HMAC = [[NSData alloc] initWithBytes:cHMAC length:sizeof(cHMAC)];
    
    NSString *hash = [HMAC base64EncodedStringWithOptions:0];
    
    return hash;
}

#pragma mark - Timestamp
- (NSString *)oauthTimestamp
{
    NSTimeInterval timeInterval = [[NSDate date] timeIntervalSince1970];
    return [NSString stringWithFormat:@"%d", (int)timeInterval];
}

#pragma mark - URL
- (NSString *)URLWithType:(GetStatusesType)type SearchText:(NSString *)searchText
{
    if (type == GetStatusesTypeNormal)
    {
        return [NSString stringWithFormat:@"%@://%@%@", Scheme, Host, StatusesPath];
    }
    else if (type == GetStatusesTypeFilter)
    {
        return [NSString stringWithFormat:@"%@://%@%@", Scheme, Host, FilterStatusesPath];
    }
    else {
        return nil;
    }
}

#pragma mark - OAuth header
- (NSString *)oauthHeaderForParameters:(NSDictionary *)params
{
    NSArray *sortedKeys = [self sortedKeysForDictionary:params];
    NSMutableString *headerString = [[NSMutableString alloc] init];
    
    [headerString appendString:@"OAuth "];
    for (NSString *key in sortedKeys) {
        [headerString appendString:key];
        [headerString appendString:@"="];
        [headerString appendFormat:@"\"%@\"", [params valueForKey:key]];
        
        if (key != [sortedKeys lastObject]) {
            [headerString appendString:@", "];
        }
    }
    
    return headerString;
}

- (NSString *)oauthSignatureFromParameters:(NSDictionary *)params URL:(NSString *)url GetStatusesType:(GetStatusesType)type SearchText:(NSString *)searchText
{
    NSArray *sortedKeys = [self sortedKeysForDictionary:params];
    NSMutableString *parametersString = [[NSMutableString alloc] init];
    
    for (NSString *key in sortedKeys) {
        [parametersString appendString:key];
        [parametersString appendString:@"="];
        [parametersString appendString:[params valueForKey:key]];
        
        if (key != [sortedKeys lastObject]) {
            [parametersString appendString:@"&"];
        }
    }
    
    NSString *signatureBaseString = nil;
    if (type == GetStatusesTypeNormal) {
        signatureBaseString = [NSString stringWithFormat:@"%@&%@&%@", [HTTPMethodGet uppercaseString], [url percentEncodedString], [parametersString percentEncodedString]];
    }
    else if (type == GetStatusesTypeFilter)
    {
        signatureBaseString = [NSString stringWithFormat:@"%@&%@&%@%@", [HTTPMethodPost uppercaseString], [url percentEncodedString], [parametersString percentEncodedString], [[NSString stringWithFormat:@"&track=%@", searchText] percentEncodedString]];
    }
    
    NSString *signingKey = [NSString stringWithFormat:@"%@&%@", [OauthConsumerSecret percentEncodedString], [OauthAccessTokenSecret percentEncodedString]];
    NSString *oauthSignature = [self hmacsha1:signatureBaseString secret:signingKey];
    
    return oauthSignature;
}

- (NSString *)httpMethodForStatusesType:(GetStatusesType)type
{
    if (type == GetStatusesTypeNormal) {
        return HTTPMethodGet;
    }
    else if (type == GetStatusesTypeFilter) {
        return HTTPMethodPost;
    }
    return nil;
}

@end
