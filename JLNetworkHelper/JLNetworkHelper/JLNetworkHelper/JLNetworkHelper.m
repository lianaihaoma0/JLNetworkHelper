//
//  JLNetworkHelper.m
//  JLNetworkHelper
//
//  Created by JeLon_Cai on 16/12/25.
//  Copyright © 2016年 JeLon_Cai. All rights reserved.
//

#import "JLNetworkHelper.h"
#import "AFNetworking.h"
#import "AFNetworkActivityIndicatorManager.h"

#ifdef DEBUG
#define CCLog(...) NSLog(@"%s 第%d行 \n %@\n\n",__func__,__LINE__,[NSString stringWithFormat:__VA_ARGS__])
#else
#define CCLog(...)
#endif

@implementation JLNetworkHelper

static NetworkStatus _status;
static BOOL _isNetwork;

#pragma mark - 开始监听网络
+ (void)startMonitoringNetwork
{
    AFNetworkReachabilityManager *manager = [AFNetworkReachabilityManager sharedManager];
    [manager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        switch (status) {
            case AFNetworkReachabilityStatusUnknown:
                _status ? _status(JLNetworkStatusUnknown) : nil;
                _isNetwork = NO;
                CCLog(@"未知网络");
                break;
                
            case AFNetworkReachabilityStatusNotReachable:
                _status ? _status(JLNetworkStatusNotReachable) : nil;
                _isNetwork = NO;
                CCLog(@"无网络");
                break;
                
            case AFNetworkReachabilityStatusReachableViaWWAN:
                _status ? _status(JLNetworkStatusReachableViaWWAN) : nil;
                _isNetwork = NO;
                CCLog(@"手机自带网络");
                break;
                
            case AFNetworkReachabilityStatusReachableViaWiFi:
                _status ? _status(JLNetworkStatusReachableViaWiFi) : nil;
                _isNetwork = NO;
                CCLog(@"WIFI");
                break;
            default:
                break;
        }
    }];
    [manager startMonitoring];
}

+ (void)checkNetworkStatusWithBlock:(NetworkStatus)status
{
    status ? _status = status : nil;
}

+ (BOOL)currentNetworkStatus
{
    return _isNetwork;
}

#pragma mark - GET请求无缓存
+ (NSURLSessionTask *)GET:(NSString *)URL
               parameters:(NSDictionary *)parameters
                  success:(HttpRequestSuccess)success
                  failure:(HttpRequestFailed)failure
{
    return [self GET:URL parameters:parameters responseCache:nil success:success failure:failure];
}

#pragma mark - POST请求无缓存
+ (NSURLSessionTask *)POST:(NSString *)URL parameters:(NSDictionary *)parameters success:(HttpRequestSuccess)success failure:(HttpRequestFailed)failure
{
    return [self POST:URL parameters:parameters responseCache:nil success:success failure:failure];
}

#pragma mark - GET请求自动缓存
+ (NSURLSessionTask *)GET:(NSString *)URL parameters:(NSDictionary *)parameters responseCache:(HttpRequestCache)responseCache success:(HttpRequestSuccess)success failure:(HttpRequestFailed)failure
{
    /// 读取缓存
    responseCache ? responseCache([JLNetworkCacheHelper getHttpCacheForKey:URL]) : nil;
    
    AFHTTPSessionManager *manager = [self createAFHTTPSessionManager];
    return [manager GET:URL parameters:parameters progress:^(NSProgress * _Nonnull downloadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        success ? success(responseObject) : nil;
        /// 对数据进行异步缓存
        responseCache ? [JLNetworkCacheHelper saveHttpCache:responseObject forKey:URL] : nil;
        CCLog(@"responseObject = %@", responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        failure ? failure(error) : nil;
        CCLog(@"error = %@",error);
    }];
}

#pragma mark - POST请求自动缓存
+ (NSURLSessionTask *)POST:(NSString *)URL parameters:(NSDictionary *)parameters responseCache:(HttpRequestCache)responseCache success:(HttpRequestSuccess)success failure:(HttpRequestFailed)failure
{
    /// 读取缓存
    responseCache ? responseCache([JLNetworkCacheHelper getHttpCacheForKey:URL]) : nil;
    
    AFHTTPSessionManager *manager = [self createAFHTTPSessionManager];
    return [manager POST:URL parameters:parameters progress:^(NSProgress * _Nonnull uploadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        success ? success(responseObject) : nil;
        /// 对数据进行异步缓存
        responseCache ? [JLNetworkCacheHelper saveHttpCache:responseObject forKey:URL] : nil;
        CCLog(@"responseObject = %@", responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        failure ? failure(error) : nil;
        CCLog(@"error = %@", error);
    }];
}

#pragma mark - 上传图片文件
+ (NSURLSessionTask *)uploadWithURL:(NSString *)URL
                         parameters:(NSDictionary *)parameters
                             images:(NSArray<UIImage *> *)images
                               name:(NSString *)name
                           fileName:(NSString *)fileName
                           mimeType:(NSString *)mimeType
                           progress:(HttpProgress)progress
                            success:(HttpRequestSuccess)success
                            failure:(HttpRequestFailed)failure
{
    AFHTTPSessionManager *manager = [self createAFHTTPSessionManager];
    return [manager POST:URL parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        
        //压缩-添加-上传图片
        [images enumerateObjectsUsingBlock:^(UIImage * _Nonnull image, NSUInteger idx, BOOL * _Nonnull stop) {
            
            NSData *imageData = UIImageJPEGRepresentation(image, 0.5);
            [formData appendPartWithFileData:imageData name:name fileName:[NSString stringWithFormat:@"%@%lu.%@",fileName,(unsigned long)idx,mimeType?mimeType:@"jpeg"] mimeType:[NSString stringWithFormat:@"image/%@",mimeType?mimeType:@"jpeg"]];
        }];
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        //上传进度
        progress ? progress(uploadProgress) : nil;
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        success ? success(responseObject) : nil;
        CCLog(@"responseObject = %@",responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        failure ? failure(error) : nil;
        CCLog(@"error = %@",error);
    }];
}
#pragma mark - 下载文件
+ (NSURLSessionTask *)downloadWithURL:(NSString *)URL fileDir:(NSString *)fileDir progress:(HttpProgress)progress success:(void (^)(NSString *))success failure:(HttpRequestFailed)failure
{
    AFHTTPSessionManager *manager = [self createAFHTTPSessionManager];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:URL]];
    NSURLSessionDownloadTask *downloadTask = [manager downloadTaskWithRequest:request progress:^(NSProgress * _Nonnull downloadProgress) {
        /// 下载进度
        progress ? progress(downloadProgress) : nil;
        CCLog(@"下载进度:%.2f%%",100.0*downloadProgress.completedUnitCount/downloadProgress.totalUnitCount);
    } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        //拼接缓存目录
        NSString *downloadDir = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:fileDir ? fileDir : @"Download"];
        //打开文件管理器
        NSFileManager *fileManager = [NSFileManager defaultManager];
        
        //创建Download目录
        [fileManager createDirectoryAtPath:downloadDir withIntermediateDirectories:YES attributes:nil error:nil];
        
        //拼接文件路径
        NSString *filePath = [downloadDir stringByAppendingPathComponent:response.suggestedFilename];
        
        CCLog(@"downloadDir = %@",downloadDir);
        
        //返回文件位置的URL路径
        return [NSURL fileURLWithPath:filePath];
        
    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        success ? success(filePath.absoluteString /** NSURL->NSString*/) : nil;
        failure && error ? failure(error) : nil;
    }];
    
    /// 开始下载
    [downloadTask resume];
    
    return  downloadTask;
}
#pragma mark - 设置AFHTTPSessionManager相关属性
+ (AFHTTPSessionManager *)createAFHTTPSessionManager
{
    /// 打开状态的等待菊花
    [AFNetworkActivityIndicatorManager sharedManager].enabled = YES;
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    /// 设置请求参数的类型:HTTP(AFJSONRequesSerializer, AFHTTPRequestSerializer)
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    /// 设置请求的超过时间
    manager.requestSerializer.timeoutInterval = 30.f;
    /// 设置服务器返回结果的类型:JSON(AFJSONRequesSerializer, AFHTTPRequestSerializer)
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithArray:@[@"application/json",
                                                                              @"text/html",
                                                                              @"text/json",
                                                                              @"text/plain",
                                                                              @"text/javascript",
                                                                              @"text/xml",
                                                                              @"image/*"]];
    return manager;
}
@end
