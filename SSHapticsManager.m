//
//  SSHapticsManager.h


#import "SSHapticsManager.h"

@interface SSHapticsManager ()

@property (strong, nonatomic) id hapticFeedbackGenerator;

@end

@implementation SSHapticsManager

+ (instancetype)sharedManager {
    static SSHapticsManager *sharedManager = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        sharedManager = [[self alloc] init];
    });
    return sharedManager;
}

- (id) init {
    self = [super init];
    if (self) {
        NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:@prefFile];
        
        _feedbackTypeSegment = ([prefs objectForKey:@"feedbackTypeSegment"] ? [[prefs objectForKey:@"feedbackTypeSegment"] intValue] : 1);
        _tapticStrength = ([prefs objectForKey:@"tapticStrength"] ? [[prefs objectForKey:@"tapticStrength"] intValue] : 1);
        _hapticStrength = ([prefs objectForKey:@"hapticStrength"] ? [[prefs objectForKey:@"hapticStrength"] intValue] : 1);
        
    }
    return self;
}

- (void) triggerFeedback {
    if ((_feedbackTypeSegment == 1 && _tapticStrength != 0) || (_feedbackTypeSegment == 2 && _hapticStrength != 0) ) {
        [self hapticFeedback:_feedbackTypeSegment tapticStrength:_tapticStrength hapticStrength:_hapticStrength];
    }
}

- (void)hapticFeedback:(int)type tapticStrength:(int)tapticStrength hapticStrength:(int)hapticStrength {
    if (type == 1 && tapticStrength != 0) {
        UIImpactFeedbackGenerator *gen = [[UIImpactFeedbackGenerator alloc] init];
        [gen prepare];

        if (tapticStrength == 1) {
            gen = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];

        } else if (tapticStrength == 2) {
            gen = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium];

        } else if (tapticStrength == 3) {
            gen = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleHeavy];

        } else if (tapticStrength == 4) {
            gen = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleSoft];

        } else if (tapticStrength == 5) {
            gen = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleRigid];

        }

        [gen impactOccurred];

    } else if (type == 2 && hapticStrength != 0) {
        if (hapticStrength == 1) {
            AudioServicesPlaySystemSound(1519);
        }

        else if (hapticStrength == 2) {
            AudioServicesPlaySystemSound(1520);
        }

        else if (hapticStrength == 3) {
            AudioServicesPlaySystemSound(1521);
        }
    }
}

- (void)actuateHapticsForType:(int)feedbackType {
    switch (feedbackType) {
        case 1:
            [self handleHapticFeedbackForSelection]; break;
        case 2:
            [self handleHapticFeedbackForImpactStyle:UIImpactFeedbackStyleLight]; break;
        case 3:
            [self handleHapticFeedbackForImpactStyle:UIImpactFeedbackStyleMedium]; break;
        case 4:
            [self handleHapticFeedbackForImpactStyle:UIImpactFeedbackStyleHeavy]; break;
        case 5:
            [self handleHapticFeedbackForSuccess]; break;
        case 6:
            [self handleHapticFeedbackForWarning]; break;
    }
}

- (void)handleHapticFeedbackForImpactStyle:(UIImpactFeedbackStyle)style {
    if (@available(iOS 10.0, *)) {
        dispatch_async(dispatch_get_main_queue(), ^{
            _hapticFeedbackGenerator = [[UIImpactFeedbackGenerator alloc] initWithStyle:style];
            [_hapticFeedbackGenerator prepare];
            [_hapticFeedbackGenerator impactOccurred];
            _hapticFeedbackGenerator = nil;
        });
    }
}

- (void)handleHapticFeedbackForError {
    if (@available(iOS 10.0, *)) {
        dispatch_async(dispatch_get_main_queue(), ^{
            _hapticFeedbackGenerator = [[UINotificationFeedbackGenerator alloc] init];
            [_hapticFeedbackGenerator prepare];
            [_hapticFeedbackGenerator notificationOccurred:UINotificationFeedbackTypeError];
            _hapticFeedbackGenerator = nil;
        });
    }
}

- (void)handleHapticFeedbackForSelection {
    if (@available(iOS 10.0, *)) {
        dispatch_async(dispatch_get_main_queue(), ^{
            _hapticFeedbackGenerator = [[UISelectionFeedbackGenerator alloc] init];
            [_hapticFeedbackGenerator prepare];
            [_hapticFeedbackGenerator selectionChanged];
            _hapticFeedbackGenerator = nil;
        });
    }
}

- (void)handleHapticFeedbackForSuccess {
    if (@available(iOS 10.0, *)) {
        dispatch_async(dispatch_get_main_queue(), ^{
            _hapticFeedbackGenerator = [[UINotificationFeedbackGenerator alloc] init];
            [_hapticFeedbackGenerator prepare];
            [_hapticFeedbackGenerator notificationOccurred:UINotificationFeedbackTypeSuccess];
            _hapticFeedbackGenerator = nil;
        });
    }
}

- (void)handleHapticFeedbackForWarning {
    if (@available(iOS 10.0, *)) {
        dispatch_async(dispatch_get_main_queue(), ^{
            _hapticFeedbackGenerator = [[UINotificationFeedbackGenerator alloc] init];
            [_hapticFeedbackGenerator prepare];
            [_hapticFeedbackGenerator notificationOccurred:UINotificationFeedbackTypeWarning];
            _hapticFeedbackGenerator = nil;
        });
    }
}

@end
