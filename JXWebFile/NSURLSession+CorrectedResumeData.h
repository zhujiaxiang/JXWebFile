//
//  NSURLSession+CorrectedResumeData.h
//  JXWebFile
//
//  Created by 朱佳翔 on 2017/7/10.
//  Copyright © 2017年 zjx. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSURLSession (CorrectedResumeData)

- (NSURLSessionDownloadTask *)downloadTaskWithCorrectResumeData:(NSData *)resumeData;


@end
