//
//  SAXImageView.m
//  AXKit
//
//  Created by James Savage on 3/4/12.
//  Copyright (c) 2012 axiixc.com. All rights reserved.
//

#import "SAXImageView.h"
#import "SAXImageViewCell.h"
#import "AXImageFetchRequestStack.h"

@implementation SAXImageView {
AXImageFetchRequestStack * imageRequestStack;
NSArray * imageDataSource;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if ([AXImageFetchRequest removeAllCachedImages])
        NSLog(@"Error clearing cache");
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
    SAXImageViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"basicCell"];
    
    if (!cell)
        cell = [[SAXImageViewCell alloc] initWithRequestStack:imageRequestStack reuseIdentifier:@"basicCell"];
    
    cell.imageURL = [imageDataSource objectAtIndex:indexPath.row];
    return cell;
}

@end