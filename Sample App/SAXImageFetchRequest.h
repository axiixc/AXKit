//
//  SAXImageFetchRequest.h
//  AXKit
//
//  Created by James Savage on 12/10/11.
//  Copyright (c) 2011 axiixc.com. All rights reserved.
//

@interface SAXImageFetchRequest : UIViewController <UITextFieldDelegate>

@property (nonatomic, strong) IBOutlet UIBarButtonItem * goItem;
@property (nonatomic, strong) IBOutlet UITextField * urlField;
@property (nonatomic, strong) IBOutlet UIImageView * imageView;
@property (nonatomic, strong) IBOutlet UIProgressView * imageProgressView;
@property (nonatomic, strong) IBOutlet UILabel * imageStateLabel;

- (IBAction)loadImage;
- (IBAction)typedIntoURLField:(UITextField *)sender;

@end
