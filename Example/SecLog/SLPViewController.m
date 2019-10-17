//
//  SLPViewController.m
//  SecLog
//
//  Created by Serge Okon on 10/16/2019.
//  Copyright (c) 2019 Serge Okon. All rights reserved.
//

#import "SLPViewController.h"

@interface SLPViewController ()

@property (nonatomic, readonly) SecLog* logger;


@end

@implementation SLPViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)tapInfo:(id)sender {
    SecLog* logger = [SecLog sharedInstance];
    [logger info:[NSString stringWithFormat:@"This is an info message at %@", [NSDate date]]];
}

- (IBAction)tapWarning:(id)sender {
}

- (IBAction)tapError:(id)sender {
}


@end
