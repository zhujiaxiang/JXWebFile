//
//  JXWebFileDownloader.h
//  JXWebFile
//
//  Created by 朱佳翔 on 2017/7/10.
//  Copyright © 2017年 zjx. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JXWebFileDownloadOperation.h"

typedef void (^JXWebFileDownloaderProgressBlock)(NSInteger receivedSize, NSInteger expectedSize, NSURL *_Nullable targetURL);

typedef void (^JXWebFileDownloaderCompletedBlock)(NSURL *_Nullable localFileURL, NSError *_Nullable error, BOOL finished);
@interface JXWebFileDownloader : NSObject

/**
 *  Singleton method, returns the shared instance
 *
 *  @return global shared instance of downloader class
 */
+ (nullable instancetype)sharedDownloader;

/**
 * Creates a SJWebFileDownloader async downloader instance with a given URL
 *
 *
 * @param fileURL        The URL to the file to download
 * @param progressBlock  A block called repeatedly while the file is downloading
 *
 * @param completedBlock A block called once the download is completed.
 *                       If the download succeeded, the localfileUrl will be returned,
 *                       error parameter is set with the error. The last parameter is always YES
 *
 * @return SJWebFileDownloaderOperation that can be used to maintain control */

- (nullable JXWebFileDownloadOperation *)downloadFileWithURL:(nonnull NSURL *)fileURL progress:(nullable JXWebFileDownloaderProgressBlock)progressBlock completed:(nullable JXWebFileDownloaderCompletedBlock)completedBlock;

@property(strong, nonatomic, nullable) NSMutableDictionary<NSURL *, JXWebFileDownloadOperation *> *URLOperations;
/**
 * Cancels a download with webFileURL
 *
 * @param fileURL The URL to the file to download.
 */
- (void)cancelDownloadWithURL:(nonnull NSURL *)fileURL;

- (void)cancelAllDownloads;

@end
