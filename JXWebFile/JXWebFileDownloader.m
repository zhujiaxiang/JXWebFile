//
//  JXWebFileDownloader.m
//  JXWebFile
//
//  Created by 朱佳翔 on 2017/7/10.
//  Copyright © 2017年 zjx. All rights reserved.
//

#import "JXWebFileDownloader.h"
#import "JXFileCache.h"

static NSString *const kProgressCallbackKey = @"progress";
static NSString *const kCompletedCallbackKey = @"completed";

typedef NSMutableDictionary<NSString *, id> JXCallbacksDictionary;

@interface JXWebFileDownloader () <NSURLSessionTaskDelegate, NSURLSessionDataDelegate>

@property(strong, nonatomic, nonnull) NSOperationQueue *downloadQueue;

@property(strong, nonatomic, nullable) NSMutableDictionary<NSURL *, JXWebFileDownloaderProgressBlock> *progressBlocks;
@property(strong, nonatomic, nullable) NSMutableDictionary<NSURL *, JXWebFileDownloaderCompletedBlock> *completedBlocks;
@property(strong, nonatomic) NSURLSession *session;
@property(strong, nonatomic, nullable) dispatch_queue_t barrierQueue;
@property(assign, nonatomic) NSTimeInterval downloadTimeout;

@end

@implementation JXWebFileDownloader

static id instance = nil;

+ (instancetype)sharedDownloader
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

#pragma mark - backgroundURLSession
- (NSURLSession *)backgroundURLSession
{
    static NSURLSession *session = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *identifier = @"net.zjx.JXWebFile.BackgroundSession";
        NSURLSessionConfiguration *sessionConfig = nil;
        
        sessionConfig = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:identifier];
        sessionConfig.timeoutIntervalForRequest = _downloadTimeout;
        session = [NSURLSession sessionWithConfiguration:sessionConfig
                                                delegate:self
                                           delegateQueue:[NSOperationQueue mainQueue]];
    });
    
    return session;
}
- (nonnull instancetype)init
{
    return [self initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
}

- (nonnull instancetype)initWithSessionConfiguration:(nullable NSURLSessionConfiguration *)sessionConfiguration
{
    if ((self = [super init])) {
        _downloadQueue = [NSOperationQueue new];
        _downloadQueue.maxConcurrentOperationCount = 6;
        _downloadQueue.name = @"net.zjx.JXWebFile";
        _URLOperations = [NSMutableDictionary new];
        _progressBlocks = [NSMutableDictionary new];
        _completedBlocks = [NSMutableDictionary new];
        _barrierQueue = dispatch_queue_create("net.zjx.JXWebFile", DISPATCH_QUEUE_CONCURRENT);
        _downloadTimeout = 15.0;
        
        if (!self.session) {
            self.session = [self backgroundURLSession];
        }
    }
    return self;
}

- (nullable JXWebFileDownloadOperation *)downloadFileWithURL:(nonnull NSURL *)fileURL progress:(nullable JXWebFileDownloaderProgressBlock)progressBlock completed:(nullable JXWebFileDownloaderCompletedBlock)completedBlock
{
    
    
    if (self.URLOperations[fileURL]) {
        return self.URLOperations[fileURL];
    } else if ([[JXFileCache sharedFileCache] fileFromDiskCacheForURL:fileURL]) {
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"already downloaded!" forKey:NSLocalizedDescriptionKey];
        NSError *error = [NSError errorWithDomain:@"net.zjx.JXWebFile" code:-1 userInfo:userInfo];
        
        completedBlock([[NSURL alloc] initWithString:[[JXFileCache sharedFileCache] fileFromDiskCacheForURL:fileURL]], error, YES);
        return nil;
    }else if ([[JXFileCache sharedFileCache]dataFromResumeDataForURL:fileURL]){
        NSData * resumeData = [NSData dataWithContentsOfFile:[[JXFileCache sharedFileCache]dataFromResumeDataForURL:fileURL]];
        JXWebFileDownloadOperation *operation = [[JXWebFileDownloadOperation alloc] initWithResumeData:resumeData session:self.session];
        
        [self.downloadQueue addOperation:operation];
        self.URLOperations[fileURL] = operation;
        self.progressBlocks[fileURL] = progressBlock;
        self.completedBlocks[fileURL] = completedBlock;
        return operation;
    }
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:fileURL];
    
    JXWebFileDownloadOperation *operation = [[JXWebFileDownloadOperation alloc] initWithRequest:request session:self.session];
    
    [self.downloadQueue addOperation:operation];
    
    self.URLOperations[fileURL] = operation;
    self.progressBlocks[fileURL] = progressBlock;
    self.completedBlocks[fileURL] = completedBlock;
    
    return operation;
}

- (void)cancelDownloadWithURL:(nonnull NSURL *)fileURL
{
    dispatch_barrier_async(self.barrierQueue, ^{
        JXWebFileDownloadOperation *operation = self.URLOperations[fileURL];
        [operation cancel];
    });
}

- (void)cancelAllDownloads
{
    [self.downloadQueue cancelAllOperations];
    self.URLOperations = nil;
    self.completedBlocks = nil;
    self.progressBlocks = nil;
}

#pragma mark - Private APIs

- (void)setMaxConcurrentDownloads:(NSInteger)maxConcurrentDownloads
{
    _downloadQueue.maxConcurrentOperationCount = maxConcurrentDownloads;
}

- (NSUInteger)currentDownloadCount
{
    return _downloadQueue.operationCount;
}

- (NSInteger)maxConcurrentDownloads
{
    return _downloadQueue.maxConcurrentOperationCount;
}

#pragma mark - NSURLSessionDownloadDelegate
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    NSUInteger count = _URLOperations.allValues.count;
    for (int i = 0; i < count; i++) {
        BOOL flag = [_URLOperations.allValues objectAtIndex:i].downloadTask == downloadTask;
        if (flag) {
            NSURL *url = [_URLOperations.allValues objectAtIndex:i].downloadTask.currentRequest.URL;
            [_URLOperations.allValues objectAtIndex:i].bytesWritten = totalBytesWritten;
            [_URLOperations.allValues objectAtIndex:i].totalBytes = totalBytesExpectedToWrite;
            if(url){
                JXWebFileDownloaderProgressBlock progressBlock = self.progressBlocks[url];
                progressBlock(totalBytesWritten, totalBytesExpectedToWrite, url);
                break;
            }
            
            
        }
    }
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location
{
    NSURL *localFileURL = nil;
    NSData *fileData = [NSData dataWithContentsOfURL:location];
    
    NSUInteger count = _URLOperations.allValues.count;
    for (int i = 0; i < count; i++) {
        if ([_URLOperations.allValues objectAtIndex:i].downloadTask == downloadTask) {
            NSURL *url = [_URLOperations.allValues objectAtIndex:i].downloadTask.currentRequest.URL;
            [[JXFileCache sharedFileCache] storeFileDataToDiskForURL:url fileData:fileData];
            
            localFileURL = [[NSURL alloc] initWithString:[[JXFileCache sharedFileCache] fileFromDiskCacheForURL:url]];
            
            JXWebFileDownloaderCompletedBlock completedBlock = self.completedBlocks[url];
            completedBlock(localFileURL, nil, YES);
            [self.URLOperations removeObjectForKey:url];
            [self.completedBlocks removeObjectForKey:url];
            [self.progressBlocks removeObjectForKey:url];
            [[JXFileCache sharedFileCache]removeResumeDataFromResumeDataPathForURL:url];
            break;
        }
    }
}

#pragma mark - NSURLSessionTaskDelegate
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
didCompleteWithError:(nullable NSError *)error
{
    if ([error.userInfo objectForKey:NSURLSessionDownloadTaskResumeData]) {
        // check if resume data are available
        if ([error.userInfo objectForKey:NSURLSessionDownloadTaskResumeData]) {
            NSData *resumeData = [error.userInfo objectForKey:NSURLSessionDownloadTaskResumeData];
            //通过之前保存的resumeData，获取断点的NSURLSessionTask，调用resume恢复下载
            if ([self isValideResumeData:resumeData]) {
                [[JXFileCache sharedFileCache] storeResumeDataToDiskForURL:[NSURL URLWithString:[error.userInfo objectForKey:NSURLErrorFailingURLStringErrorKey]] resumeData:resumeData];
            }
        }
    } else {
        if (error.code == -999) {
            NSUInteger count = _URLOperations.allValues.count;
            for (int i = 0; i < count; i++) {
                if ([_URLOperations.allValues objectAtIndex:i].downloadTask == task) {
                    NSURL *url = task.currentRequest.URL;
                    JXWebFileDownloaderCompletedBlock completedBlock = self.completedBlocks[url];
                    completedBlock(nil, error, NO);
                    
                    [self.URLOperations removeObjectForKey:url];
                    [self.completedBlocks removeObjectForKey:url];
                    [self.progressBlocks removeObjectForKey:url];
                    [[JXFileCache sharedFileCache]removeResumeDataFromResumeDataPathForURL:url];
                    break;
                }
                
            }
        }
    }
    
    
}

- (BOOL)isValideResumeData:(NSData *)resumeData
{
    if (!resumeData || resumeData.length == 0) {
        return NO;
    }
    return YES;
}
@end
