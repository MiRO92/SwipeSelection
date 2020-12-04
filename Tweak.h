#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>
#import <UIKit/UITextInput.h>
#import <UIKit/UIGestureRecognizerSubclass.h>
#import <objc/runtime.h>

#import "SSSettings.h"
#import "SSHapticsManager.h"

@class UIKeyboardTaskExecutionContext;

@interface UIKeyboardTaskQueue : NSObject
@property(retain, nonatomic) UIKeyboardTaskExecutionContext *executionContext;
- (void)finishExecution;
@end

@interface UIKeyboardTaskExecutionContext : NSObject
@property(readonly, nonatomic) UIKeyboardTaskQueue *executionQueue;
@end


@protocol UITextInputPrivate <UITextInput, UITextInputTokenizer> //, UITextInputTraits_Private, UITextSelectingContainer>
- (BOOL)shouldEnableAutoShift;
- (NSRange)selectionRange;
- (CGRect)rectForNSRange:(NSRange)nsrange;
- (NSRange)_markedTextNSRange;
//-(id)selectedDOMRange;
//-(id)wordInRange:(id)range;
//-(void)setSelectedDOMRange:(id)range affinityDownstream:(BOOL)downstream;
//-(void)replaceRangeWithTextWithoutClosingTyping:(id)textWithoutClosingTyping replacementText:(id)text;
//-(CGRect)rectContainingCaretSelection;
- (void)moveBackward:(unsigned)backward;
- (void)moveForward:(unsigned)forward;
- (unsigned short)characterBeforeCaretSelection;
- (id)wordContainingCaretSelection;
- (id)wordRangeContainingCaretSelection;
- (id)markedText;
- (void)setMarkedText:(id)text;
- (BOOL)hasContent;
- (void)selectAll;
- (id)textColorForCaretSelection;
- (id)fontForCaretSelection;
- (BOOL)hasSelection;
@end



/** iOS 5-6 **/
@interface UIKBShape : NSObject
@end

@interface UIKBKey : UIKBShape
@property(copy) NSString *name;
@property(copy) NSString *representedString;
@property(copy) NSString *displayString;
@property(copy) NSString *displayType;
@property(copy) NSString *interactionType;
@property(copy) NSString *variantType;
//@property(copy) UIKBAttributeList **attributes;
@property(copy) NSString *overrideDisplayString;
@property(copy) NSString *clientVariantRepresentedString;
@property(copy) NSString *clientVariantActionName;
@property BOOL visible;
@property BOOL hidden;
@property BOOL disabled;
@property BOOL isGhost;
@property int splitMode;
@end


/** iOS 7 **/
@interface UIKBTree : NSObject <NSCopying>
+ (id)keyboard;
+ (id)key;
+ (id)shapesForControlKeyShapes:(id)arg1 options:(int)arg2;
+ (id)mergeStringForKeyName:(id)arg1;
+ (BOOL)shouldSkipCacheString:(id)arg1;
+ (id)stringForType:(int)arg1;
+ (id)treeOfType:(int)arg1;
+ (id)uniqueName;

@property(retain, nonatomic) NSString *layoutTag;
@property(retain, nonatomic) NSMutableDictionary *cache;
@property(retain, nonatomic) NSMutableArray *subtrees;
@property(retain, nonatomic) NSMutableDictionary *properties;
@property(retain, nonatomic) NSString *name;
@property(nonatomic) int type;

- (int)flickDirection;

- (BOOL)isLeafType;
- (BOOL)usesKeyCharging;
- (BOOL)usesAdaptiveKeys;
- (BOOL)modifiesKeyplane;
- (BOOL)avoidsLanguageIndicator;
- (BOOL)isAlphabeticPlane;
- (BOOL)noLanguageIndicator;
- (BOOL)isLetters;
- (BOOL)subtreesAreOrdered;

@end


@interface UIKeyboardLayout : UIView
- (UIKBKey *)keyHitTest:(CGPoint)point;
@end

@interface UIKeyboardLayoutStar : UIKeyboardLayout
// iOS 7
- (id)keyHitTest:(CGPoint)arg1;
- (id)keyHitTestWithoutCharging:(CGPoint)arg1;
- (id)keyHitTestClosestToPoint:(CGPoint)arg1;
- (id)keyHitTestContainingPoint:(CGPoint)arg1;
- (void)willBeginIndirectSelectionGesture:(BOOL)arg1;
- (void)didEndIndirectSelectionGesture:(BOOL)arg1;
- (BOOL)shift;
- (void)deleteAction;
- (BOOL)isShiftKeyBeingHeld;
- (BOOL)shift;
- (BOOL)autoShift;

// New
- (BOOL)SS_isSpaceKey;
- (BOOL)SS_shouldSelect;
- (BOOL)SS_disableSwipes;

@end


@interface UIKeyboardImpl : UIView
+ (UIKeyboardImpl *)sharedInstance;
+ (UIKeyboardImpl *)activeInstance;
@property (readonly, assign, nonatomic) UIResponder <UITextInputPrivate> *privateInputDelegate;
@property (readonly, assign, nonatomic) UIResponder <UITextInput> *inputDelegate;
- (BOOL)isLongPress;
- (BOOL)isTrackpadMode;
- (id)_layout;
- (BOOL)callLayoutIsShiftKeyBeingHeld;
- (void)handleDelete;
- (void)handleDeleteAsRepeat:(BOOL)repeat;
- (BOOL)canHandleDelete;
- (void)deleteBackwardAndNotify:(BOOL)arg1;
- (void)handleDeleteWithNonZeroInputCount;
- (BOOL)isInHardwareKeyboardMode;
- (void)stopAutoDelete;
- (BOOL)handwritingPlane;
- (id)delegateAsResponder;
- (id)inputDelegate;
- (id)privateInputDelegate;
- (id)legacyInputDelegate;
- (id)privateKeyInputDelegate;
- (BOOL)isLongPress;
- (void)clearAnimations;
- (void)clearTransientState;
- (void)setCaretBlinks:(BOOL)arg1;
- (void)deleteFromInput;
- (void)showSelectionCommands;
- (void)updateForChangedSelection;
- (BOOL)isShifted;
- (BOOL)isShiftLocked;
- (BOOL)isAutoShifted;
- (BOOL)shiftLockedEnabled;

// SwipeSelection
- (void)SSLeftRightGesture:(UIPanGestureRecognizer *)gesture;
- (void)SSUpDownGesture:(UIPanGestureRecognizer *)gesture;
@end


@interface UIFieldEditor : NSObject
+ (UIFieldEditor *)sharedFieldEditor;
- (void)revealSelection;
@end


@interface UIView(Private_text) <UITextInput>
// UIWebDocumentView
- (void)_scrollRectToVisible:(CGRect)visible animated:(BOOL)animated;
- (void)scrollSelectionToVisible:(BOOL)visible;

// UITextInputPrivate
- (CGRect)caretRect;
- (void)_scrollRectToVisible:(CGRect)visible animated:(BOOL)animated;

- (NSRange)selectedRange;
- (NSRange)selectionRange;
- (void)setSelectedRange:(NSRange)range;
- (void)setSelectionRange:(NSRange)range;
- (void)scrollSelectionToVisible:(BOOL)arg1;
- (CGRect)rectForSelection:(NSRange)range;
- (CGRect)textRectForBounds:(CGRect)rect;
@end

@interface WKWebView
- (void)evaluateJavaScript:(id)arg1 completionHandler:(/*^block */id)arg2;
- (NSString *)stringByEvaluatingJavaScriptFromString:(NSString *)script;
- (id)loadHTMLString:(NSString *)string baseURL:(NSURL *)baseURL;
@end

// Safari webview
@interface WKContentView : UIView {
    WKWebView *_webView;
}
- (void)moveByOffset:(NSInteger)offset;
- (id)positionFromPosition:(id)arg1 inDirection:(long long)arg2 offset:(long long)arg3 ;
- (id)positionFromPosition:(id)arg1 toBoundary:(long long)arg2 inDirection:(long long)arg3 ;
- (id)textRangeFromPosition:(id)arg1 toPosition:(id)arg2 ;
- (void)setSelectedTextRange:(UITextRange *)arg1 ;
- (id)selectedText;
- (void)selectWordBackward;
- (UITextRange *)selectedTextRange;
- (void)setSelectedTextRange:(UITextRange *)arg1 ;
- (long long)baseWritingDirectionForPosition:(id)arg1 inDirection:(long long)arg2 ;
- (id<UITextInputTokenizer>)tokenizer;
- (UITextRange *)markedTextRange;
- (id)textInRange:(id)arg1 ;
- (void)setMarkedText:(id)arg1 selectedRange:(NSRange)arg2 ;
- (NSRange)selectionRange;
- (NSRange)_markedTextNSRange;
- (UITextPosition *)beginningOfDocument;
- (id)selectionRectsForRange:(id)arg1 ;
- (long long)comparePosition:(id)arg1 toPosition:(id)arg2 ;
- (void)beginSelectionInDirection:(long long)arg1 completionHandler:(id)arg2 ;
- (void)selectTextWithGranularity:(long long)arg1 atPoint:(CGPoint)arg2 completionHandler:(id)arg3 ;
- (void)updateSelectionWithExtentPoint:(CGPoint)arg1 completionHandler:(/*^block */id)arg2 ;
- (void)updateSelectionWithExtentPoint:(CGPoint)arg1 withBoundary:(long long)arg2 completionHandler:(id)arg3 ;
- (id)webView;
- (id)positionFromPosition:(id)arg1 offset:(long long)arg2 ;

- (id)_moveToEndOfWord:(BOOL)arg1 withHistory:(id)arg2 ;
- (id)_moveToEndOfLine:(BOOL)arg1 withHistory:(id)arg2 ;
- (id)_moveRight:(BOOL)arg1 withHistory:(id)arg2 ;
- (id)_moveToStartOfWord:(BOOL)arg1 withHistory:(id)arg2 ;
- (id)_moveToStartOfLine:(BOOL)arg1 withHistory:(id)arg2 ;
- (id)_moveLeft:(BOOL)arg1 withHistory:(id)arg2 ;
- (id)_moveToEndOfParagraph:(BOOL)arg1 withHistory:(id)arg2 ;
- (id)_moveToEndOfDocument:(BOOL)arg1 withHistory:(id)arg2 ;
- (id)_moveDown:(BOOL)arg1 withHistory:(id)arg2 ;
- (id)_moveToStartOfParagraph:(BOOL)arg1 withHistory:(id)arg2 ;
- (id)_moveToStartOfDocument:(BOOL)arg1 withHistory:(id)arg2 ;
- (id)_moveUp:(BOOL)arg1 withHistory:(id)arg2 ;

@end




@interface UIResponder (SwipeSelection)
- (void)scrollSelectionToVisible:(BOOL)scroll;
- (void)_define:(NSString *)text;
@end



@interface WKTextPosition : UITextPosition
@property (assign,nonatomic) CGRect positionRect;
+ (id)textPositionWithRect:(CGRect)arg1 ;
- (BOOL)isEqual:(id)arg1 ;
- (id)description;
- (CGRect)positionRect;
- (void)setPositionRect:(CGRect)arg1 ;
@end



@interface WKTextRange : UITextRange
@property (assign,nonatomic) CGRect startRect;
@property (assign,nonatomic) CGRect endRect;                                     
@property (assign,nonatomic) BOOL isNone;                                        
@property (assign,nonatomic) BOOL isRange;                                       
@property (assign,nonatomic) BOOL isEditable;                                    
@property (assign,nonatomic) long long selectedTextLength;
@property (nonatomic,copy) NSArray *selectionRects;
+ (id)textRangeWithState:(BOOL)arg1 isRange:(BOOL)arg2 isEditable:(BOOL)arg3 startRect:(CGRect)arg4 endRect:(CGRect)arg5 selectionRects:(id)arg6 selectedTextLength:(unsigned long long)arg7 ;
- (BOOL)isEqual:(id)arg1 ;
- (id)description;
- (BOOL)isEmpty;
- (id)start;
- (id)end;
- (BOOL)isEditable;
- (BOOL)_isRanged;
- (BOOL)_isCaret;
- (NSArray *)selectionRects;
- (void)setStartRect:(CGRect)arg1 ;
- (void)setEndRect:(CGRect)arg1 ;
- (CGRect)startRect;
- (CGRect)endRect;
- (void)setIsEditable:(BOOL)arg1 ;
- (void)setIsNone:(BOOL)arg1 ;
- (void)setIsRange:(BOOL)arg1 ;
- (void)setSelectedTextLength:(long long)arg1 ;
- (void)setSelectionRects:(NSArray *)arg1 ;
- (BOOL)isRange;
- (BOOL)isNone;
- (long long)selectedTextLength;
@end



@interface UIKeyboardInputMode : UITextInputMode
@property (nonatomic,retain) NSString *normalizedIdentifier;
@end

@interface UIKeyboardInputModeController : NSObject
@property (retain) UIKeyboardInputMode *currentInputMode;
+ (id)sharedInputModeController;
- (UIKeyboardInputMode *)currentInputMode;
@end
