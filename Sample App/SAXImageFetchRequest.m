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
                        imageProgressView.progress = (float)((double)downloaded / (double)filesize);
                    } 
                    stateChangedBlock:^(AXImageFetchRequestState state, NSString *imagePath, NSError *error) {
                        switch (state) {
                            case AXImageFetchRequestStateDownloading:
                                imageView.image = nil;
                                imageStateLabel.text = @"Downloading";
                                imageProgressView.progress = 0;
                                break;
                            case AXImageFetchRequestStateCompleted:
                                imageView.image = [UIImage imageWithContentsOfFile:imagePath];
                                imageStateLabel.text = @"Complete";
                                imageProgressView.progress = 1;
                                break;
                            case AXImageFetchRequestStateError:
                                imageView.image = nil;
                                imageStateLabel.text = @"Error";
                                [[[UIAlertView alloc]
                                  initWithTitle:@"An Error Occured"
                                  message:[error description]
                                  delegate:nil
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil]
                                 show];
                                break;
                                
                            default:
                                break;
                        }
                    }];
}

@end
