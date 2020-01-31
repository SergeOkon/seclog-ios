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

- (IBAction)sharedInstanceInit:(id)sender {
    [SecLog sharedInstance];
}

- (IBAction)cleanup:(id)sender {
    [SecLog cleanUpKeepingLogFiles:4 maxTotalLogSizeInMiB:1];
}

- (IBAction)tapInfo:(id)sender {
    SecLog* logger = [SecLog sharedInstance];
    [logger info:[NSString stringWithFormat:@"This is an info message at %@", [NSDate date]]];
}

- (IBAction)tapWarning:(id)sender {
    SecLog* logger = [SecLog sharedInstance];
    [logger warn:[NSString stringWithFormat:@"This is an info message at %@", [NSDate date]]];
}

- (IBAction)tapError:(id)sender {
    SecLog* logger = [SecLog sharedInstance];
    [logger error:[NSString stringWithFormat:@"This is an info message at %@", [NSDate date]]];
}



@end
