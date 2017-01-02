//
//  JLNetworkCacheHelper.m
//  JLNetworkHelper
//
//  Created by JeLon_Cai on 16/12/25.
//  Copyright © 2016年 JeLon_Cai. All rights reserved.
//

#import "JLNetworkCacheHelper.h"
#import "YYCache.h"

@implementation JLNetworkCacheHelper

static NSString *const NetworkResponseCache = @"NetworkResponseCache";
static YYCache *_dataCache;

+ (void)initialize
{
    _dataCache = [YYCache cacheWithName:NetworkResponseCache];
}

+ (void)saveHttpCache:(id)httpCache forKey:(NSString *)key
{   /// 异步缓存, 不会阻塞主线程
    [_dataCache setObject:httpCache forKey:key withBlock:nil];
}

+ (id)getHttpCacheForKey:(NSString *)key
{
    return [_dataCache objectForKey:key];
}

+ (NSInteger)getAllHttpCacheSize
{
    return [_dataCache.diskCache totalCost];
}

+ (void)removeAllHttpCache
{
    [_dataCache.diskCache removeAllObjects];
}
@end
