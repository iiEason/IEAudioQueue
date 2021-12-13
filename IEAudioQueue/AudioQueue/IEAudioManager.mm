//
//  IEAudioManager.m
//  IEAudioQueue
//
//  Created by L on 2021/12/8.
//

#import "IEAudioManager.h"
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>
#import <pthread.h>

#define kXDXRecoderAudioBytesPerPacket      2
#define kXDXRecoderAACFramesPerPacket       1024

static void AQInputCallBack (void *inUserData,
                             AudioQueueRef inAudioQueue,
                             AudioQueueBufferRef inBuffer,
                             const AudioTimeStamp *inStartTime,
                             UInt32               inNumPackets,
                             const AudioStreamPacketDescription *inPacketDesc) {
    IEAudioManager *manager = (__bridge IEAudioManager *) inUserData;
    if (!manager) {
        NSLog(@"manager is dealloc");
        return;
    }
    NSTimeInterval playedTime = inStartTime->mSampleTime / manager.aqc.mDataFormat.mSampleRate;
    printf("inNumPackets %d record time %f\n",
           inNumPackets,
           playedTime);
    if (inNumPackets > 0) {
        [manager processAudioBuffer:inBuffer
                          withQueue:inAudioQueue];
    }
    
    if (manager.aqc.run) {
        AudioQueueEnqueueBuffer(manager.aqc.queue,
                                inBuffer,
                                0,
                                NULL);
    }
    
}

@interface IEAudioManager ()

@property (nonatomic, assign) BOOL isRunning;

@end

@implementation IEAudioManager

/// 单例
+ (id)shareAudioManager {
    static IEAudioManager *recorder = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        recorder = [[IEAudioManager alloc] init];
    });
    return recorder;
}

/// 开始录音
-(void)start {
    
    if (_aqc.run) {
        NSLog(@"start failed : aqc run is true");
        return;
    }
    
    /*
     mBytesPerPacket: 每个音频包中有多少字节数

     mBytesPerFrame: 每一帧中有多少字节

     mFramesPerPacket: 每个包中有多少帧

     mBitsPerChannel: 每个声道有多少位
     
     mFormatFlags(metaflag): 某些audio unit使用不规则的音频数据格式即不同的音频数据类型，则mFormatFlags字段需要不同的标志集。 例如:3D Mixer unit需要UInt16类型数据作为采样值且mFormatFlags需要设置为kAudioFormatFlagsCanonical.
     */
    
    // 采样率
    _aqc.mDataFormat.mSampleRate = 16000.0;
    // 在一个数据帧中，每个通道的样本数据的位数
    _aqc.mDataFormat.mBitsPerChannel = 16;
    // 每帧数据通道数
    _aqc.mDataFormat.mChannelsPerFrame = 1;
    // 数据格式 PCM
    _aqc.mDataFormat.mFormatID = kAudioFormatLinearPCM;
    //每包数据帧数
    _aqc.mDataFormat.mFramesPerPacket = 1;
    // 每一帧中有多少字节(mBitsPerChannel:每个声道有多少位 / 8 ) * (mChannelsPerFrame：每帧数据通道数)
    _aqc.mDataFormat.mBytesPerFrame = (_aqc.mDataFormat.mBitsPerChannel / 8) * _aqc.mDataFormat.mChannelsPerFrame;
    
    //每个音频包中有多少字节数（mBytesPerFrame:每一帧中有多少字节）* (mFramesPerPacket: 每个包中有多少帧)
    _aqc.mDataFormat.mBytesPerPacket = _aqc.mDataFormat.mBytesPerFrame * _aqc.mDataFormat.mFramesPerPacket;
    
    _aqc.mDataFormat.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked;
    // 每帧大小
    _aqc.frameSize = kFrameSize;
    
    /*
     初始化音频输入队列
     参数1：所录制音频的格式AudioStreamBasicDescription类型。
     参数2：一个回调，当一个buffer被填充完成时，会触发这个回调。
     参数3：传入的
     参数4：要调用inCallbackProc的事件循环。如果指定NULL，
     则在其中一个音频队列的内部线程上调用回调。这个参数一般填写NULL。
     参数5：为Runloop模式，如果传入NULL就相当于kCFRunLoopCommonModes，一般这个参数也是填NULL
     参数6：保留字段，直接传0
     参数7：返回生成的AudioQueue实例，返回值用来判断是否成功创建
     
     */
    AudioQueueNewInput(&_aqc.mDataFormat,
                       AQInputCallBack,
                       (__bridge void *)(self),
                       NULL,
                       kCFRunLoopCommonModes,
                       0,
                       &_aqc.queue);
    for (int i=0; i<kNumberBuffers; i++) {
        /*
         通过AudioQueueAllocateBuffer生成生成若干个AudioQueueBufferRef结构，这些Buffer将用来存储即将要播放的音频数据，并且这些Buffer是受生成他们的AudioQueue实例管理的，内存空间也已经被分配（按照Allocate方法的参数），当AudioQueue被Dispose时这些Buffer也会随之被销毁
         */
        // 传入AudioQueue实例和Buffer大小，传出的Buffer实例
        AudioQueueAllocateBuffer(_aqc.queue, _aqc.frameSize, &_aqc.mBuffers[i]);
        /*
         把存有音频数据的Buffer插入到AudioQueue内置的Buffer队列中。在Buffer队列中有buffer存在的情况下调用AudioQueueStart，此时AudioQueue就回按照Enqueue顺序逐个使用Buffer队列中的buffer进行播放，每当一个Buffer使用完毕之后就会从Buffer队列中被移除并且在使用者指定的RunLoop上触发一个回调来告诉使用者，某个AudioQueueBufferRef对象已经使用完成，你可以继续重用这个对象来存储后面的音频数据。如此循环往复音频数据就会被逐个播放直到结束
         */
        AudioQueueEnqueueBuffer(_aqc.queue, _aqc.mBuffers[i], 0, NULL);
    }
    
    _aqc.run = 1;
    AudioQueueStart(_aqc.queue, NULL);
}

/// 暂停
- (void)pause {
    AudioQueuePause(_aqc.queue);
}


/// 停止
- (void)stop {
    [self cleanUp];
}

- (void)processAudioBuffer:(AudioQueueBufferRef)buffer
                 withQueue:(AudioQueueRef) queue {
    
    if (buffer) {
        char *psrc = (char *)buffer -> mAudioData;
        int bufLength = buffer -> mAudioDataByteSize;
        if (self.delegate &&
            [self.delegate respondsToSelector:@selector(processAudioPacket:length:)]) {
            [self.delegate processAudioPacket:psrc
                                       length:bufLength];
        }
    } else {
        NSLog(@"Audio Buffer is nil");
    }
    
}

- (void)dealloc {
    [self cleanUp];
}

- (void)cleanUp {
    if (_aqc.run != 0) {
        _aqc.run = 0;
        OSStatus status = AudioQueueStop(_aqc.queue,
                                         true);
        if (status != noErr) {
            for (int i = 0; i < kNumberBuffers; i++) {
                AudioQueueFreeBuffer(_aqc.queue, _aqc.mBuffers[i]);
            }
        }
        AudioQueueDispose(_aqc.queue, true);
        _aqc.queue = NULL;
    }
    
}

- (void)resetAudio {
    if (_aqc.run) {
        [self stop];
        [self start];
    } else {
        [self start];
    }
}

@end
