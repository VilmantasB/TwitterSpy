//
//  Test.m
//  Farmis
//
//  Created by Vilmantas on 28/09/16.
//  Copyright © 2016 Rento Media. All rights reserved.
//

#import "TwitterSpy.h"
#import "TwitterRequestFactory.h"

#define ARC4RANDOM_MAX 0x100000000

@interface TwitterSpy () <NSURLConnectionDelegate>
{
    dispatch_queue_t parseQueue;
}

@property (strong, nonatomic) MKMapView *map;

@property (strong, nonatomic) NSMutableArray<Tweet *> *tweets;

@property (strong, nonatomic) NSMutableData *data;
@property (strong, nonatomic) NSURLConnection *connection;
@property (strong, nonatomic) TwitterRequestFactory *requestFactory;

@property (strong, nonatomic) id<TwitterSpyDelegate> delegate;

@end

@implementation TwitterSpy

- (instancetype)initWithDelegate:(id <TwitterSpyDelegate>)delegate Map:(MKMapView *)map
{
    self = [super init];
    if (self) {
        parseQueue = dispatch_queue_create("TweetParseQueue", NULL);
        
        _requestFactory = [[TwitterRequestFactory alloc] init];
        
        _delegate = delegate;
        _map = map;
        
        _tweets = [[NSMutableArray alloc] init];
    }
    return self;
}

- (instancetype)init
{
    NSAssert(NO, @"Use initWithDelegate:Map: instead of init");
    return [super init];
}

- (void)startSpying
{
    [self startSpyingWithType:GetStatusesTypeNormal SearchText:nil];
}

- (void)startSpyingWithType:(GetStatusesType)type SearchText:(NSString *)text
{
    if (_connection) {
        [_connection cancel];
    }
    NSURLRequest *request = [_requestFactory formRequestForType:type SearchText:text];
    
    //Yes, NSURLConnection is deprecated since iOS 9, but the response has Content-type: chunked
    //and NSURLSession wasn't quite happy about it
    //or maybe I was using it wrong, somehow
    //ignoring deprecated declarations for 0 warning builds
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    _connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES];
#pragma clang diagnostic pop
}

- (void)stopSpying
{
    [_connection cancel];
}

#pragma mark -
#pragma mark - Filter setter
- (void)setFilterText:(NSString *)text
{
    if (text == nil || [text isEqualToString:@""]) {
        [self startSpyingWithType:GetStatusesTypeNormal SearchText:nil];
    }
    else {
        [self startSpyingWithType:GetStatusesTypeFilter SearchText:text];
    }
}

#pragma mark -
#pragma mark - NSURLConnectionDelegate
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    if ([(NSHTTPURLResponse *)response statusCode] == 200) {
        //request successful!
        _data = [[NSMutableData alloc] init];
    }
    else {
        //inform user that the request failed
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    dispatch_async(parseQueue, ^{
        if (data != nil) {
            [self parseData:data];
        }
    });
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    //NSLog(@"didFinish");
}

#pragma mark -
#pragma mark - Parsing
- (void)parseData:(NSData *)data
{
    NSString *aStr = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
    NSArray *messages = [aStr componentsSeparatedByString:@"\r\n"];
    
    for (NSString *message in messages) {
        NSError *error;
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:[message dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
        if (error) {
            //handle error, message doesn't "deserialize" from json
            //in this situation we are just not adding the tweet to the map
            continue;
        }
        
        //making sure the coordinate isn't nil, otherwise we can't add it to the map
        //since the sole objective is to add the tweet onto the map
        //if the tweet doesn't have a coordinate
        //just dismiss the tweet entirely
        id coordinate = [dict valueForKey:@"coordinates"];
        id text = [dict valueForKey:@"text"];
        id screenName = [[dict valueForKey:@"user"] valueForKey:@"screen_name"];
        
        //didn't find any documentation on this, so observed a couple of json objects
        //and assumed the coordinate is a dictionary of two key/value pairs
        //one being type, and second one being an array of two doubles (lon, lat)
        NSArray *coordinates = [coordinate valueForKey:@"coordinates"];
        if (coordinates != nil && [coordinates isKindOfClass:[NSArray class]] && [coordinates count] == 2) {
            if ([coordinates count] == 2) {
                double longitude = [[coordinates objectAtIndex:0] doubleValue];
                double latitude = [[coordinates objectAtIndex:1] doubleValue];
                
                //also assuming text and screen_name is always available
                Tweet *tweet = [[Tweet alloc] initWithPoster:screenName Text:text Coordinates:CLLocationCoordinate2DMake(latitude, longitude)];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (tweet) {
                        [self showTweet:tweet];
                    }
                });
            }
        }
        else if (_shouldGenerateCoordinates) {
            double latitude = [self randomLatitude];
            double longitude = [self randomLongitude];
            
            Tweet *tweet = [[Tweet alloc] initWithPoster:screenName Text:text Coordinates:CLLocationCoordinate2DMake(latitude, longitude)];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (tweet) {
                    [self showTweet:tweet];
                }
            });
        }
        
        //PS
        //there should be other checks and validations, as per twitter streaming API documentation (regard deletes, etc)
    }
}

- (CGFloat)randomLatitude
{
    return [self randomDoubleMinRange:-90 MaxRange:90];
}

- (CGFloat)randomLongitude
{
    return [self randomDoubleMinRange:-180 MaxRange:180];
}

- (double)randomDoubleMinRange:(double)minRange MaxRange:(double)maxRange
{
    return ((double)arc4random() / ARC4RANDOM_MAX) * (maxRange - minRange) + minRange;
}

#pragma mark -
#pragma mark - Tweet addition to the map
- (void)showTweet:(Tweet *)tweet
{
    [_tweets addObject:tweet];
    tweet.annotation = [self annotationForTweet:tweet];
    [_map addAnnotation:tweet.annotation];
    
    [NSTimer scheduledTimerWithTimeInterval:kTweetLifetime target:self selector:@selector(timerFired:) userInfo:tweet repeats:NO];
    //checking if delegate responds to TwitterSpy:didShowTweet: (if they don't - unrecognized selector crash)
    id delegate = _delegate;
    if ([delegate respondsToSelector:@selector(TwitterSpy:didShowTweet:)]) {
        [delegate TwitterSpy:self didShowTweet:tweet];
    }
}

- (void)timerFired:(NSTimer *)timer
{
    Tweet *tweet = timer.userInfo;
    [_tweets removeObject:tweet];
    [_map removeAnnotation:tweet.annotation];
    
    id delegate = _delegate;
    if ([delegate respondsToSelector:@selector(TwitterSpy:didRemoveTweet:)]) {
        [delegate TwitterSpy:self didRemoveTweet:tweet];
    }
}

- (MKPointAnnotation *)annotationForTweet:(Tweet *)tweet
{
    MKPointAnnotation *annotation = [[MKPointAnnotation alloc] init];
    annotation.title = tweet.poster;
    annotation.subtitle = tweet.text;
    annotation.coordinate = tweet.coordinate;
    return annotation;
}

@end
