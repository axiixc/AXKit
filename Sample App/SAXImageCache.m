//
//  SAXImageCache.m
//  AXKit
//
//  Created by James Savage on 12/10/11.
//  Copyright (c) 2011 axiixc.com. All rights reserved.
//

#import "SAXImageCache.h"
#import "AXImageCache.h"
#import "AXImageFetchRequest.h"

@implementation SAXImageCache {
    AXImageCache * imageCache;
    NSArray * imageDataSource;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [AXImageFetchRequest removeAllCachedImages];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    imageCache = [[AXImageCache alloc] initWithDownloadStackSize:10];
    
    NSString * cacheData = [[NSBundle mainBundle] pathForResource:@"SAXImageCacheData" ofType:@"plist"];
    NSMutableArray * tempImageDataSource = [NSMutableArray new];
    
    [[NSArray arrayWithContentsOfFile:cacheData]
     enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
         NSURL * url = [NSURL URLWithString:obj];
         
         if (url != nil) {
             [tempImageDataSource addObject:url];
         }
    }];
    
    imageDataSource = [tempImageDataSource copy];
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return imageDataSource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"basicCell"];
    cell.textLabel.text = [[imageDataSource objectAtIndex:indexPath.row] absoluteString];
    
    [imageCache
     fetchImageAtURL:[imageDataSource objectAtIndex:indexPath.row]
     startingBlock:^(NSString *imagePath) {
         cell.imageView.image = nil;
     }
     progressBlock:NULL
     completionBlock:^(NSString *imagePath, NSError *error) {
         
     }];
    return cell;
}

@end
