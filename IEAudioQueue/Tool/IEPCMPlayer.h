//
//  IEPCMPlayer.h
//  IEAudioQueue
//
//  Created by L on 2021/12/8.
//

#import <Foundation/Foundation.h>
#include <pthread.h>
#include <AudioToolbox/AudioToolbox.h>

#define kNumAQBufs 16

#define kAQDefaultBufSize 2048

#define kAQMaxPacketDescs 512

typedef enum {
    
    AS_INITIALIZED = 0,
    AS_STARTING_FILE_THREAD,
    AS_WAITING_FOR_DATA,
    AS_FLUSHING_EOF,
    AS_WAITING_FOR_QUEUE_TO_START,
    AS_PLAYING,
    AS_BUFFERING,
    AS_STOPPING,
    AS_STOPPED,
    AS_PAUSED
    
}AudioStreamerState;

NS_ASSUME_NONNULL_BEGIN

@interface IEPCMPlayer : NSObject {
    
    AudioQueueRef audioQueue;
    AudioFileStreamID audioFileStream;    // the audio file stream parser
    AudioStreamBasicDescription asbd;    // description of the audio
    AudioQueueBufferRef audioQueueBuffer[kNumAQBufs];        // audio queue buffers
    AudioStreamPacketDescription *aspd;
    unsigned int fillBufferIndex;    // the index of the audioQueueBuffer that is being filled
    UInt32 packetBufferSize;
    size_t bytesFilled;                // how many bytes have been filled
    size_t packetsFilled;            // how many packets have been filled
    bool inuse[kNumAQBufs];            // flags to indicate that a buffer is still in use
    NSInteger buffersUsed;
    
    AudioStreamerState state;
    OSStatus err;
    
    pthread_mutex_t queueBuffersMutex;            // a mutex to protect the inuse flags
    pthread_cond_t queueBufferReadyCondition;    // a condition varable for handling the inuse flags
    
}

- (instancetype)initWithPCMFile:(NSString *)path;

/**
 播放声音
 */
- (void)play;

/**
 停止播放
 */
- (void)stop;

- (void)setVolume:(float)vol;


@end

NS_ASSUME_NONNULL_END
