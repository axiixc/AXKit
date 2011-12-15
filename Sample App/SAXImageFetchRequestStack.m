//
//  SAXImageCache.m
//  AXKit
//
//  Created by James Savage on 12/10/11.
//  Copyright (c) 2011 axiixc.com. All rights reserved.
//

#import "SAXImageFetchRequestStack.h"
#import "AXImageFetchRequestStack.h"
#import "AXImageFetchRequest.h"

@implementation SAXImageFetchRequestStack {
    AXImageFetchRequestStack * imageRequestStack;
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
    
    imageRequestStack = [[AXImageFetchRequestStack alloc] initWithStackSize:6 maxConcurrentDownloads:6];
    
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
    cell.imageView.image = nil;
    
    [imageRequestStack
     fetchImageAtURL:[imageDataSource objectAtIndex:indexPath.row]
     stateChangedBlock:^(AXImageFetchRequestState state, NSString *imagePath, NSError *error) {
         UITableViewCell * cell = [tableView cellForRowAtIndexPath:indexPath];
         if (cell != nil) {
             if (state == AXImageFetchRequestStateCompleted)
                 cell.imageView.image = [UIImage imageWithContentsOfFile:imagePath];
             else
                 cell.imageView.image = nil;
             [cell setNeedsLayout];
         }
     }];
    
    return cell;
}

@end
