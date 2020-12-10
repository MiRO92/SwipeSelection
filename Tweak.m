// **************************************************** //
// **************************************************** //
// **********        Design outline          ********** //
// **************************************************** //
// **************************************************** //
//
// 1 finger moves the cursour
// 2 fingers moves it one word at a time
//
// Should be able to move between 1 and 2 fingers without lifting your hand.
// If a selection has been made and you move right the selection starts moving from the end.
// - else it starts at the beginning.
//
// Holding shift selects text between the starting point and the destination.
// - the starting point is the reverse of the non selection movement.
// - - movement to the right starts at the start of existing selections.
//
// Movement upwards when in 2 finger mode should jump to the nearest word in the new line.
// - But another movement up again (without sideways movement) will jump to the nearest word to the originals x location,
// - - this ensures that the cursour doesn't jump about moving far away from it's start point.
//


#import "Tweak.h"
extern "C" CFNotificationCenterRef CFNotificationCenterGetDistributedCenter(void);

// Should finish deadZone so SS will run
CGFloat deadZone = 20;

BOOL enabledSwitch = YES;
BOOL enabledCursorUpDown = YES;
BOOL showSelection = YES;
BOOL enabledSwipeExtenderX = NO;
BOOL enableKeyboardFade = NO;
BOOL onlyInSpaceKey = NO;
BOOL disableTrackpad = NO;
BOOL deleteKeySound = YES;
int cursorSpeed = 10;

static UITextRange *range;
static NSString *textRange;
static UIResponder <UITextInput> *tempDelegate;
static UIResponder <UITextInput> *delegate;
static WKContentView *webView;

#pragma mark - Helper functions

UITextPosition *KH_MovePositionDirection(id <UITextInput, UITextInputTokenizer> tokenizer, UITextPosition *startPosition, UITextDirection direction) {
    if (tokenizer && startPosition) {
        return [tokenizer positionFromPosition:startPosition inDirection:direction offset:1];
    }
    return nil;
}

UITextPosition *KH_tokenizerMovePositionWithGranularitInDirection(id <UITextInput, UITextInputTokenizer> tokenizer, UITextPosition *startPosition, UITextGranularity granularity, UITextDirection direction) {

    if (tokenizer && startPosition) {
        return [tokenizer positionFromPosition:startPosition toBoundary:granularity inDirection:direction];
    }

    return nil;
}

BOOL KH_positionsSame(id <UITextInput, UITextInputTokenizer> tokenizer, UITextPosition *position1, UITextPosition *position2) {
    return ([tokenizer comparePosition:position1 toPosition:position2] == NSOrderedSame);
}

static void ShiftCaretToOneCharacter(id<UITextInput> delegate, UITextLayoutDirection direction) {
    UITextPosition *position = [delegate positionFromPosition:delegate.selectedTextRange.start inDirection:direction offset:1];
    if (!position)
        return;
    UITextRange *range = [delegate textRangeFromPosition:position toPosition:position];
    delegate.selectedTextRange = range;
}


#pragma mark - GestureRecognizer
@interface SSPanGesture : UIPanGestureRecognizer
@end

@implementation SSPanGesture
- (BOOL)canBePreventedByGestureRecognizer:(UIGestureRecognizer *)gesture {
    if (([gesture isKindOfClass:[UIPanGestureRecognizer class]] && ![gesture isKindOfClass:[SSPanGesture class]]) || [gesture isKindOfClass:[UISwipeGestureRecognizer class]]) {
        // if (enabledSwipeExtenderX) return YES;
        return YES;
    }
    return NO;
}

- (BOOL)canPreventGestureRecognizer:(UIGestureRecognizer *)gesture {
    return NO;
}
@end


%group globalGroup

#pragma mark - Hooks
%hook UIKeyboardImpl

- (id)initWithFrame:(CGRect)rect {
    id orig = %orig;

    if (orig) {
        SSPanGesture *panRightLeft = [[SSPanGesture alloc] initWithTarget:self action:@selector(SSLeftRightGesture:)];
        panRightLeft.cancelsTouchesInView = NO;
        [self addGestureRecognizer:panRightLeft];
        
        if (enabledCursorUpDown) {
            SSPanGesture *panUpDown = [[SSPanGesture alloc] initWithTarget:self action:@selector(SSUpDownGesture:)];
            panUpDown.cancelsTouchesInView = NO;
            [self addGestureRecognizer:panUpDown];
        }
    }

    return orig;
}



- (void)layoutSubviews {
    %orig;
    if (@available(iOS 14.0, *)) {
        BOOL found = NO;
        for (UIGestureRecognizer *gesture in self.gestureRecognizers) {
            if ([gesture isKindOfClass:[SSPanGesture class]]) {
                found = YES;
            }
        }
        
        if (!found) {
            SSPanGesture *panRightLeft = [[SSPanGesture alloc] initWithTarget:self action:@selector(SSLeftRightGesture:)];
            panRightLeft.cancelsTouchesInView = NO;
            [self addGestureRecognizer:panRightLeft];
            
            if (enabledCursorUpDown) {
                SSPanGesture *panUpDown = [[SSPanGesture alloc] initWithTarget:self action:@selector(SSUpDownGesture:)];
                panUpDown.cancelsTouchesInView = NO;
                [self addGestureRecognizer:panUpDown];
            }
        }
    }
}



%new
- (void)SSUpDownGesture:(UIPanGestureRecognizer *)gesture {
    static CGPoint previousPosition;
    static CGFloat yOffset = 0;
    static CGPoint realPreviousPosition;

    static BOOL hasStarted = NO;
    static BOOL feedback = NO;
    static BOOL longPress = NO;
    static BOOL handWriting = NO;
    static BOOL haveCheckedHand = NO;
    static BOOL cancelled = NO;

    int touchesCount = [gesture numberOfTouches];

    // Stop it from running in Emoji keyboard
    if ([[[NSClassFromString(@"UIKeyboardInputModeController") sharedInputModeController] currentInputMode].normalizedIdentifier isEqualToString:@"emoji"]) return;

    UIKeyboardImpl *keyboardImpl = self;
    if ([keyboardImpl isTrackpadMode] && !enableKeyboardFade) return;
            
    if ([keyboardImpl respondsToSelector:@selector(isLongPress)]) {
        if ([keyboardImpl isLongPress]) {
            longPress = [keyboardImpl isLongPress];
        }
    }

    // Get current layout
    id currentLayout = nil;
    if ([keyboardImpl respondsToSelector:@selector(_layout)]) {
        currentLayout = [keyboardImpl _layout];
    }

    // Hand writing recognition
    if ([currentLayout respondsToSelector:@selector(handwritingPlane)] && !haveCheckedHand) {
        handWriting = [currentLayout handwritingPlane];
    }
    else if ([currentLayout respondsToSelector:@selector(subviews)] && !handWriting && !haveCheckedHand) {
        NSArray *subviews = [((UIView *)currentLayout) subviews];
        for (UIView *subview in subviews) {

            if ([subview respondsToSelector:@selector(subviews)]) {
                NSArray *arrayToCheck = [subview subviews];

                for (id view in arrayToCheck) {
                    NSString *classString = [NSStringFromClass([view class]) lowercaseString];
                    NSString *substring = [@"Handwriting" lowercaseString];

                    if ([classString rangeOfString:substring].location != NSNotFound) {
                        handWriting = YES;
                        break;
                    }
                }
            }
        }
        haveCheckedHand = YES;
    }
    haveCheckedHand = YES;

    // Get the text input
    id <UITextInputPrivate> delegate = nil;
    if ([keyboardImpl respondsToSelector:@selector(privateInputDelegate)]) {
        delegate = (id)keyboardImpl.privateInputDelegate;
    }
    if (!delegate && [keyboardImpl respondsToSelector:@selector(inputDelegate)]) {
        delegate = (id)keyboardImpl.inputDelegate;
    }

    // Start Gesture stuff
    if (gesture.state == UIGestureRecognizerStateEnded || gesture.state == UIGestureRecognizerStateCancelled) {
        if (feedback) {
            [[SSHapticsManager sharedManager] triggerFeedback];
            feedback = NO;
        }

        longPress = NO;
        hasStarted = NO;
        feedback = NO;
        handWriting = NO;
        haveCheckedHand = NO;
        cancelled = NO;

        touchesCount = 0;
        gesture.cancelsTouchesInView = NO;
        
        if ([currentLayout respondsToSelector:@selector(didEndIndirectSelectionGesture:)] && enableKeyboardFade) {
            [currentLayout didEndIndirectSelectionGesture:YES];
        }
    } else if (([keyboardImpl isTrackpadMode] && !enableKeyboardFade) || longPress || handWriting || !delegate || cancelled) {
        if ([currentLayout respondsToSelector:@selector(didEndIndirectSelectionGesture:)] && enableKeyboardFade) {
            [currentLayout didEndIndirectSelectionGesture:YES];
        }
        return;
        
    } else if (gesture.state == UIGestureRecognizerStateBegan) {
        if ([keyboardImpl isTrackpadMode] && !enableKeyboardFade) return;

        yOffset = 0;

        previousPosition = [gesture locationInView:self];
        realPreviousPosition = previousPosition;

    } else if (gesture.state == UIGestureRecognizerStateChanged) {
        if ([keyboardImpl isTrackpadMode] && !enableKeyboardFade) return;

        CGPoint position = [gesture locationInView:self];
        CGPoint delta = CGPointMake(position.x - previousPosition.x, position.y - previousPosition.y);

        // If hasn't started, and it's moved less than  deadZone then we should kill it.
        if (hasStarted == NO && delta.y < deadZone && delta.y > (-deadZone)) return;
        
        if (!feedback) {
            [[SSHapticsManager sharedManager] triggerFeedback];
            feedback = YES;
        }
        
        
        if ([currentLayout respondsToSelector:@selector(willBeginIndirectSelectionGesture:)] && enableKeyboardFade) [currentLayout willBeginIndirectSelectionGesture:YES];

        // We are running so shut other things off/down
        gesture.cancelsTouchesInView = YES;
        hasStarted = YES;

        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(SSLeftRightGesture:) object:nil];

        // Make x positive for comparison
        CGFloat positiveY = ABS(delta.y);
        
        // Only do these new big 'jumps' if we've moved far enough
        CGFloat yMinimum = cursorSpeed;

        // Should I change X?
        if (positiveY > yMinimum) {
            previousPosition = position;
        }

        yOffset += (position.y - realPreviousPosition.y);

        if (ABS(yOffset) >= yMinimum) {
            BOOL positive = (yOffset > 0);
            int offset = (ABS(yOffset) / yMinimum);

            for (int i = 0; i < offset; i++) {
                if (!positive) {
                    ShiftCaretToOneCharacter(delegate, UITextLayoutDirectionUp);
                } else {
                    ShiftCaretToOneCharacter(delegate, UITextLayoutDirectionDown);
                }
            }
            yOffset += (positive ? -(offset * yMinimum) : (offset * yMinimum));
        }

        realPreviousPosition = position;
    }
}

%new
- (void)SSLeftRightGesture:(UIPanGestureRecognizer *)gesture {
    // Location info (may change)
    static UITextRange *startingTextRange = nil;
    static CGPoint previousPosition;

    // webView fix
    static CGFloat xOffset = 0;
    static CGPoint realPreviousPosition;

    // Basic info
    static BOOL selectionIsOn = NO;
    static BOOL hasStarted = NO;
    static BOOL feedback = NO;
    static BOOL longPress = NO;
    static BOOL isSpaceKey = NO;
    static BOOL handWriting = NO;
    static BOOL haveCheckedHand = NO;
    static BOOL isFirstShiftDown = NO;
    static BOOL isMoreKey = NO;
    static int touchesWhenShiting = 0;
    static BOOL cancelled = NO;

    int touchesCount = [gesture numberOfTouches];

    if ([[[NSClassFromString(@"UIKeyboardInputModeController") sharedInputModeController] currentInputMode].normalizedIdentifier isEqualToString:@"emoji"]) return;

    UIKeyboardImpl *keyboardImpl = self;
    if ([keyboardImpl isTrackpadMode] && !enableKeyboardFade) return;

    if ([keyboardImpl respondsToSelector:@selector(isLongPress)]) {
        if ([keyboardImpl isLongPress]) {
            longPress = [keyboardImpl isLongPress];
        }
    }

    // Get current layout
    id currentLayout = nil;
    if ([keyboardImpl respondsToSelector:@selector(_layout)]) {
        currentLayout = [keyboardImpl _layout];
    }

    // Check more key, unless it's already use
    if ([currentLayout respondsToSelector:@selector(SS_disableSwipes)] && !isMoreKey) {
        isMoreKey = [currentLayout SS_disableSwipes];
    }
    
    if ([currentLayout respondsToSelector:@selector(SS_isSpaceKey)] && !isSpaceKey) {
        isSpaceKey = [currentLayout SS_isSpaceKey];
    }
    

    // Hand writing recognition
    if ([currentLayout respondsToSelector:@selector(handwritingPlane)] && !haveCheckedHand) {
        handWriting = [currentLayout handwritingPlane];
    }
    else if ([currentLayout respondsToSelector:@selector(subviews)] && !handWriting && !haveCheckedHand) {
        NSArray *subviews = [((UIView *)currentLayout) subviews];
        for (UIView *subview in subviews) {

            if ([subview respondsToSelector:@selector(subviews)]) {
                NSArray *arrayToCheck = [subview subviews];

                for (id view in arrayToCheck) {
                    NSString *classString = [NSStringFromClass([view class]) lowercaseString];
                    NSString *substring = [@"Handwriting" lowercaseString];

                    if ([classString rangeOfString:substring].location != NSNotFound) {
                        handWriting = YES;
                        break;
                    }
                }
            }
        }
        haveCheckedHand = YES;
    }
    haveCheckedHand = YES;

    // Check for shift key being pressed
    if ([currentLayout respondsToSelector:@selector(SS_shouldSelect)] && !selectionIsOn) {
        selectionIsOn = [currentLayout SS_shouldSelect];
        isFirstShiftDown = YES;
        touchesWhenShiting = touchesCount;
    }
    
    if (onlyInSpaceKey && !isSpaceKey && !selectionIsOn) return;

    // Get the text input
    id <UITextInputPrivate> delegate = nil;
    if ([keyboardImpl respondsToSelector:@selector(privateInputDelegate)]) {
        delegate = (id)keyboardImpl.privateInputDelegate;
    }
    if (!delegate && [keyboardImpl respondsToSelector:@selector(inputDelegate)]) {
        delegate = (id)keyboardImpl.inputDelegate;
    }
    
    if ([NSStringFromClass([delegate class]) isEqualToString:@"WKContentView"]) webView = (WKContentView *)delegate;


    // Start Gesture stuff
    if (gesture.state == UIGestureRecognizerStateEnded || gesture.state == UIGestureRecognizerStateCancelled) {
        if (feedback) {
            [[SSHapticsManager sharedManager] triggerFeedback];
            feedback = NO;
        }

        if (hasStarted) {
            if (webView && [webView respondsToSelector:@selector(markedTextRange)]) {
                UITextRange *range = [webView markedTextRange];
                if (range && !range.empty && [keyboardImpl respondsToSelector:@selector(showSelectionCommands)] && showSelection) {
                    [keyboardImpl showSelectionCommands];
                }
            } else if ([delegate respondsToSelector:@selector(selectedTextRange)]) {
                UITextRange *range = [delegate selectedTextRange];
                if (range && !range.empty && [keyboardImpl respondsToSelector:@selector(showSelectionCommands)] && showSelection) {
                    [keyboardImpl showSelectionCommands];
                }
            }

            // Tell auto correct/suggestions the cursor has moved
            if ([keyboardImpl respondsToSelector:@selector(updateForChangedSelection)]) {
                [keyboardImpl updateForChangedSelection];
            }
        }

        selectionIsOn = NO;
        isMoreKey = NO;
        longPress = NO;
        isSpaceKey = NO;
        hasStarted = NO;
        feedback = NO;
        handWriting = NO;
        haveCheckedHand = NO;
        cancelled = NO;

        touchesCount = 0;
        touchesWhenShiting = 0;
        gesture.cancelsTouchesInView = NO;
        
        if ([currentLayout respondsToSelector:@selector(didEndIndirectSelectionGesture:)] && enableKeyboardFade) {
            [currentLayout didEndIndirectSelectionGesture:YES];
        }
    } else if (([keyboardImpl isTrackpadMode] && !enableKeyboardFade) || longPress || handWriting || !delegate || isMoreKey || cancelled) {
        if ([currentLayout respondsToSelector:@selector(didEndIndirectSelectionGesture:)] && enableKeyboardFade) {
            [currentLayout didEndIndirectSelectionGesture:YES];
        }
        return;
        
    } else if (gesture.state == UIGestureRecognizerStateBegan) {
        if ([keyboardImpl isTrackpadMode] && !enableKeyboardFade) return;

        xOffset = 0;

        previousPosition = [gesture locationInView:self];
        realPreviousPosition = previousPosition;

        if ([delegate respondsToSelector:@selector(selectedTextRange)]) {
            startingTextRange = nil;
            startingTextRange = [delegate selectedTextRange];
        }
                
    } else if (gesture.state == UIGestureRecognizerStateChanged) {
        if ([keyboardImpl isTrackpadMode] && !enableKeyboardFade) return;

        UITextRange *currentRange = startingTextRange;
        if ([delegate respondsToSelector:@selector(selectedTextRange)]) {
            currentRange = nil;
            currentRange = [delegate selectedTextRange];
        }

        CGPoint position = [gesture locationInView:self];
        CGPoint delta = CGPointMake(position.x - previousPosition.x, position.y - previousPosition.y);


        // If hasn't started, and it's moved less than  deadZone then we should kill it.
        if (hasStarted == NO && delta.x < deadZone && delta.x > (-deadZone)) return;
        
        if (!feedback) {
            [[SSHapticsManager sharedManager] triggerFeedback];
            feedback = YES;
        }
        
        if ([currentLayout respondsToSelector:@selector(willBeginIndirectSelectionGesture:)] && enableKeyboardFade) [currentLayout willBeginIndirectSelectionGesture:YES];

        // We are running so shut other things off/down
        gesture.cancelsTouchesInView = YES;
        hasStarted = YES;
        
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(SSUpDownGesture:) object:nil];
        if ([self respondsToSelector:@selector(LSChangeInputGesture:)]) {
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(LSChangeInputGesture:) object:nil];
        }
        
        // Make x positive for comparison
        CGFloat positiveX = ABS(delta.x);

        // Determine the direction it should be going in
        UITextDirection textDirection;
        if (delta.x < 0) {
            textDirection = UITextStorageDirectionBackward;
        } else {
            textDirection = UITextStorageDirectionForward;
        }
        
        // Only do these new big 'jumps' if we've moved far enough
        CGFloat xMinimum = cursorSpeed;
        CGFloat neededTouches = 2;
        if (selectionIsOn && (touchesWhenShiting >= 2)) {
            neededTouches = 3;
        }

        UITextGranularity granularity = UITextGranularityCharacter;
        // Handle different touches
        if (touchesCount >= neededTouches) {
            // make it skip words
            granularity = UITextGranularityWord;
            xMinimum = 20;
        }


        // Get the new range
        UITextPosition *positionStart = currentRange.start;
        UITextPosition *positionEnd = currentRange.end;

        // If this is the first run we are selecting then pick our pivot point
        static UITextPosition *pivotPoint = nil;
        if (isFirstShiftDown) {
            pivotPoint = nil;
            if (delta.x > 0 || delta.y < -20) {
                pivotPoint = positionStart;
            } else {
                pivotPoint = positionEnd;
            }
        }
        
        // The moving position is
        UITextPosition *_position = nil;

        if (selectionIsOn && pivotPoint) {
            // Find which position isn't our pivot and move that.
            BOOL startIsPivot = KH_positionsSame(delegate, pivotPoint, positionStart);
            if (startIsPivot) {
                _position = positionEnd;
            } else {
                _position = positionStart;
            }
            
        } else {
            _position = (delta.x > 0) ? positionEnd : positionStart;
            if (!pivotPoint) {
                pivotPoint = _position;
            }
        }

        // Is it right to left at the current selection point?
        
        if (webView && [webView baseWritingDirectionForPosition:_position inDirection:UITextStorageDirectionForward]) {
            if (textDirection == UITextStorageDirectionForward) {
                textDirection = UITextStorageDirectionBackward;
            } else {
                textDirection = UITextStorageDirectionForward;
            }
        
        } else if ([delegate baseWritingDirectionForPosition:_position inDirection:UITextStorageDirectionForward] == NSWritingDirectionRightToLeft) {
            if (textDirection == UITextStorageDirectionForward) {
                textDirection = UITextStorageDirectionBackward;
            } else {
                textDirection = UITextStorageDirectionForward;
            }
        }

        // Try and get the tokenizer
        id <UITextInputTokenizer, UITextInput> tokenizer = nil;
            
        if ([delegate respondsToSelector:@selector(positionFromPosition:toBoundary:inDirection:)]) {
            tokenizer = delegate;
            
        } else if ([delegate respondsToSelector:@selector(tokenizer)]) {
            tokenizer = (id <UITextInput, UITextInputTokenizer>)delegate.tokenizer;
        }

        if (tokenizer) {
            // Move X
            if (positiveX >= 1) {
                UITextPosition *_position_old = _position;

                if (granularity == UITextGranularityCharacter && [tokenizer respondsToSelector:@selector(positionFromPosition:inDirection:offset:)] && NO) {
                    _position = KH_MovePositionDirection(tokenizer, _position, textDirection);
                } else {
                    _position = KH_tokenizerMovePositionWithGranularitInDirection(tokenizer, _position, granularity, textDirection);
                }

                // If I tried to move it and got nothing back reset it to what I had.
                if (!_position) { _position = _position_old; }

                // If I tried to move it a word at a time and nothing happened
                if (granularity == UITextGranularityWord && (KH_positionsSame(delegate, currentRange.start, _position) && !KH_positionsSame(delegate, delegate.beginningOfDocument, _position))) {

                    _position = KH_tokenizerMovePositionWithGranularitInDirection(tokenizer, _position, UITextGranularityCharacter, textDirection);
                    xMinimum = 4;
                }

                // Another sanity check
                if (!_position || positiveX < xMinimum) {
                    _position = _position_old;
                }
            }
        }

        if (!selectionIsOn && _position) {
            pivotPoint = nil;
            pivotPoint = _position;
        }

        // Get a new text range
        UITextRange *textRange = startingTextRange = nil;
        if ([delegate respondsToSelector:@selector(textRangeFromPosition:toPosition:)]) {
            textRange = [delegate textRangeFromPosition:pivotPoint toPosition:_position];
        }
        
        CGPoint oldPrevious = previousPosition;
        // Should I change X?
        if (positiveX > xMinimum) {
            previousPosition = position;
        }
        isFirstShiftDown = NO;

        
        // Handle Safari's broken UITextInput support
        if (webView) {
            xOffset += (position.x - realPreviousPosition.x);

            if (ABS(xOffset) >= xMinimum) {
                BOOL positive = (xOffset > 0);
                int offset = (ABS(xOffset) / xMinimum);

                for (int i = 0; i < offset; i++) {
                    if (selectionIsOn) {
                        if (positive) {
                            [webView _moveRight:YES withHistory:nil];
                        } else {
                            [webView _moveLeft:YES withHistory:nil];
                        }
                    } else {
                        [webView moveByOffset:(positive ? 1 : -1)];
                    }
                }
                xOffset += (positive ? -(offset * xMinimum) : (offset * xMinimum));
            }
        }

        // Normal text input
        if (textRange && (oldPrevious.x != previousPosition.x || oldPrevious.y != previousPosition.y)) {
            [delegate setSelectedTextRange:textRange];
        }
        realPreviousPosition = position;
    }
}
%end


static BOOL deleteKeyPressed = NO;
static BOOL isLongPressed = NO;
static BOOL isDeleteKey = NO;
static BOOL isSpaceKey = NO;
static BOOL isMoreKey = NO;
static BOOL triggerDelete = NO;

%hook UIKeyboardDockView
- (id)_keyboardLongPressInteractionRegions {
    if (disableTrackpad) {
        NSMutableArray<NSValue *> *regions = [NSMutableArray array];
        return regions;
    }
    return %orig;
}
%end

%hook UIKeyboardLayout
- (id)_keyboardLongPressInteractionRegions {
    if (disableTrackpad) {
        NSMutableArray<NSValue *> *regions = [NSMutableArray array];
        return regions;
    }
    return %orig;
}
%end

%hook UIKeyboardLayoutStar
- (void)layoutSubviews {
    %orig;
    if (disableTrackpad) self.gestureRecognizers = [NSArray new];
}

/*==============touchesBegan================*/
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    
    UIKBKey *keyObject = [self keyHitTest:[touch locationInView:touch.view]];
    NSString *key = [[keyObject representedString] lowercaseString];
//    NSLog(@"key=[%@]  -  keyObject=%@  -  flickDirection = %d", key, keyObject, [(UIKBTree *)keyObject flickDirection]);
    
    // Delete key
    if ([key isEqualToString:@"delete"]) {
        isDeleteKey = YES;
    } else {
        isDeleteKey = NO;
    }
    
    if ([key isEqualToString:@" "]) {
        isSpaceKey = YES;
    } else {
        isSpaceKey = NO;
    }
    
    // More key
    if ([key isEqualToString:@"more"]) {
        isMoreKey = YES;
    } else {
        isMoreKey = NO;
    }
    
    %orig;
}

/*==============touchesMoved================*/
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    
    UIKBKey *keyObject = [self keyHitTest:[touch locationInView:touch.view]];
    NSString *key = [[keyObject representedString] lowercaseString];
    
    // Delete key (or the arabic key which is where the shift key would be)
    if ([key isEqualToString:@"delete"] ||
        [key isEqualToString:@"ء"] ||
        [key isEqualToString:@"ㄈ"]) {
        deleteKeyPressed = YES;
    }
    
    if ([key isEqualToString:@" "]) {
        isSpaceKey = YES;
    } else {
        isSpaceKey = NO;
    }

    // More key
    if ([key isEqualToString:@"more"]) {
        isMoreKey = YES;
    } else {
        isMoreKey = NO;
    }
    
//    NSLog(@"miroo key \"%@\"", key);
    
    %orig;
}

- (void)touchesCancelled:(id)arg1 withEvent:(id)arg2 {
    %orig(arg1, arg2);
    
    deleteKeyPressed = NO;
    isSpaceKey = NO;
    isLongPressed = NO;
    isMoreKey = NO;
}

/*==============touchesEnded================*/
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    %orig;
    
    isDeleteKey = NO;
    
    UITouch *touch = [touches anyObject];
    NSString *key = [[[self keyHitTest:[touch locationInView:touch.view]] representedString] lowercaseString];
    
    
    // Delete key
    if ([key isEqualToString:@"delete"] && !isLongPressed) {
        UIKeyboardImpl *kb = [UIKeyboardImpl activeInstance];
        if ([kb respondsToSelector:@selector(handleDelete)]) {
            triggerDelete = YES;
            [kb handleDelete];
            if (deleteKeySound) AudioServicesPlaySystemSound(1155);
        }
    }

    deleteKeyPressed = NO;
    isSpaceKey = NO;
    isLongPressed = NO;
    isMoreKey = NO;
}

%new
- (BOOL)SS_shouldSelect {
    return ([self isShiftKeyBeingHeld] || deleteKeyPressed);
}

%new
- (BOOL)SS_isSpaceKey {
    return isSpaceKey;
}

%new
- (BOOL)SS_disableSwipes {
    return isMoreKey;
}
%end
    
/*==============UIKeyboardImpl================*/
%hook UIKeyboardImpl

// Doesn't work to get long press on delete key but does for other keys.
- (BOOL)isLongPress {
    isLongPressed = %orig;
    
    if (isLongPressed) [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(SSLeftRightGesture:) object:nil];
    if (isLongPressed) [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(SSUpDownGesture:) object:nil];
    
    return isLongPressed;
}

- (BOOL)isTrackpadMode {
    BOOL isTrackpadMode = %orig;
    
    if (isTrackpadMode) [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(SSLeftRightGesture:) object:nil];
    if (isTrackpadMode) [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(SSUpDownGesture:) object:nil];

    return isTrackpadMode;
}

//- (void)handleDelete {
//    if (!isLongPressed && isDeleteKey) {
//
//    }
//    else {
//        %orig;
//    }
//}

- (void)handleDeleteAsRepeat:(BOOL)repeat executionContext:(UIKeyboardTaskExecutionContext *)executionContext {
    isLongPressed = repeat;
    if ([[UIKeyboardImpl activeInstance] isInHardwareKeyboardMode] || (isLongPressed && isDeleteKey)) {
        %orig;
        
    } else if (triggerDelete && !isLongPressed) {
        repeat = NO;
        %orig;
        
    } else {
        [[executionContext executionQueue] finishExecution];
    }
    
    triggerDelete = NO;
    return;
}
%end



//%hook WKWebView
//%new
//- (NSString *)stringByEvaluatingJavaScriptFromString:(NSString *)script {
//    __block NSString *resultString = nil;
//    __block BOOL finished = NO;
//
//    [self evaluateJavaScript:script completionHandler:^(id result, NSError *error) {
//        if (error == nil) {
//            if (result != nil) {
//                resultString = [NSString stringWithFormat:@"%@", result];
//            }
//        } else {
//            NSLog(@"miroo error : %@", error.localizedDescription);
//        }
//        finished = YES;
//    }];
//
//    while (!finished) {
//        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
//    }
//
//    return resultString;
//}
//%end
%end // globalGroup




static void loadPrefs() {
    NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:@prefFile];

    enabledSwitch = ([prefs objectForKey:@"enabledSwitch"] ? [[prefs objectForKey:@"enabledSwitch"] boolValue] : YES);
    enabledCursorUpDown = ([prefs objectForKey:@"enabledCursorUpDown"] ? [[prefs objectForKey:@"enabledCursorUpDown"] boolValue] : YES);
    deadZone = ([prefs objectForKey:@"deadZone"] ? [[prefs objectForKey:@"deadZone"] intValue] : 20);
    cursorSpeed = ([prefs objectForKey:@"cursorSpeed"] ? [[prefs objectForKey:@"cursorSpeed"] intValue] : 10);
    showSelection = ([prefs objectForKey:@"showSelection"] ? [[prefs objectForKey:@"showSelection"] boolValue] : YES);
    enabledSwipeExtenderX = ([prefs objectForKey:@"enabledSwipeExtenderX"] ? [[prefs objectForKey:@"enabledSwipeExtenderX"] boolValue] : NO);
    onlyInSpaceKey = ([prefs objectForKey:@"onlyInSpaceKey"] ? [[prefs objectForKey:@"onlyInSpaceKey"] boolValue] : NO);
    disableTrackpad = ([prefs objectForKey:@"disableTrackpad"] ? [[prefs objectForKey:@"disableTrackpad"] boolValue] : NO);
    deleteKeySound = ([prefs objectForKey:@"deleteKeySound"] ? [[prefs objectForKey:@"deleteKeySound"] boolValue] : YES);
//    enableKeyboardFade = ([prefs objectForKey:@"enableKeyboardFade"] ? [[prefs objectForKey:@"enableKeyboardFade"] boolValue] : YES);
    disableTrackpad = ([prefs objectForKey:@"disableTrackpad"] ? [[prefs objectForKey:@"disableTrackpad"] boolValue] : NO);
    BOOL enableCursorMovingOffset = ([prefs objectForKey:@"enableCursorMovingOffset"] ? [[prefs objectForKey:@"enableCursorMovingOffset"] boolValue] : NO);
    int cursorMovingOffset = ([prefs objectForKey:@"cursorMovingOffset"] ? [[prefs objectForKey:@"cursorMovingOffset"] intValue] : 20);

    if (enableCursorMovingOffset) {
        deadZone = cursorMovingOffset;
    } else if (enabledSwipeExtenderX) {
        deadZone = 65;
    }
}

static void loadPrefsNotification(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    loadPrefs();
}

%ctor {
    @autoreleasepool {
        loadPrefs();
        if (enabledSwitch) {
            NSArray *args = [[NSClassFromString(@"NSProcessInfo") processInfo] arguments];
            
            if (args.count != 0) {
                NSString *executablePath = args[0];
                
                if (executablePath) {
                    NSString *processName = [executablePath lastPathComponent];
                    
                    BOOL isSpringBoard = [processName isEqualToString:@"SpringBoard"];
                    BOOL isApplication = [executablePath rangeOfString:@"/Application"].location != NSNotFound;
                    
                    if (isSpringBoard || isApplication) {

                        %init(globalGroup);

                        CFNotificationCenterAddObserver(CFNotificationCenterGetDistributedCenter(), NULL, loadPrefsNotification, CFSTR("com.miro.swipeselection.settings"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
                    }
                }
            }
        }
    }
}

