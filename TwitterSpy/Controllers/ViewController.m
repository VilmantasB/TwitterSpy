//
//  ViewController.m
//  TwitterSpy
//
//  Created by William on 26/09/16.
//  Copyright © 2016 William. All rights reserved.
//

#import "ViewController.h"
#import "TwitterSpy.h"
#import <MapKit/MapKit.h>

@interface ViewController () <TwitterSpyDelegate, UISearchBarDelegate>

@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (strong, nonatomic) UISearchBar *searchBar;

@property (strong, nonatomic) TwitterSpy *spy;
@property (strong, nonatomic) NSMutableArray<Tweet *> *tweets;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    _spy = [[TwitterSpy alloc] initWithDelegate:self Map:_mapView];
    _spy.shouldGenerateCoordinates = YES;
    [_spy startSpying];
    [self initSearchBar];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [_spy stopSpying];
}

#pragma mark -
#pragma mark - Search functionality
- (void)searchAction
{
    [self presentSearchBar];
}

- (void)cancelSearchAction
{
    [self dismissSearchBar];
    [_spy setFilterText:nil];
}

- (void)showSearchButton
{
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Search"] style:UIBarButtonItemStylePlain target:self action:@selector(searchAction)];
    self.navigationItem.rightBarButtonItem = item;
}

- (void)presentSearchBar
{
    _searchBar.text = @"";
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(cancelSearchAction)];
    self.navigationItem.rightBarButtonItem = item;
    self.navigationItem.titleView = _searchBar;
    self.navigationItem.hidesBackButton = YES;
    [_searchBar becomeFirstResponder];
}

- (void)dismissSearchBar
{
    self.navigationItem.rightBarButtonItem = nil;
    self.navigationItem.titleView = nil;
    self.navigationItem.hidesBackButton = NO;
    [_searchBar resignFirstResponder];
    [self showSearchButton];
}

- (void)initSearchBar
{
    UISearchBar *searchBar = [UISearchBar new];
    searchBar.delegate = self;
    searchBar.placeholder = @"Search";
    _searchBar = searchBar;
    
    for (UIView *subview in [[searchBar.subviews lastObject] subviews]) {
        if ([subview isKindOfClass:NSClassFromString(@"UISearchBarBackground")]) {
            [subview removeFromSuperview];
            break;
        }
    }
    
    self.definesPresentationContext = YES;
    
    [self showSearchButton];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    [_spy setFilterText:searchText];
}

#pragma mark -
#pragma mark - TwitterSpyDelegate
- (void)TwitterSpy:(TwitterSpy *)twitterSpy didShowTweet:(Tweet *)tweet
{
    NSLog(@"Added tweet: %@", [tweet description]);
}

- (void)TwitterSpy:(TwitterSpy *)twitterSpy didRemoveTweet:(Tweet *)tweet
{
    NSLog(@"Removed tweet: %@", [tweet description]);
}

@end
