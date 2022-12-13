//
//  FUNetMonitorTool.h
//  FUPTAG
//
//  Created by G-Triumphant on 2022/6/9.
//

#import <UIKit/UIKit.h>
#import "AFNetworkReachabilityManager.h"

FOUNDATION_EXPORT NSString * _Nullable const FUReachabilityChangedNotification;

#define KFUNetMonitorTool       [FUNetMonitorTool shareInstance]

// 网络状态(本机 + Ping)
typedef NS_ENUM(NSUInteger, FUNetworkReachabilityStatus) {
    FUNetworkReachabilityStatusUnknown = -1,
    FUNetworkReachabilityStatusNotReachable = 0,
    FUNetworkReachabilityStatusReachable = 1,
};

// 网络类型（信号强弱 + 类型）
typedef NS_ENUM(NSUInteger, FUNetworkType) {
    FUNetworkTypeUnknown,
    FUNetworkTypeNone,// 无SIM卡、无信号、无服务
    FUNetworkTypeE,
    FUNetworkType2G,
    FUNetworkType3G,
    FUNetworkType4G,
    FUNetworkTypeWWAN,
    FUNetworkTypeWifiLow,
    FUNetworkTypeWifiMiddle,
    FUNetworkTypeWifiHigh,
};

@protocol FUNetworkStatusDelegate <NSObject>

- (void)observer:(id _Nullable )obsever host:(NSString *_Nullable)host reachabilityStatus:(FUNetworkReachabilityStatus)reachabilityStatus networkTypeDidChanged:(FUNetworkType)type;

@end

NS_ASSUME_NONNULL_BEGIN

@interface FUNetMonitorTool : NSObject

@property (nonatomic, assign) FUNetworkReachabilityStatus reachabilityStatus;

/// 网络状态
@property (nonatomic, assign) FUNetworkType networkType;

@property (nonatomic, weak) id<FUNetworkStatusDelegate> delegate;

/// 有很小概率ping失败, 设定多少次ping失败认为是断网, 默认2次, 必须 >= 2
@property (nonatomic, assign) NSUInteger failureTimes;

/// ping的频率, 默认1s
@property (nonatomic, assign) NSTimeInterval interval;

/// 是否支持IPv4, 默认全部支持
@property (nonatomic, assign) BOOL supportIPv4;

/// 是否支持IPv6
@property (nonatomic,assign) BOOL supportIPv6;

/// 初始化单例
+ (instancetype)shareInstance;

/// 销毁单例
+ (void)destroy;

/// 默认ping地址www.baidu.com
+ (instancetype)defultObsever;

/// 自定义ping地址
/// @param host 地址
+ (instancetype)observerWithHost:(NSString *)host;

/// 开启监测
- (void)startNetMonitor;

/// 关闭监测
- (void)stopNetMonitor;

#pragma mark - 不使用Reachability + Ping组合方式, 直接AF监测回调
+ (void)netWorkStateMonitNetWorkStateBlock:(void(^)(AFNetworkReachabilityStatus netStatus))block;

@end

NS_ASSUME_NONNULL_END
