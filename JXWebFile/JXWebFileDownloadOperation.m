//
//  JXWebFileDownloadOperation.m
//  JXWebFile
//
//  Created by 朱佳翔 on 2017/7/10.
//  Copyright © 2017年 zjx. All rights reserved.
//

#import "JXWebFileDownloadOperation.h"
#import "NSURLSession+CorrectedResumeData.h"
#import <UIKit/UIKit.h>

#define IS_IOS10ORLATER ([[[UIDevice currentDevice] systemVersion] floatValue] >= 10)

@interface JXWebFileDownloadOperation ()

@property(assign, nonatomic, getter=isExecuting) BOOL executing;
@property(assign, nonatomic, getter=isFinished) BOOL finished;
@property(weak, nonatomic, nullable) NSURLSession *session;
@property(strong, nonatomic, readwrite, nullable) NSURLSessionDownloadTask *downloadTask;
@property(strong, nonatomic) NSData *resumeData;

@end

@implementation JXWebFileDownloadOperation
@synthesize executing = _executing;
@synthesize finished = _finished;

- (nonnull instancetype)init
{
    return [self initWithRequest:nil session:nil];
}

- (instancetype)initWithRequest:(NSURLRequest *)request session:(NSURLSession *)session
{
    if ((self = [super init])) {
        _request = request;
        _session = session;
    }
    
    return self;
}

- (instancetype)initWithResumeData:(NSData *)resumeData session:(NSURLSession *)session
{
    if ((self = [super init])) {
        _resumeData = resumeData;
        _session = session;
    }
    
    return self;
}

- (void)start
{
    
    @synchronized(self)
    {
        if (_resumeData) {
            if (IS_IOS10ORLATER) {
                self.downloadTask= [self.session downloadTaskWithCorrectResumeData:_resumeData];
            }else {
                self.downloadTask = [self.session downloadTaskWithResumeData:_resumeData];
            }
            
        }else{
            self.downloadTask = [self.session downloadTaskWithRequest:self.request];
        }
        
    }
    [self.downloadTask resume];
    
}


- (void)cancel
{
    @synchronized(self)
    {
        [self cancelInternal];
    }
}

#pragma mark - Private APIs

- (void)cancelInternal
{
    if (self.isFinished)
        return;
    [super cancel];
    
    if (self.downloadTask) {
        [self.downloadTask cancel];
        
        if (self.isExecuting)
            self.executing = NO;
        if (!self.isFinished)
            self.finished = YES;
    }
}

- (void)done
{
    self.finished = YES;
    self.executing = NO;
}

- (void)setFinished:(BOOL)finished
{
    [self willChangeValueForKey:@"isFinished"];
    _finished = finished;
    [self didChangeValueForKey:@"isFinished"];
}

- (void)setExecuting:(BOOL)executing
{
    [self willChangeValueForKey:@"isExecuting"];
    _executing = executing;
    [self didChangeValueForKey:@"isExecuting"];
}
@end

