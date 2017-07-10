//
//  JXWebFileDownloadOperation.h
//  JXWebFile
//
//  Created by 朱佳翔 on 2017/7/10.
//  Copyright © 2017年 zjx. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JXWebFileDownloadOperation : NSOperation

/**
 * The request used by the operation's task.
 */
@property(strong, nonatomic, readonly, nullable) NSURLRequest *request;

/**
 * The operation's task
 */
@property(strong, nonatomic, readonly, nullable) NSURLSessionDownloadTask *downloadTask;

@property (assign, nonatomic) NSInteger bytesWritten;

@property (assign, nonatomic) NSInteger totalBytes;
/**
 *  Initializes a `SJWebFileDownloaderOperation` object
 *
 *  @see SJWebFileDownloaderOperation
 *
 *  @param request        the URL request
 *  @param session        the URL session in which this operation will run
 *
 *  @return the initialized instance
 */

- (nonnull instancetype)initWithRequest:(nullable NSURLRequest *)request
                                session:(nullable NSURLSession *)session;

- (nonnull instancetype)initWithResumeData:(nullable NSData *)resumeData session:(nullable NSURLSession *)session;

@end
