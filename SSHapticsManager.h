//
//  SSHapticsManager.h


#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>
#import "Tweak.h"

@interface SSHapticsManager : NSObject
@property (nonatomic, assign) int feedbackTypeSegment;
@property (nonatomic, assign) int tapticStrength;
@property (nonatomic, assign) int hapticStrength;

+ (instancetype)sharedManager;
- (void) triggerFeedback;
- (void)actuateHapticsForType:(int)feedbackType;
- (void)hapticFeedback:(int)type tapticStrength:(int)tapticStrength hapticStrength:(int)hapticStrength;

@end
