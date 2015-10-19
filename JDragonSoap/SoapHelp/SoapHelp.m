//
//  SoapHelp.m
//  HttpRequest
//
//  Created by tiger on 15/4/12.
//  Copyright (c) 2015年 long. All rights reserved.
//

#import "SoapHelp.h"

@interface SoapHelp ()

@property (strong, nonatomic) ReturnValueBlock returnBlock;
@property (strong, nonatomic) ErrorCodeBlock errorBlock;
@property (strong, nonatomic) FailureBlock failureBlock;

@property(nonatomic,strong) Reachability  *reachability;

//获取网络的链接状态
-(void) netWorkStateWithNetConnectBlock: (NetWorkBlock) netConnectBlock WithURlStr: (NSString *) strURl;

// 传入交互的Block块
-(void) setBlockWithReturnBlock: (ReturnValueBlock) returnBlock
                 WithErrorBlock: (ErrorCodeBlock) errorBlock
               WithFailureBlock: (FailureBlock) failureBlock;

@end

@implementation SoapHelp

//-(id)init
//{
//    
//    if (self=[super init]) {
//        self.info = self;
//        [self checkReachability];
//    }
//    return self;
//}

+(SoapHelp*)shareInstance
{
    static SoapHelp *_sharedInstance = nil;
    
    static dispatch_once_t oncePredicate;
    
    dispatch_once(&oncePredicate, ^{
        
        _sharedInstance = [[SoapHelp alloc] init];
        [_sharedInstance checkReachability];
    });
    
    return _sharedInstance;
}

#pragma 获取网络可到达状态
-(void) netWorkStateWithNetConnectBlock: (NetWorkBlock) netConnectBlock WithURlStr: (NSString *) strURl;
{
    _netBlock = netConnectBlock;
}

#pragma 接收穿过来的block
-(void) setBlockWithReturnBlock: (ReturnValueBlock) returnBlock
                 WithErrorBlock: (ErrorCodeBlock) errorBlock
               WithFailureBlock: (FailureBlock) failureBlock
{
    _returnBlock = returnBlock;
    _errorBlock = errorBlock;
    _failureBlock = failureBlock;
}
+(void)soapPostRequestWith:(resultBlock)result{
    
    [SoapHelp NetRequestPOSTWithRequestURL: [SoapHelp shareInstance].urlHost WithParameter:[SoapHelp shareInstance].parameter WithReturnValeuBlock:^(id returnValue) {
        result(returnValue);
    } WithErrorCodeBlock:^(id errorCode) {
        
        [SoapHelp shareInstance].errorBlock(errorCode);
    } WithFailureBlock:^{
        
       [SoapHelp shareInstance].failureBlock();
    }];

    [[SoapHelp shareInstance] soapHelpRequestResultInfo];
    
}
-(void)soapHelpRequestResultInfo
{
    
    __weak    SoapHelp  *soap = self;
    
   [self setBlockWithReturnBlock:^(id returnValue) {
       
//       if ([soap.delegate respondsToSelector:@selector(soapHelpObjectResultInfo:)]) {
//           
//           [soap.delegate  soapHelpObjectResultInfo:returnValue];
//       }
//       NSLog(@"rereer%@",returnValue);
       soap.returnBlock(returnValue);
       
   } WithErrorBlock:^(id errorCode) {
       
       if ([soap.delegate respondsToSelector:@selector(soapHelpObjectErrorInfo:)]) {
           
           [soap.delegate  soapHelpObjectErrorInfo:errorCode];
       }
       
   } WithFailureBlock:^{
       
       if ([soap.delegate respondsToSelector:@selector(soapHelpObjectFailureInfo)]) {
           
           [soap.delegate  soapHelpObjectFailureInfo];
       }
       
   }];
    
}
+(void)soapGetRequestWith:(ReturnValueBlock)result
{
    [SoapHelp NetRequestGETWithRequestURL: [SoapHelp shareInstance].urlHost WithParameter:[SoapHelp shareInstance].parameter WithReturnValeuBlock:^(id returnValue) {
//        _returnBlock(returnValue);
        result(returnValue);
    } WithErrorCodeBlock:^(id errorCode) {
        
        [SoapHelp shareInstance].errorBlock(errorCode);
    } WithFailureBlock:^{
        
        [SoapHelp shareInstance].failureBlock();
//        LLog(@"网络异常");
    }];
    [SoapHelp shareInstance].returnBlock = result;
    [[SoapHelp shareInstance] soapHelpRequestResultInfo];
   
}

+(void)netWorkStateReachability:(NetWorkBlock)net
{
//    [SoapHelp netWorkReachabilityWithURLString:@"wap.baidu.com" withReturnNetBlock:^(int netConnetState) {
//                  [SoapHelp shareInstance].netBlock(netConnetState);
//            }];
   [SoapHelp shareInstance].netBlock = net;
   [[SoapHelp shareInstance] updateInterfaceWithReachability:[SoapHelp shareInstance].reachability];
}


#pragma mark Reachability Methods
#pragma mark
- (void)checkReachability
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
    self.reachability = [Reachability reachabilityForInternetConnection];
    [self.reachability startNotifier];
    [self updateInterfaceWithReachability:self.reachability];
    
 }

/*!
 * Called by Reachability whenever status changes.
 */
- (void) reachabilityChanged:(NSNotification *)note
{
    Reachability * curReach = [note object];
    NSParameterAssert([curReach isKindOfClass:[Reachability class]]);
    [self updateInterfaceWithReachability:curReach];
}

- (void)updateInterfaceWithReachability:(Reachability *)reachability
{
    NetworkStatus status = [reachability currentReachabilityStatus];
    
    int  net = 0;
    if(status == NotReachable)
    {
        //No internet
        NSLog(@"No Internet");
        net = 0;
    }
    else if (status == ReachableViaWiFi)
    {
        //WiFi
        NSLog(@"Reachable WIFI");
        net = 1;
    }
    else if (status == ReachableViaWWAN)
    {
        //3G
        NSLog(@"Reachable 3G");
        net=  [SoapHelp checkNetWorklocalType];
    }
    if (_netBlock) {
        [SoapHelp shareInstance].netBlock(net);
    }
}
#pragma mark-----------------------------------
#pragma 监测网络的可链接性
+(void) netWorkReachabilityWithURLString:(NSString *) strUrl withReturnNetBlock:(NetWorkBlock)netBlock;
{

    __block int  netState;
    
    NSURL *baseURL = [NSURL URLWithString:strUrl];
    
    AFHTTPRequestOperationManager *manager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:baseURL];
    
    NSOperationQueue *operationQueue = manager.operationQueue;
    
    [manager.reachabilityManager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        switch (status) {
            case AFNetworkReachabilityStatusReachableViaWWAN:
            case AFNetworkReachabilityStatusReachableViaWiFi:
                [operationQueue setSuspended:NO];
                
                netState = [SoapHelp checkNetWorklocalType];
                
                break;
            case AFNetworkReachabilityStatusNotReachable:
                netState = 0;
            default:
                [operationQueue setSuspended:YES];
                break;
        }
        netBlock(netState);
    }];
    
    [manager.reachabilityManager startMonitoring];
    
}
/**
 *  判断网络
 *
 *  @return 返回网络状态
 */
+(int)checkNetWorklocalType
{
    UIApplication *app = [UIApplication sharedApplication];
    NSArray *children = [[[app valueForKeyPath:@"statusBar"]valueForKeyPath:@"foregroundView"]subviews];
    int state = 0;
    int netType ;
    //获取到网络返回码
    for (id child in children) {
        if ([child isKindOfClass:NSClassFromString(@"UIStatusBarDataNetworkItemView")]) {
            //获取到状态栏
            netType = [[child valueForKeyPath:@"dataNetworkType"]intValue];
            
            switch (netType) {
                case 0:
//                    state = @"无网络";
                     state = 0;
                    //无网模式
                    break;
                case 1:
//                    state = @"2G";
                    state =2;

                    break;
                case 2:
//                    state = @"3G";
                     state = 3;
                    break;
                case 3:
//                    state = @"4G";
                    state = 4;
                    break;
                case 5:
                {
//                    state = @"WIFI";
                    state = 1;
                }
                    break;
                default:
                    break;
            }
        }
    }
    //根据状态选择
    return state;
}


/*
 在这做判断如果有dic里有errorCode
 调用errorBlock(dic)
 没有errorCode则调用block(dic
 */
#pragma --mark GET请求方式
+ (void) NetRequestGETWithRequestURL: (NSString *) requestURLString
                       WithParameter: (NSDictionary *) parameter
                WithReturnValeuBlock: (ReturnValueBlock) block
                  WithErrorCodeBlock: (ErrorCodeBlock) errorBlock
                    WithFailureBlock: (FailureBlock) failureBlock
{
    AFHTTPRequestOperationManager *manager = [[AFHTTPRequestOperationManager alloc] init];
    
    AFHTTPRequestOperation *op = [manager GET:requestURLString parameters:parameter success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingAllowFragments error:nil];
        //        LLog(@"%@", dic);
        
        block(dic);
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        errorBlock(error);
    }];
    
    op.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    [op start];
}
#pragma --mark POST请求方式
+ (void) NetRequestPOSTWithRequestURL: (NSString *) requestURLString
                        WithParameter: (NSDictionary *) parameter
                 WithReturnValeuBlock: (ReturnValueBlock) block
                   WithErrorCodeBlock: (ErrorCodeBlock) errorBlock
                     WithFailureBlock: (FailureBlock) failureBlock
{
    AFHTTPRequestOperationManager *manager = [[AFHTTPRequestOperationManager alloc] init];
    
    manager.requestSerializer.timeoutInterval = 120;
    
    AFHTTPRequestOperation *op = [manager POST:requestURLString parameters:parameter success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingAllowFragments error:nil];
        //        LLog(@"%@", dic);
        
        block(dic);
        /*
         在这做判断如果有dic里有errorCode
         调用errorBlock(dic)
         没有errorCode则调用block(dic
         */
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        errorBlock(error);
    }];
    op.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    
    
    [op start];
}

+(void)soapHelpUpdateLoadImagewithResult:(resultBlock)resultBlock withUploadProgress:(void (^)(float progress))progressBlock;
{

    AFHTTPRequestOperationManager *manager = [[AFHTTPRequestOperationManager  alloc]init];
    AFHTTPRequestOperation *op = [manager POST:[SoapHelp shareInstance].urlHost parameters:[SoapHelp shareInstance].parameter constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        NSData *imageData = UIImageJPEGRepresentation([SoapHelp shareInstance].upImage, 0.3);
        //上传图片，以文件流的格式
        //        NSData *data=[NSData dataWithContentsOfFile:userIconFilePath];
//        [formData appendPartWithFileData:imageData name:@"userpic" fileName:fileName
//        [formData appendPartWithFormData:imageData name:@"userpic"];
        
//        [formData appendPartWithFileURL:[NSURL fileURLWithPath:userIconFilePath] name:@"userpic" fileName:fileName mimeType:@"image/jpeg/file" error:nil];

        [formData appendPartWithFileData:imageData name:[SoapHelp shareInstance].upImgParameterName fileName:[SoapHelp shareInstance].fileName mimeType:@"image/jpeg/file"];
    } success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingAllowFragments error:nil];
        resultBlock(dic);
        //        NSLog(@"成功%@",dic);
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
//        NSLog(@"错误%@",error);
        [SoapHelp shareInstance].errorBlock(error);
        
    }];
    
    op.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    [op start];
    
    [op setUploadProgressBlock:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
        CGFloat progress = ((float)totalBytesWritten) / totalBytesExpectedToWrite;
        //        NSLog(@"进度%f",progress);
        progressBlock(progress);
    }];
    [[SoapHelp shareInstance] soapHelpRequestResultInfo];

}

@end
