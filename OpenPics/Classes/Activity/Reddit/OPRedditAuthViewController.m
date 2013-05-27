//
//  OPRedditAuthViewController.m
//  OpenPics
//
//  Created by David Ohayon on 5/25/13.
//  Copyright (c) 2013 Say Goodnight Software. All rights reserved.
//

#import "OPRedditAuthViewController.h"
#import "AFRedditAPIClient.h"
#import "FUIButton.h"

@interface OPRedditAuthViewController ()

@end

@implementation OPRedditAuthViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [self.usernameField becomeFirstResponder];
    self.passwordField.secureTextEntry = YES;
    self.loginButton = [[FUIButton alloc] initWithFrame:self.buttonView.frame];
    [self.loginButton ]
    self.loginButton.buttonColor = [UIColor turquoiseColor];
    self.loginButton.shadowColor = [UIColor greenSeaColor];
    self.loginButton.shadowHeight = 3.0f;
    self.loginButton.cornerRadius = 6.0f;
    self.loginButton.titleLabel.font = [UIFont boldFlatFontOfSize:16];
    [self.loginButton setTitleColor:[UIColor cloudsColor] forState:UIControlStateNormal];
    [self.loginButton setTitleColor:[UIColor cloudsColor] forState:UIControlStateHighlighted];
    self.loginButton.titleLabel.text = @"Login";
    [self.buttonView addSubview:self.loginButton];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)loginToReddit:(id)sender {
    AFRedditAPIClient *redditClient = [AFRedditAPIClient sharedClient];
    [redditClient loginToRedditWithUsername:self.usernameField.text password:self.passwordField.text completion:^(NSDictionary *response, BOOL success) {
        NSLog(@"Logged In!");
        [self.delegate didAuthenticateWithReddit];
        [self dismissViewControllerAnimated:YES completion:nil];
    }];
}

- (IBAction)cancelTapped:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}
@end
