//
//  JXFileCache.h
//  JXWebFile
//
//  Created by 朱佳翔 on 2017/7/10.
//  Copyright © 2017年 zjx. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JXFileCache : NSObject

/**
 *  Singleton method, returns the shared instance
 *
 *  @return global shared instance of fileCache class
 */
+ (nullable instancetype)sharedFileCache;

/**
 *  Get default disk cache path
 *
 *  @return dafault disk cache path
 */
- (nullable NSString *)getDiskCachePath;

- (nullable NSString *)getResumeDataPath;
/**
 *  Get file cache key with URL by md5
 *
 *  @param URL fileWebURL
 *  @return dafault Disk Cache Path
 */
- (nullable NSString *)getCacheKeyForURL:(nonnull NSURL *)URL;

/**
 *  store fileData to disk for URL
 *
 *  @param URL fileWebURL
 *  @param fileData downloadedFileData
 */
- (void)storeFileDataToDiskForURL:(nonnull NSURL *)URL fileData:(nonnull NSData *)fileData;

- (void)storeResumeDataToDiskForURL:(nonnull NSURL *)URL resumeData:(nonnull NSData *)resumeData;
/**
 *  get file disk cache path string by URL
 *
 *  @param URL fileWebURL
 *  @return dafault Disk Cache Path string
 */
- (nullable NSString *)fileFromDiskCacheForURL:(nonnull NSURL *)URL;

- (nullable NSString *)dataFromResumeDataForURL:(nonnull NSURL *)URL;
/**
 *  remove file from disk cache with URL
 *
 *  @param URL fileWebURL
 */
- (void)removeFileFromDiskCacheForURL:(nonnull NSURL *)URL;

- (void)removeResumeDataFromResumeDataPathForURL:(nonnull NSURL *)URL;

- (NSUInteger)getDiskCacheFileCount;

- (NSUInteger)getUsedDiskCacheSize;

- (void)clearAllDiskCache;


@end
