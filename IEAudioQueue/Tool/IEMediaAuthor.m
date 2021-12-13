//
//  IEMediaAuthor.m
//  IEAudioQueue
//
//  Created by L on 2021/12/7.
//

#import "IEMediaAuthor.h"
#import <AVFoundation/AVFoundation.h>

@implementation IEMediaAuthor

///  获取相机权限
/// @param completion 回调
+ (void)getAuthorCamera:(void (^ __nullable)(BOOL granted))completion {
    
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (authStatus == AVAuthorizationStatusAuthorized) {
        if (completion) {
            completion(YES);
        }
    } else if (authStatus == AVAuthorizationStatusDenied) {
        if (completion) {
            completion(NO);
        }
    } else if (authStatus == AVAuthorizationStatusRestricted) {
    } else if (authStatus == AVAuthorizationStatusNotDetermined) {
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:completion];
    } else {
    }
    
}

/// 获取麦克风访问权限
/// @param completion 回调
+ (void)getAuthorMicphone:(void (^ __nullable)(BOOL granted))completion {
    
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
    if(authStatus == AVAuthorizationStatusAuthorized) {
        if (completion) {
            completion(YES);
        }
    } else if(authStatus == AVAuthorizationStatusDenied){
        if (completion) {
            completion(NO);
        }
    } else if(authStatus == AVAuthorizationStatusRestricted){
    } else if(authStatus == AVAuthorizationStatusNotDetermined){
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio completionHandler:completion];
    } else {
    }
    
}

@end
