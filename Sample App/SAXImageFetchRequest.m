//
//  SAXImageFetchRequest.m
//  AXKit
//
//  Created by James Savage on 12/10/11.
//  Copyright (c) 2011 axiixc.com. All rights reserved.
//

#import "SAXImageFetchRequest.h"
#import "AXImageFetchRequest.h"

@implementation SAXImageFetchRequest {
    AXImageFetchRequest * pendingFetch;
}

@synthesize goItem, urlField, imageView, imageProgressView, imageStateLabel;

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [AXImageFetchRequest removeAllCachedImages];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    if (urlField.isFirstResponder) {
        [urlField resignFirstResponder];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self loadImage];
    return YES;
}

- (void)typedIntoURLField:(UITextField *)sender
{
    goItem.enabled = (sender.text.length != 0);
}

- (IBAction)loadImage
{
    if (urlField.isFirstResponder) {
        [urlField resignFirstResponder];
    }
    
    if (urlField.text.length == 0) {
        return;
    }
    
    if (pendingFetch != nil) {
        [pendingFetch cancel], pendingFetch = nil;
    }
    
    NSURL * imageURL = [NSURL URLWithString:urlField.text];
    pendingFetch = [AXImageFetchRequest
                    fetchImageAtURL:imageURL
                    progressBlock:^(long long downloaded, long long filesize) {
                        NSLog(@"%lld %lld", downloaded, filesize);
                        imageProgressView.progress = (float)((double)downloaded / (double)filesize);
                        imageStateLabel.text = @"Downloading";
                    } 
                    completionBlock:^(NSString *imagePath, NSError *error) {
                        if (error || imagePath == nil) {
                            [[[UIAlertView alloc]
                              initWithTitle:@"An Error Occured"
                              message:[error description]
                              delegate:nil
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil]
                             show];
                            imageView.image = nil;
                            imageStateLabel.text = @"Error";
                        }
                        else {
                            imageView.image = [UIImage imageWithContentsOfFile:imagePath];
                            imageStateLabel.text = @"Downloaded";
                        }
                    }];
}

@end
