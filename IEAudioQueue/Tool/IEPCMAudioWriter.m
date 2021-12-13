//
//  IEPCMAudioWriter.m
//  IEAudioQueue
//
//  Created by L on 2021/12/7.
//

#import "IEPCMAudioWriter.h"

@implementation IEPCMAudioWriter {
    
    NSOutputStream *m_outputSteam;
    NSString *m_fileName;
    NSString *cachePath;
    
}

- (instancetype)init {
    
    if (self = [super init]) {
        [self setup];
    }
    return  self;
    
}

- (void)setup {
    
    if (!m_outputSteam) {
        NSArray *array = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        NSString *path = [[array objectAtIndex:0] stringByAppendingPathComponent:@"AudioFile"];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        BOOL isDir = NO;
        if (![fileManager fileExistsAtPath:path
                               isDirectory:&isDir]) {
            NSError *error = nil;
            [fileManager createDirectoryAtPath:path
                   withIntermediateDirectories:YES
                                    attributes:nil
                                         error:&error];
        }
        cachePath = [[array objectAtIndex:0] stringByAppendingPathComponent:@"AudioFile"];
        NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
        [fmt setDateFormat:@"YYYYMMDD-HHMMSS"];
        NSDate *current = [NSDate date];
        NSString *webcastId = [fmt stringFromDate:current];
        m_fileName = [cachePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.pcm",webcastId]];
        if ([fileManager fileExistsAtPath:m_fileName
                              isDirectory:&isDir]) {
            NSError *error = nil;
            BOOL result = [fileManager removeItemAtPath:m_fileName
                                                  error:&error];
            if (result) {
                NSLog(@"[IEPCMAudioWriter] remove PCM at %@",m_fileName);
                [fileManager createFileAtPath:m_fileName
                                     contents:nil
                                   attributes:nil];
            } else {
                [fileManager createFileAtPath:m_fileName
                                     contents:nil
                                   attributes:nil];
            }
            NSLog(@"[IEPCMAudioWriter] write PCM to %@",m_fileName);
            m_outputSteam = [[NSOutputStream alloc] initToFileAtPath:m_fileName append:YES];
            [m_outputSteam open];
        }
        
    }
    
}

/// 获得文件句柄
-(NSString *)getPCMHandler {
    return m_fileName;
}

/// 重置文件句柄
- (void)resetPCMHandler {
    
    NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
    [fmt setDateFormat:@"YYYYMMDD-HHMMSS"];
    NSDate *current = [NSDate date];
    NSString *webcastId = [fmt stringFromDate:current];
    [self resetPCMHandler:webcastId];
}

/// 重置文件句柄
/// @param filename 新的文件名
-(void)resetPCMHandler:(NSString *)filename {
    
    if (m_outputSteam) {
        [m_outputSteam close];
        m_outputSteam = nil;
    }
    m_fileName = [cachePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.pcm",filename]];
    BOOL isDir = NO;
    if([[NSFileManager defaultManager] fileExistsAtPath:m_fileName
                                            isDirectory:&isDir]){
        NSError *error = nil;
        BOOL result = [[NSFileManager defaultManager]
                       removeItemAtPath:m_fileName
                                  error:&error];
        if (result) {
            NSLog(@"[IEPCMAudioWriter] remove PCM at %@",m_fileName);
            [[NSFileManager defaultManager] createFileAtPath:m_fileName
                                                    contents:nil
                                                  attributes:nil];
        }
    }else {
        [[NSFileManager defaultManager] createFileAtPath:m_fileName
                                                contents:nil
                                              attributes:nil];
    }
    NSLog(@"[IEPCMAudioWriter] write PCM to %@",m_fileName);
    m_outputSteam = [[NSOutputStream alloc] initToFileAtPath:m_fileName
                                                      append:YES];
    [m_outputSteam open];
}

/// 删除PCM缓存文件
- (void)clearAllPCM {
    NSFileManager *manager = [NSFileManager defaultManager];
    NSArray *tempArray = [manager contentsOfDirectoryAtPath:cachePath
                                                      error:nil];
    for (NSString *fileName in tempArray) {
        BOOL flag = YES;
        NSString *fullPath = [cachePath stringByAppendingPathComponent:fileName];
        if ([manager fileExistsAtPath:fullPath
                          isDirectory:&flag]) {
            if (!flag) {
                [manager removeItemAtPath:fullPath
                                    error:nil];
            }
        }
    }
    m_fileName = nil;
}

/// 写入数据
/// @param data  void*类型指针
/// @param length 数据长度
- (void)writePCM:(void *)data
          length:(unsigned long)length {
    if (m_outputSteam) {
        [m_outputSteam write:(const uint8_t*)data
                   maxLength:length];
    }
}

@end
