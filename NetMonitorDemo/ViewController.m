//
//  ViewController.m
//  NetMonitorDemo
//
//  Created by G-Triumphant on 2022/6/9.
//

#import "ViewController.h"

#import "FUNetMonitorTool.h"

@interface ViewController ()

@property (nonatomic, strong) UIButton *testButton;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [FUNetMonitorTool defultObsever];
    [KFUNetMonitorTool startNetMonitor];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkStatusChanged:) name:FUReachabilityChangedNotification object:nil];
    
    self.testButton = [[UIButton alloc] initWithFrame:CGRectMake(10, 100, 100, 50)];
    self.testButton.backgroundColor = [UIColor cyanColor];
    [self.testButton addTarget:self action:@selector(test) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.testButton];
}

- (void)test {
    NSLog(@"%lu-----%lu", (FUNetworkReachabilityStatus)KFUNetMonitorTool.reachabilityStatus,  (FUNetworkType)KFUNetMonitorTool.networkType);
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:FUReachabilityChangedNotification object:nil];
}

- (void)networkStatusChanged:(NSNotification *)notify {
    NSLog(@"notify-------%@", notify.userInfo);
}


@end
