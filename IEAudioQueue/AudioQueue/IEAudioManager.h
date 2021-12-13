//
//  IEAudioManager.h
//  IEAudioQueue
//
//  Created by L on 2021/12/8.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>

#define kNumberBuffers  3         // 使用多少个音频队列数据
#define kFrameSize      2048      // 每一帧的大小
#define kTVURecoderPCMMaxBuffSize    2048

typedef struct AQRecorderState {
    AudioStreamBasicDescription          mDataFormat; // 音频初始化参数
    AudioQueueRef _Nonnull               queue;       //  应用程序创建的录制音频队列
    AudioQueueBufferRef _Nonnull         mBuffers[kNumberBuffers];
    AudioFileID _Nonnull                 outputFile;  // 输出文件的标识
    unsigned int                         frameSize;   // 当前录制的文件的大小(单位是bytes)
    long long                            recPtr;
    int                                  run;
    
}AQRecorderState;

@protocol IEAudioManagerDelegate <NSObject>

/// 音频数据回调
/// @param data 音频数据
/// @param len 音频数据大小
- (void)processAudioPacket:(char *_Nonnull)data
                    length:(int)len;

@end


NS_ASSUME_NONNULL_BEGIN

@interface IEAudioManager : NSObject

@property (nonatomic, assign) AQRecorderState aqc;

@property (nonatomic, weak) id<IEAudioManagerDelegate> delegate;

@property (nonatomic, assign) AVAudioSessionCategoryOptions sessionCategoryOption;

+ (id)shareAudioManager;

- (void)start;

- (void)stop;

- (void)pause;

- (void)processAudioBuffer:(AudioQueueBufferRef)buffer
                 withQueue:(AudioQueueRef) queue;

@end

NS_ASSUME_NONNULL_END
