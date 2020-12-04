//
//  Welcome.h
//  
//
//  Created by MiRO on 7/1/20.
//

#import "SSRoot.h"

@interface OBButtonTray : UIView
@property (nonatomic,retain) UIVisualEffectView *effectView;
- (void)addButton:(id)arg1;
- (void)addCaptionText:(id)arg1;;
@end

@interface OBBoldTrayButton : UIButton
- (void)setTitle:(id)arg1 forState:(NSUInteger)arg2;
+ (id)buttonWithType:(NSInteger)arg1;
@end

@interface OBWelcomeController : UIViewController
@property (nonatomic,retain) UIView *viewIfLoaded;
@property (nonatomic,strong) UIColor *backgroundColor;
- (OBButtonTray *)buttonTray;
- (id)initWithTitle:(id)arg1 detailText:(id)arg2 icon:(id)arg3;
- (void)addBulletedListItemWithTitle:(id)arg1 description:(id)arg2 image:(id)arg3;
@end




@interface Welcome : UIViewController
- (UIImage *)imageWithTint:(UIImage *)image andTintColor:(UIColor *)tintColor;
@end

