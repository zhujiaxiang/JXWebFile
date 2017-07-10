//
//  JXFileCache.m
//  JXWebFile
//
//  Created by 朱佳翔 on 2017/7/10.
//  Copyright © 2017年 zjx. All rights reserved.
//

#import "JXFileCache.h"
#import <CommonCrypto/CommonDigest.h>

@interface JXFileCache ()

@property(strong, nonatomic, nullable) dispatch_queue_t ioQueue;
@property(strong, nonatomic, nullable) NSFileManager *fileManager;
@property(strong, nonatomic, nonnull) NSString *diskCachePath;
@property(strong, nonatomic, nonnull) NSString *resumeDataPath;

@end

@implementation JXFileCache

static id instance = nil;

+ (instancetype)sharedFileCache
{
    static dispatch_once_t once;
    
    dispatch_once(&once, ^{
        instance = [[[self class] alloc] init];
    });
    return instance;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [super allocWithZone:zone];
    });
    return instance;
}

- (instancetype)init
{
    if ((self = [super init])) {
        _ioQueue = dispatch_queue_create("net.zjx.JXWebFile", DISPATCH_QUEUE_SERIAL);
        dispatch_sync(_ioQueue, ^{
            _fileManager = [NSFileManager new];
        });
    }
    
    return self;
}

- (nullable NSString *)getDiskCachePath
{
    if (_diskCachePath) {
        return _diskCachePath;
    }
    NSArray<NSString *> *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    _diskCachePath = [paths[0] stringByAppendingPathComponent:@"net.zjx.JXWebFile"];
    return _diskCachePath;
}

- (nullable NSString *)getResumeDataPath
{
    if (_resumeDataPath) {
        return _resumeDataPath;
    }
    NSArray<NSString *> *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    _resumeDataPath = [paths[0] stringByAppendingPathComponent:@"net.zjx.JXWebFile.Tmp"];
    return _resumeDataPath;
}

- (nullable NSString *)getCacheKeyForURL:(nonnull NSURL *)URL
{
    const char *str = URL.absoluteString.UTF8String;
    if (str == NULL) {
        str = "";
    }
    unsigned char r[16];
    CC_MD5(str, (CC_LONG)strlen(str), r);
    NSString *filename = [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%@",
                          r[0], r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8], r[9], r[10],
                          r[11], r[12], r[13], r[14], r[15], [URL.absoluteString.pathExtension isEqualToString:@""] ? @"" : [NSString stringWithFormat:@".%@", URL.absoluteString.pathExtension]];
    
    return filename;
}

- (void)storeFileDataToDiskForURL:(nonnull NSURL *)URL fileData:(nonnull NSData *)fileData
{
    NSURL *localFileURL = nil;
    //构建缓存目录
    NSString *dirPath = nil;
    dirPath = [self getDiskCachePath];
    
    //构建缓存文件的路径
    NSString *filePath = [NSString stringWithFormat:@"%@/%@", dirPath, [self getCacheKeyForURL:URL]];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:dirPath]) {
        [fm createDirectoryAtPath:dirPath withIntermediateDirectories:YES attributes:nil error:NULL];
    }
    BOOL createFileSuccess = [fm createFileAtPath:filePath
                                         contents:fileData
                                       attributes:nil];
    if (createFileSuccess) {
        localFileURL = [NSURL fileURLWithPath:filePath];
    }
}

- (void)storeResumeDataToDiskForURL:(nonnull NSURL *)URL resumeData:(nonnull NSData *)resumeData
{
    NSURL *localFileURL = nil;
    //构建缓存目录
    NSString *dirPath = nil;
    dirPath = [self getResumeDataPath];
    
    //构建缓存文件的路径
    NSString *filePath = [NSString stringWithFormat:@"%@/%@", dirPath, [self getCacheKeyForURL:URL]];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:dirPath]) {
        [fm createDirectoryAtPath:dirPath withIntermediateDirectories:YES attributes:nil error:NULL];
    }
    BOOL createFileSuccess = [fm createFileAtPath:filePath
                                         contents:resumeData
                                       attributes:nil];
    if (createFileSuccess) {
        localFileURL = [NSURL fileURLWithPath:filePath];
    }
}

- (nullable NSString *)dataFromResumeDataForURL:(nonnull NSURL *)URL
{
    NSString *dirPath = nil;
    dirPath = [self getResumeDataPath];
    NSString *filePath = [NSString stringWithFormat:@"%@/%@", dirPath, [self getCacheKeyForURL:URL]];
    BOOL exists = [self.fileManager fileExistsAtPath:filePath];
    if (exists) {
        return filePath;
    }
    return nil;
}

- (nullable NSString *)fileFromDiskCacheForURL:(nonnull NSURL *)URL
{
    NSString *dirPath = nil;
    dirPath = [self getDiskCachePath];
    NSString *filePath = [NSString stringWithFormat:@"%@/%@", dirPath, [self getCacheKeyForURL:URL]];
    BOOL exists = [self.fileManager fileExistsAtPath:filePath];
    if (exists) {
        return filePath;
    }
    return nil;
}

- (void)removeFileFromDiskCacheForURL:(nonnull NSURL *)URL
{
    NSFileManager *fm = [NSFileManager defaultManager];
    
    NSString *localFilePath = [self fileFromDiskCacheForURL:URL];
    if ([fm fileExistsAtPath:localFilePath]) {
        BOOL success = [fm removeItemAtPath:localFilePath error:nil];
        NSLog(@"removeFile = %i", success);
    }
}

- (void)removeResumeDataFromResumeDataPathForURL:(nonnull NSURL *)URL
{
    NSFileManager *fm = [NSFileManager defaultManager];
    
    NSString *localFilePath = [self dataFromResumeDataForURL:URL];
    if ([fm fileExistsAtPath:localFilePath]) {
        BOOL success = [fm removeItemAtPath:localFilePath error:nil];
        NSLog(@"removeResumeData = %i", success);
    }
}

- (NSUInteger)getDiskCacheFileCount
{
    __block NSUInteger count = 0;
    dispatch_sync(self.ioQueue, ^{
        NSDirectoryEnumerator *fileEnumerator = [self.fileManager enumeratorAtPath:[self getDiskCachePath]];
        count = fileEnumerator.allObjects.count;
    });
    return count;
}

- (NSUInteger)getUsedDiskCacheSize
{
    __block NSUInteger size = 0;
    dispatch_sync(self.ioQueue, ^{
        NSDirectoryEnumerator *fileEnumerator = [self.fileManager enumeratorAtPath:[self getDiskCachePath]];
        for (NSString *fileName in fileEnumerator) {
            NSString *filePath = [self.diskCachePath stringByAppendingPathComponent:fileName];
            NSDictionary<NSString *, id> *attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
            size += [attrs fileSize];
        }
    });
    return size;
}

- (void)clearAllDiskCache
{
    if ([self.fileManager fileExistsAtPath:[self getDiskCachePath]]) {
        BOOL success = [self.fileManager removeItemAtPath:self.diskCachePath error:nil];
        
        NSLog(@"clear cache = %i", success);
    }
}
@end

