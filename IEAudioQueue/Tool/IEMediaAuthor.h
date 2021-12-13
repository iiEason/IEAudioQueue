//
//  IEMediaAuthor.h
//  IEAudioQueue
//
//  Created by L on 2021/12/7.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface IEMediaAuthor : NSObject

+ (void)getAuthorCamera:(void (^ __nullable)(BOOL granted))completion;

+ (void)getAuthorMicphone:(void (^ __nullable)(BOOL granted))completion;

@end

NS_ASSUME_NONNULL_END
