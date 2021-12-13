//
//  IEPCMAudioWriter.h
//  IEAudioQueue
//
//  Created by L on 2021/12/7.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface IEPCMAudioWriter : NSObject

///  获得文件句柄
- (NSString *)getPCMHandler;

///  重置文件句柄
- (void)resetPCMHandler;

/// 重置文件句柄
/// @param filename 新文件名
- (void)resetPCMHandler:(NSString *)filename;

/// 写入数据
/// @param data void*类型指针
/// @param length 数据长度
- (void)writePCM:(void*)data length:(unsigned long)length;

/// 删除PCM缓存文件
- (void)clearAllPCM;

@end

NS_ASSUME_NONNULL_END
