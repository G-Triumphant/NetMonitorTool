//
//  FUNetMonitorTool.m
//  FUPTAG
//
//  Created by G-Triumphant on 2022/6/9.
//

#import "FUNetMonitorTool.h"

#import "Reachability.h"
#import "FUPinger.h"

static FUNetMonitorTool *_shareManager = nil;
static dispatch_once_t onceToken;

NSString * const FUReachabilityChangedNotification = @"FUNetReachabilityChangedNotification";

@interface FUNetMonitorTool ()

@property (nonatomic, copy) NSString *host;

@property (nonatomic, strong) Reachability *reachability;

@property (nonatomic, strong) FUPinger *pinger;

@end

@implementation FUNetMonitorTool

- (instancetype)init {
    if (self = [super init]) {
        _reachabilityStatus = -1;
        _networkType = -1;
        _failureTimes = 2;
        _interval = 1.0;
    }
    return self;
}

+ (instancetype)shareInstance {
    dispatch_once(&onceToken, ^{
        _shareManager = [[self alloc] init];
    });
    return _shareManager;
}

+ (instancetype)defultObsever {
    return [FUNetMonitorTool observerWithHost:@"www.baidu.com"];
}

+ (instancetype)observerWithHost:(NSString *)host {
    KFUNetMonitorTool.host = host;
    return KFUNetMonitorTool;
}

+ (void)destroy {
    onceToken = 0;
    _shareManager = nil;
}

- (void)dealloc {
    [self stopNetMonitor];
}

#pragma mark - function
- (void)startNetMonitor {
//    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
//    __weak typeof(self) weakSelf = self;
//    [[AFNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
//        [weakSelf networkStatusDidChanged];
//    }];
    [self.reachability startNotifier];
    [self.pinger startPingNotifier];
}

- (void)stopNetMonitor {
//    [[AFNetworkReachabilityManager sharedManager] stopMonitoring];
    [self.reachability stopNotifier];
    [self.pinger stopPingNotifier];
}

+ (AFNetworkReachabilityManager *)reachabilityManager {
    AFNetworkReachabilityManager *netWorkManager = [AFNetworkReachabilityManager sharedManager];
    [netWorkManager startMonitoring];
    return netWorkManager;
}

+ (void)netWorkStateMonitNetWorkStateBlock:(void(^)(AFNetworkReachabilityStatus netStatus))block {
    [[self reachabilityManager] setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        if (status == AFNetworkReachabilityStatusUnknown || status == AFNetworkReachabilityStatusNotReachable) {
            // ???????????????
        }
        block(status);
    }];
}

#pragma mark - delegate

- (void)networkStatusDidChanged {
    // ???????????????????????????????????????, BOOL???
//    BOOL reachable = [[AFNetworkReachabilityManager sharedManager] isReachable];
    
    BOOL reachable = NO;
    if ([self.reachability currentReachabilityStatus] != NotReachable) {
        reachable = YES;
    }
    BOOL pingReachable = self.pinger.reachable;
     
    // ??????????????????, ????????????:Reachability -> pinger
    if (reachable && pingReachable) {
        // ??????
        self.reachabilityStatus = FUNetworkReachabilityStatusReachable;
        self.networkType = [self netWorkDetailType];
    } else {
        // ??????
        self.reachabilityStatus = FUNetworkReachabilityStatusNotReachable;
        self.networkType = FUNetworkTypeNone;
    }
}

#pragma mark - Getter/Setter

- (Reachability *)reachability {
    if (!_reachability) {
        _reachability = [Reachability reachabilityWithHostName:self.host];
        __weak typeof(self) weakSelf = self;
        [_reachability setNetworkStatusDidChanged:^{
            [weakSelf networkStatusDidChanged];
        }];
    }
    return _reachability;
}

- (FUPinger *)pinger {
    if (_pinger == nil) {
        _pinger = [FUPinger simplePingerWithHostName:self.host];
        _pinger.supportIPv4 = self.supportIPv4;
        _pinger.supportIPv6 = self.supportIPv6;
        _pinger.interval = self.interval;
        _pinger.failureTimes = self.failureTimes;
        
        __weak typeof(self) weakSelf = self;
        [_pinger setNetworkStatusDidChanged:^{
            [weakSelf networkStatusDidChanged];
        }];
    }
    return _pinger;
}

//
- (void)setReachabilityStatus:(FUNetworkReachabilityStatus)reachabilityStatus {
    if (_reachabilityStatus != reachabilityStatus) {
        _reachabilityStatus = reachabilityStatus;
        NSLog(@"????????????-----%@", [self reachabilityStatusDict][@(reachabilityStatus)]);
        // ??????????????????
        NSDictionary *info = @{@"reachabilityStatus" : @(reachabilityStatus),
                               @"host"   : self.host
                               };
        [[NSNotificationCenter defaultCenter] postNotificationName:FUReachabilityChangedNotification object:nil userInfo:info];
    }
}

//
- (void)setNetworkType:(FUNetworkType)networkType {
    if (_networkType != networkType) {
        _networkType = networkType;
        NSLog(@"????????????-----%@",self.networkDict[@(networkType)]);
        if(self.delegate){
            // ????????????
            if ([self.delegate respondsToSelector:@selector(observer:host:reachabilityStatus:networkTypeDidChanged:)]) {
                [self.delegate observer:self host:self.host reachabilityStatus:self.reachabilityStatus networkTypeDidChanged:networkType];
            }
        }else {
            // ??????????????????
            NSDictionary *info = @{@"type" : @(networkType),
                                   @"host"   : self.host
                                   };
            [[NSNotificationCenter defaultCenter] postNotificationName:FUReachabilityChangedNotification object:nil userInfo:info];
        }
    }
}

#pragma mark - tools

- (FUNetworkType)netWorkDetailType {
    FUNetworkType netType = FUNetworkTypeNone;
    
    UIApplication *app = [UIApplication sharedApplication];
    id statusBar = nil;
    // ???????????????iOS 13
    if (@available(iOS 13.0, *)) {
        UIStatusBarManager *statusBarManager = [UIApplication sharedApplication].keyWindow.windowScene.statusBarManager;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
        if ([statusBarManager respondsToSelector:@selector(createLocalStatusBar)]) {
            UIView *localStatusBar = [statusBarManager performSelector:@selector(createLocalStatusBar)];
            if ([localStatusBar respondsToSelector:@selector(statusBar)]) {
                statusBar = [localStatusBar performSelector:@selector(statusBar)];
            }
        }
#pragma clang diagnostic pop
        if (statusBar) {
            id currentData = [[statusBar valueForKeyPath:@"_statusBar"] valueForKeyPath:@"currentData"];
            id _wifiEntry = [currentData valueForKeyPath:@"wifiEntry"];
            id _cellularEntry = [currentData valueForKeyPath:@"cellularEntry"];
            if (_wifiEntry && [[_wifiEntry valueForKeyPath:@"isEnabled"] boolValue]) {
                netType = [self getNetworkWifiType];
            } else if (_cellularEntry && [[_cellularEntry valueForKeyPath:@"isEnabled"] boolValue]) {
                NSNumber *type = [_cellularEntry valueForKeyPath:@"type"];
                if (type) {
                    switch (type.integerValue) {
                        case 0:
                            netType = FUNetworkTypeNone;
                            break;
                            
                        case 1:
                            netType = FUNetworkTypeE;
                            break;
                            
                        case 4:
                            netType = FUNetworkType3G;
                            break;
                            
                        case 5:
                            netType = FUNetworkType4G;
                            break;
                            
                        default:
                            netType = FUNetworkTypeWWAN;
                            break;
                    }
                }
            }
        }
    }else {
        statusBar = [app valueForKeyPath:@"statusBar"];
        if ([self isPhoneX_Service]) {
                // ?????????
                id statusBarView = [statusBar valueForKeyPath:@"statusBar"];
                UIView *foregroundView = [statusBarView valueForKeyPath:@"foregroundView"];
                NSArray *subviews = [[foregroundView subviews][2] subviews];
                if (subviews.count == 0) {
                    // iOS 12
                    id currentData = [statusBarView valueForKeyPath:@"currentData"];
                    id wifiEntry = [currentData valueForKey:@"wifiEntry"];
                    if ([[wifiEntry valueForKey:@"_enabled"] boolValue]) {
                        // wifi
                        netType = [self getNetworkWifiType];
                    }else {
                        // ???1:
                        id cellularEntry = [currentData valueForKey:@"cellularEntry"];
                        // ???2:
                        id secondaryCellularEntry = [currentData valueForKey:@"secondaryCellularEntry"];
                        
                        if (([[cellularEntry valueForKey:@"_enabled"] boolValue]|[[secondaryCellularEntry valueForKey:@"_enabled"] boolValue]) == NO) {
                            // ????????????
                            netType = FUNetworkTypeNone;
                        }else {
                            // ?????????1?????????2
                            BOOL isCardOne = [[cellularEntry valueForKey:@"_enabled"] boolValue];
                            int networkType = isCardOne ? [[cellularEntry valueForKey:@"type"] intValue] : [[secondaryCellularEntry valueForKey:@"type"] intValue];
                            switch (networkType) {
                                case 0:
                                    //?????????
                                    netType = FUNetworkTypeNone;
                                    break;
        
                                case 3:
                                    networkType = FUNetworkTypeE;
                                    break;
                                    
                                case 4:
                                    networkType = FUNetworkType3G;
                                    break;
                                    
                                case 5:
                                    networkType = FUNetworkType4G;
                                    break;
                                    
                                default:
                                    break;
                            }
                        }
                    }
                }else {
                    for (id subview in subviews) {
                        if ([subview isKindOfClass:NSClassFromString(@"_UIStatusBarWifiSignalView")]) {
                           // wifi
                            netType = [self getNetworkWifiType];
                        }else if ([subview isKindOfClass:NSClassFromString(@"_UIStatusBarStringView")]) {
                            netType = FUNetworkTypeWWAN;
                        }
                    }
                }
            }else {
                // ????????????
                UIView *foregroundView = [statusBar valueForKeyPath:@"foregroundView"];
                NSArray *subviews = [foregroundView subviews];
                
                for (id subview in subviews) {
                    if ([subview isKindOfClass:NSClassFromString(@"UIStatusBarDataNetworkItemView")]) {
                        int networkType = [[subview valueForKeyPath:@"dataNetworkType"] intValue];
                        switch (networkType) {
                            case 0:
                                networkType = FUNetworkTypeNone;
                                break;
                                
                            case 1:
                                networkType = FUNetworkType2G;
                                break;
                                
                            case 2:
                                networkType = FUNetworkType3G;
                                break;
                                
                            case 3:
                                networkType = FUNetworkType4G;
                                break;
                                
                            case 5:
                                // wifi
                                netType = [self getNetworkWifiType];
                                break;
                                
                            default:
                                break;
                        }
                    }
                }
            }
    }
    return netType;
}

- (FUNetworkType)getNetworkWifiType {
    FUNetworkType netType = FUNetworkTypeNone;
    // ???????????????iOS 13
    if (@available(iOS 13.0, *)) {
        UIStatusBarManager *statusBarManager = [UIApplication sharedApplication].keyWindow.windowScene.statusBarManager;
        id statusBar = nil;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
        if ([statusBarManager respondsToSelector:@selector(createLocalStatusBar)]) {
            UIView *localStatusBar = [statusBarManager performSelector:@selector(createLocalStatusBar)];
            if ([localStatusBar respondsToSelector:@selector(statusBar)]) {
                statusBar = [localStatusBar performSelector:@selector(statusBar)];
            }
        }
#pragma clang diagnostic pop
        if (statusBar) {
            id currentData = [[statusBar valueForKeyPath:@"_statusBar"] valueForKeyPath:@"currentData"];
            id wifiEntry = [currentData valueForKeyPath:@"wifiEntry"];
            if ([wifiEntry isKindOfClass:NSClassFromString(@"_UIStatusBarDataIntegerEntry")]) {
            //                    ?????????_UIStatusBarDataNetworkEntry???_UIStatusBarDataIntegerEntry???_UIStatusBarDataEntry
                NSInteger signalStrength = [[wifiEntry valueForKey:@"displayValue"] intValue];
                netType = [self configType:signalStrength];
            }
        }
    }else {
        UIApplication *app = [UIApplication sharedApplication];
        id statusBar = [app valueForKey:@"statusBar"];
        if ([self isPhoneX_Service]) {
            // ?????????
            id statusBarView = [statusBar valueForKeyPath:@"statusBar"];
            UIView *foregroundView = [statusBarView valueForKeyPath:@"foregroundView"];
            NSArray *subviews = [[foregroundView subviews][2] subviews];
            if (subviews.count == 0) {
                // iOS 12
                id currentData = [statusBarView valueForKeyPath:@"currentData"];
                id wifiEntry = [currentData valueForKey:@"wifiEntry"];
                NSInteger signalStrength = [[wifiEntry valueForKey:@"displayValue"] intValue];
                netType = [self configType:signalStrength];
                // dBm
                // int rawValue = [[wifiEntry valueForKey:@"rawValue"] intValue];
            }else {
                for (id subview in subviews) {
                    if ([subview isKindOfClass:NSClassFromString(@"_UIStatusBarWifiSignalView")]) {
                        NSInteger signalStrength = [[subview valueForKey:@"_numberOfActiveBars"] intValue];
                        netType = [self configType:signalStrength];
                    }
                }
            }
        }else {
            // ????????????
            UIView *foregroundView = [statusBar valueForKey:@"foregroundView"];
            NSArray *subviews = [foregroundView subviews];
            NSString *dataNetworkItemView = nil;
            for (id subview in subviews) {
                if([subview isKindOfClass:[NSClassFromString(@"UIStatusBarDataNetworkItemView") class]]) {
                    dataNetworkItemView = subview;
                    break;
               
                }
            }
            NSInteger signalStrength = [[dataNetworkItemView valueForKey:@"_wifiStrengthBars"] intValue];
            netType = [self configType:signalStrength];
            return signalStrength;
        }
    }
    return netType;
}

- (FUNetworkType)configType:(NSInteger)signalStrength {
    switch (signalStrength) {
        case 1:
            return FUNetworkTypeWifiLow;
            
        case 2:
            return FUNetworkTypeWifiMiddle;
            
        case 3:
            return FUNetworkTypeWifiHigh;
            
        default:
            break;
    }
    return FUNetworkTypeUnknown;
}

- (NSDictionary *)reachabilityStatusDict {
    return @{
             @(FUNetworkReachabilityStatusUnknown)   : @"????????????",
             @(FUNetworkReachabilityStatusNotReachable) : @"?????????",
             @(FUNetworkReachabilityStatusReachable)     : @"?????????",
            };
}

- (NSDictionary *)networkDict {
    return @{
             @(FUNetworkTypeNone)   : @"?????????/???SIM???/?????????",
             @(FUNetworkTypeUnknown) : @"????????????",
             @(FUNetworkTypeE)     : @"E???",
             @(FUNetworkType2G)     : @"2G??????",
             @(FUNetworkType3G)     : @"3G??????",
             @(FUNetworkType4G)     : @"4G??????",
             @(FUNetworkTypeWWAN)   : @"????????????",
             @(FUNetworkTypeWifiLow)   : @"WIFI-???",
             @(FUNetworkTypeWifiMiddle)   : @"WIFI-??????",
             @(FUNetworkTypeWifiHigh)   : @"WIFI-???",
            };
}

- (BOOL)isPhoneX_Service {
    if (@available(iOS 11.0, *)) {
        UIEdgeInsets safeAreaInsets = [UIApplication sharedApplication].windows[0].safeAreaInsets;
        return safeAreaInsets.top == 44.0 || safeAreaInsets.bottom == 44.0 || safeAreaInsets.left == 44.0 || safeAreaInsets.right == 44.0;
    }else {
        return NO;
    }
}

@end
