//
//  TwitterRequestFactory.h
//  TwitterSpy
//
//  Created by William on 02/10/16.
//  Copyright © 2016 William. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, GetStatusesType)
{
    GetStatusesTypeNone,
    GetStatusesTypeNormal,
    GetStatusesTypeFilter
};

@interface TwitterRequestFactory : NSObject
//Forms a request for use with the Twitter Streaming API
//there's two 'GetStatusesType' types, normal - for use with no searchText, filter - for use with searchText
//if there's no searchText to provide, nil or an empty string is fine
- (NSURLRequest *)formRequestForType:(GetStatusesType)type SearchText:(NSString *)searchText;

@end
