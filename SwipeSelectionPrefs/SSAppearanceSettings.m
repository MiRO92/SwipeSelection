#import "SSRoot.h"


@implementation SSAppearanceSettings

- (UIColor*)tintColor {
    return tweakTintColor;
}

- (UIColor*)statusBarTintColor {
    return [UIColor whiteColor];
}

- (UIColor*)navigationBarTitleColor {
    return [UIColor whiteColor];
}

- (UIColor*)navigationBarTintColor {
    return [UIColor whiteColor];
}

- (UIColor*)tableViewCellSeparatorColor {
    return [UIColor clearColor];
}

- (UIColor*)navigationBarBackgroundColor {
    return tweakTintColor;
}

- (UIColor*)tableViewCellTextColor {
    return tweakTintColor;
}

- (BOOL)translucentNavigationBar {
    return YES;
}

- (HBAppearanceSettingsLargeTitleStyle)largeTitleStyle {
    return 2;
}
@end
