//
//  SSRoot.h
//  SwipeSelection
//
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import <MobileGestalt/MobileGestalt.h>
#import <Preferences/PSSpecifier.h>
#import <Preferences/PSListController.h>
#import <Preferences/PSListItemsController.h>
#import <Preferences/PSControlTableCell.h>
#import <Preferences/PSEditableTableCell.h>
#import <CepheiPrefs/HBRootListController.h>
#import <CepheiPrefs/CepheiPrefs.h>
#import <Cephei/HBPreferences.h>
#import <UIKit/UIImage+Private.h>

#import <version.h>
#include <spawn.h>
#import "Welcome.h"
#import "../SSSettings.h"

@interface NSTask : NSObject
- (id)init;
- (void)launch;
- (void)setArguments:(id)arg1;
- (void)setLaunchPath:(id)arg1;
- (void)setStandardOutput:(id)arg1;
- (id)standardOutput;
@end

@interface NSConcreteNotification : NSNotification { // return key to dismiss the keyboard
    BOOL dyingObject;
    NSString *name;
    id object;
    NSDictionary *userInfo;
}
+ (id)newTempNotificationWithName:(id)arg1 object:(id)arg2 userInfo:(id)arg3;
- (void)dealloc;
- (id)initWithName:(id)arg1 object:(id)arg2 userInfo:(id)arg3;
- (id)name;
- (id)object;
- (void)recycle;
- (id)userInfo;

@end


@interface HBRespringController : NSObject
+ (void)respring;
+ (void)respringAndReturnTo:(NSURL *)returnURL;
@end


@interface SSAppearanceSettings: HBAppearanceSettings
@end


#define buttonCellWithName(name) [PSSpecifier preferenceSpecifierNamed:name target:self set:NULL get:NULL detail:NULL cell:PSButtonCell edit:Nil]
#define groupSpecifier(name) [PSSpecifier groupSpecifierWithName:name]
#define subtitleSwitchCellWithName(name) [PSSpecifier preferenceSpecifierNamed:name target:self set:@selector(setPreferenceValue:specifier:) get:@selector(readPreferenceValue:) detail:NULL cell:PSSwitchCell edit:Nil]
#define switchCellWithName(name) [PSSpecifier preferenceSpecifierNamed:name target:self set:@selector(setPreferenceValue:specifier:) get:@selector(readPreferenceValue:) detail:NULL cell:PSSwitchCell edit:Nil]
#define textCellWithName(name) [PSSpecifier preferenceSpecifierNamed:name target:self set:NULL get:NULL detail:NULL cell:PSStaticTextCell edit:Nil]
#define textEditCellWithName(name) [PSSpecifier preferenceSpecifierNamed:name target:self set:@selector(setPreferenceValue:specifier:) get:@selector(readPreferenceValue:) detail:NULL cell:PSEditTextCell edit:Nil]
#define segmentCellWithName(name) [PSSpecifier preferenceSpecifierNamed:name target:self set:@selector(setPreferenceValue:specifier:) get:@selector(readPreferenceValue:) detail:NULL cell:PSSegmentCell edit:Nil]
#define setDefaultForSpec(sDefault) [specifier setProperty:sDefault forKey:@"default"]
#define setClassForSpec(className) [specifier setProperty:className forKey:@"cellClass"]
#define setPlaceholderForSpec(placeholder) [specifier setProperty:placeholder forKey:@"placeholder"]

#define setKeyForSpec(key) [specifier setProperty:key forKey:@"key"]
#define setFooterForSpec(footer) [specifier setProperty:footer forKey:@"footerText"]
