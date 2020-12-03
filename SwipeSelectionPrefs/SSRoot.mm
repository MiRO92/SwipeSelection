//
//  SSRootListController.mm
//  SwipeSelection
//
//  Created by Juan Carlos Perez <carlos@jcarlosperez.me> 01/16/2018
//  © CP Digital Darkroom <admin@cpdigitaldarkroom.com> All rights reserved.
//
#import "SSRoot.h"

extern "C" CFNotificationCenterRef CFNotificationCenterGetDistributedCenter(void);


UIImage *rescaleImage(UIImage *image, CGSize newSize) {
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

UIImage *imageWithTint(UIImage *image, UIColor *tintColor) {
    UIImage *imageNew = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:imageNew];
    imageView.tintColor = tintColor;
    
    UIGraphicsBeginImageContextWithOptions(imageView.bounds.size, NO, 0.0);
    [imageView.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *tintedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return tintedImage;
}

NSArray *countArrayFromArray(NSInteger start, NSArray *countedArray) {
    NSArray * array = [NSArray array];
    NSInteger to = [countedArray count] + start;
    for ( int i = start ; i < to ; i ++ )
        array = [array arrayByAddingObject:[NSNumber numberWithInt:i]];

    return array;
}


//@interface SSRoot : PSListController <MFMailComposeViewControllerDelegate>
@interface SSRoot : HBRootListController <MFMailComposeViewControllerDelegate>
@property (strong, nonatomic) NSMutableArray *dynamicHaptic;
@property (strong, nonatomic) NSMutableArray *dynamicTaptic;
@property (nonatomic, retain) UILabel *titleLabel;
@property (nonatomic, retain) UIImageView *iconView;
@end

@implementation SSRoot

- (instancetype)init {
    self = [super init];
    if (self) {
        SSAppearanceSettings *appearanceSettings = [[SSAppearanceSettings alloc] init];
        self.hb_appearanceSettings = appearanceSettings;

        UIBarButtonItem *respringButton = [[UIBarButtonItem alloc] initWithTitle:@"Respring"
                                style:UIBarButtonItemStylePlain
                                target:self
                                action:@selector(respring)];
        respringButton.tintColor = [UIColor whiteColor];
        self.navigationItem.rightBarButtonItem = respringButton;
        
        [self createDynamicHaptic];
        [self createDynamicTaptic];

    }
    
    self.navigationItem.titleView = [UIView new];
    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,0,10,10)];
    self.titleLabel.font = [UIFont boldSystemFontOfSize:17];
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.titleLabel.text = self.navigationItem.title;
    self.titleLabel.text = [NSString stringWithFormat:@"%@", @tweakName];
    self.titleLabel.textColor = [UIColor whiteColor];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    [self.navigationItem.titleView addSubview:self.titleLabel];
    
    self.iconView = [[UIImageView alloc] initWithFrame:CGRectMake(0,0,10,10)];
    self.iconView.contentMode = UIViewContentModeScaleAspectFit;
    self.iconView.image = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@/Icon@2x.png", @bundle]];
    self.iconView.translatesAutoresizingMaskIntoConstraints = NO;
    self.iconView.alpha = 0.0;
    [self.navigationItem.titleView addSubview:self.iconView];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.titleLabel.topAnchor constraintEqualToAnchor:self.navigationItem.titleView.topAnchor],
        [self.titleLabel.leadingAnchor constraintEqualToAnchor:self.navigationItem.titleView.leadingAnchor],
        [self.titleLabel.trailingAnchor constraintEqualToAnchor:self.navigationItem.titleView.trailingAnchor],
        [self.titleLabel.bottomAnchor constraintEqualToAnchor:self.navigationItem.titleView.bottomAnchor],
        [self.iconView.topAnchor constraintEqualToAnchor:self.navigationItem.titleView.topAnchor],
        [self.iconView.leadingAnchor constraintEqualToAnchor:self.navigationItem.titleView.leadingAnchor],
        [self.iconView.trailingAnchor constraintEqualToAnchor:self.navigationItem.titleView.trailingAnchor],
        [self.iconView.bottomAnchor constraintEqualToAnchor:self.navigationItem.titleView.bottomAnchor],
    ]];
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.titleLabel setText:self.navigationItem.title];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
  CGFloat offsetY = scrollView.contentOffset.y;

  if (offsetY > 60) {
    [UIView animateWithDuration:0.2 animations:^{
      self.iconView.alpha = 1.0;
      self.titleLabel.alpha = 0.0;
    }];
  } else {
    [UIView animateWithDuration:0.2 animations:^{
      self.iconView.alpha = 0.0;
      self.titleLabel.alpha = 1.0;
    }];
  }
}

- (void)viewDidLoad {
    [super viewDidLoad];

    CGRect frame = CGRectMake(0,-50,self.table.bounds.size.width,130);
    UIImage *headerImage = rescaleImage([UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@/Header.png", @bundle]], CGSizeMake(120, 120));
    UIImageView *headerView = [[UIImageView alloc] initWithFrame:frame];
    [headerView setImage:headerImage];
    headerView.backgroundColor = [UIColor clearColor];
    [headerView setContentMode:UIViewContentModeCenter];
    [headerView setAutoresizingMask:UIViewAutoresizingFlexibleWidth];

    self.table.tableHeaderView = headerView;
}

- (void)viewDidAppear:(BOOL)arg1 {
    [super viewDidLoad];

    NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:@prefFile];
    if (![prefs objectForKey:@"showedWelcomeVC"]) {
        [self presentViewController:[Welcome new] animated:YES completion:nil];
    }
}

- (id)specifiers {
    if (_specifiers == nil) {
        
        NSMutableArray *mutableSpecifiers = [NSMutableArray new];
        PSSpecifier *specifier;

        specifier = groupSpecifier(@"");
        [mutableSpecifiers addObject:specifier];

        specifier = groupSpecifier(@"Global Switch");
        setFooterForSpec(@"Turning on/off requires a respring");
        [mutableSpecifiers addObject:specifier];

        specifier = subtitleSwitchCellWithName(@"Enabled");
        [specifier setProperty:@packageID forKey:@"defaults"];
        setKeyForSpec(@"enabledSwitch");
        setDefaultForSpec(@YES);
        [mutableSpecifiers addObject:specifier];
        
        specifier = groupSpecifier(@"Settings");
        setFooterForSpec(@"• Only in Space Key: means SwipeSelection will only work when swiping on the space key.\n• Default Cursor Speed = 10 (Lower means faster).");
        [mutableSpecifiers addObject:specifier];

//        specifier = segmentCellWithName(@"Dead Zone: (%i)");
//        [specifier setProperty:@packageID forKey:@"defaults"];
//        [specifier setProperty:NSClassFromString(@"HBStepperTableCell") forKey:@"cellClass"];
//        [specifier setProperty:@200 forKey:@"max"];
//        [specifier setProperty:@1 forKey:@"min"];
//        [specifier setProperty:@"Dead Zone: (%i)" forKey:@"label"];
//        [specifier setProperty:@"Dead Zone: (1)" forKey:@"singularLabel"];
//        setKeyForSpec(@"deadZone");
//        setDefaultForSpec(@20);
//        [mutableSpecifiers addObject:specifier];
        
//        specifier = subtitleSwitchCellWithName(@"Fade Keyboard");
//        [specifier setProperty:@packageID forKey:@"defaults"];
//        setKeyForSpec(@"enableKeyboardFade");
//        setDefaultForSpec(@YES);
//        [mutableSpecifiers addObject:specifier];

        specifier = subtitleSwitchCellWithName(@"Move the cursor up/down");
        [specifier setProperty:@packageID forKey:@"defaults"];
        setKeyForSpec(@"enabledCursorUpDown");
        setDefaultForSpec(@YES);
        [mutableSpecifiers addObject:specifier];
        
        specifier = subtitleSwitchCellWithName(@"Disable Trackpad");
        [specifier setProperty:@packageID forKey:@"defaults"];
        setKeyForSpec(@"disableTrackpad");
        setDefaultForSpec(@NO);
        [mutableSpecifiers addObject:specifier];

        specifier = subtitleSwitchCellWithName(@"Only in Space Key");
        [specifier setProperty:@packageID forKey:@"defaults"];
        setKeyForSpec(@"onlyInSpaceKey");
        setDefaultForSpec(@NO);
        [mutableSpecifiers addObject:specifier];
        
        specifier = subtitleSwitchCellWithName(@"Selection Menu After Selection");
        [specifier setProperty:@packageID forKey:@"defaults"];
        setKeyForSpec(@"showSelection");
        setDefaultForSpec(@YES);
        [mutableSpecifiers addObject:specifier];
        
        specifier = segmentCellWithName(@"Cursor Speed: (%i)");
        [specifier setProperty:@packageID forKey:@"defaults"];
        [specifier setProperty:NSClassFromString(@"HBStepperTableCell") forKey:@"cellClass"];
        [specifier setProperty:@20 forKey:@"max"];
        [specifier setProperty:@1 forKey:@"min"];
        [specifier setProperty:@"Cursor Speed: (%i)" forKey:@"label"];
        [specifier setProperty:@"Cursor Speed: (1)" forKey:@"singularLabel"];
        setKeyForSpec(@"cursorSpeed");
        setDefaultForSpec(@10);
        [mutableSpecifiers addObject:specifier];
                
        specifier = groupSpecifier(@"Feedback Type");
        [mutableSpecifiers addObject:specifier];
        
        specifier = segmentCellWithName(@"Feedback Type");
        [specifier setProperty:@packageID forKey:@"defaults"];
        [specifier setValues:@[@(1), @(2)] titles:@[@"Taptic Engine", @"Haptic Engine"]];
        setDefaultForSpec(@(1));
        setKeyForSpec(@"feedbackTypeSegment");
        [mutableSpecifiers addObject:specifier];

        NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:@prefFile];
        int feedbackTypeSegment = ([prefs objectForKey:@"feedbackTypeSegment"] ? [[prefs objectForKey:@"feedbackTypeSegment"] intValue] : 1);

        if (feedbackTypeSegment == 1) {
            for(PSSpecifier *sp in _dynamicTaptic) {
                [mutableSpecifiers addObject:sp];
            }
        } else if (feedbackTypeSegment == 2) {
            for(PSSpecifier *sp in _dynamicHaptic) {
                [mutableSpecifiers addObject:sp];
            }
        }
        
        specifier = groupSpecifier(@"Compatibility");
        setFooterForSpec(@"• This option adds SwipeExtenderX compatibility.");
        [mutableSpecifiers addObject:specifier];
        
        specifier = subtitleSwitchCellWithName(@"SwipeExtenderX");
        [specifier setProperty:@packageID forKey:@"defaults"];
        setKeyForSpec(@"enabledSwipeExtenderX");
        setDefaultForSpec(@NO);
        [mutableSpecifiers addObject:specifier];
        
        specifier = groupSpecifier(@"Advanced Settings");
        setFooterForSpec(@"• Default Value = 20px.\n• Default Value for SwipeExtenderX = 65px.\n\n• Cursor Moving: is the distance between the start touching point and the start moving cursor point.\n\n• This option is useful with compatibility with other swiping tweaks.\n\n• Enabling this option will override \"SwipeExtenderX Compatibility\" option.");
        [mutableSpecifiers addObject:specifier];
        
        specifier = subtitleSwitchCellWithName(@"Modify Cursor Moving");
        [specifier setProperty:@packageID forKey:@"defaults"];
        setKeyForSpec(@"enableCursorMovingOffset");
        setDefaultForSpec(@NO);
        [mutableSpecifiers addObject:specifier];

        specifier = segmentCellWithName(@"Cursor Moving After (%i)px");
        [specifier setProperty:@packageID forKey:@"defaults"];
        [specifier setProperty:NSClassFromString(@"HBStepperTableCell") forKey:@"cellClass"];
        [specifier setProperty:@100 forKey:@"max"];
        [specifier setProperty:@1 forKey:@"min"];
        [specifier setProperty:@"Cursor Moving After (%i)px" forKey:@"label"];
        [specifier setProperty:@"Cursor Moving After (1)px" forKey:@"singularLabel"];
        setKeyForSpec(@"cursorMovingOffset");
        setDefaultForSpec(@20);
        [mutableSpecifiers addObject:specifier];
        
        [mutableSpecifiers addObjectsFromArray:[self loadSpecifiersFromPlistName:@"Root" target:self]];

        //_specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
        _specifiers = [mutableSpecifiers copy];

    }
    
    return _specifiers;
}

- (void)presentSupportMailController:(PSSpecifier *)spec {
    MFMailComposeViewController *composeViewController = [[MFMailComposeViewController alloc] init];
    [composeViewController setSubject:[NSString stringWithFormat:@"%@ Support", @tweakName]];
    [composeViewController setToRecipients:[NSArray arrayWithObjects:@"MiRO <tweaks_support@miro92.com>", nil]];

    NSString *product = nil, *version = nil, *build = nil;
    product = (__bridge NSString *)MGCopyAnswer(kMGProductType, nil);
    version = (__bridge NSString *)MGCopyAnswer(kMGProductVersion, nil);
    build = (__bridge NSString *)MGCopyAnswer(kMGBuildVersion, nil);
        
    [composeViewController setMessageBody:[NSString stringWithFormat:@"\n\n\nCurrent Device: %@, iOS %@ (%@)", product, version, build] isHTML:NO];

    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath: @"/bin/sh"];
    [task setArguments:@[@"-c", [NSString stringWithFormat:@"dpkg -l"]]];

    NSPipe *pipe = [NSPipe pipe];
    [task setStandardOutput:pipe];
    [task launch];

    NSData *data = [task.standardOutput fileHandleForReading].readDataToEndOfFile;
    [composeViewController addAttachmentData:data mimeType:@"text/plain" fileName:@"dpkgl.txt"];

    [self.navigationController presentViewController:composeViewController animated:YES completion:nil];
    composeViewController.mailComposeDelegate = self;
}

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    [self dismissViewControllerAnimated: YES completion: nil];
}


-(id) readPreferenceValue:(PSSpecifier *)specifier {
        NSDictionary *prefsPlist = [NSDictionary dictionaryWithContentsOfFile:[NSString stringWithFormat:@"/User/Library/Preferences/%@.plist", [specifier.properties objectForKey:@"defaults"]]];
        if (![prefsPlist objectForKey:[specifier.properties objectForKey:@"key"]]) {
            return [specifier.properties objectForKey:@"default"];
        }
        return [prefsPlist objectForKey:[specifier.properties objectForKey:@"key"]];
}

- (void)setPreferenceValue:(id)value specifier:(PSSpecifier *)specifier {
    NSMutableDictionary *prefsPlist = [[NSMutableDictionary alloc] initWithContentsOfFile:[NSString stringWithFormat:@"/User/Library/Preferences/%@.plist", [specifier.properties objectForKey:@"defaults"]]];
    [prefsPlist setObject:value forKey:[specifier.properties objectForKey:@"key"]];
    [prefsPlist writeToFile:[NSString stringWithFormat:@"/User/Library/Preferences/%@.plist", [specifier.properties objectForKey:@"defaults"]] atomically:1];
    if ([specifier.properties objectForKey:@"PostNotification"]) {
        CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), (CFStringRef)[specifier.properties objectForKey:@"PostNotification"], NULL, NULL, YES);
    }
    [super setPreferenceValue:value specifier:specifier];

    NSDictionary *properties = specifier.properties;
    NSString *key = properties[@"key"];

    if ([key isEqualToString:@"feedbackTypeSegment"]) {
        if ([value intValue] == 1) {
            [self shouldShowFeedbackSpecifiers:1];
        } else if ([value intValue] == 2) {
            [self shouldShowFeedbackSpecifiers:2];
        }
    }

    CFNotificationCenterPostNotification(
        CFNotificationCenterGetDistributedCenter(),
        CFSTR("com.miro.swipeselection.settings"),
        nil, nil, true);
}

- (void)respring {
    UIAlertController *respringAlert = [UIAlertController
        alertControllerWithTitle: [NSString stringWithFormat:@"%@", @tweakName]
        message:@"Do you really want to respring?"
        preferredStyle: UIAlertControllerStyleAlert];
    UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"Confirm" style: UIAlertActionStyleDestructive handler:
        ^(UIAlertAction * action)
        {
            [HBRespringController respringAndReturnTo:[NSURL URLWithString:[NSString stringWithFormat:@"prefs:root=%@", @tweakName]]];
        }];

    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style: UIAlertActionStyleCancel handler: nil];
    [respringAlert addAction: confirmAction];
    [respringAlert addAction: cancelAction];
    [self presentViewController: respringAlert animated: YES completion: nil];
}

- (void)createDynamicHaptic {
    PSSpecifier *specifier;
    _dynamicHaptic = [NSMutableArray new];

    specifier = [PSSpecifier preferenceSpecifierNamed:@"Haptic Type" target:self set:@selector(setPreferenceValue:specifier:) get:@selector(readPreferenceValue:) detail:NSClassFromString(@"PSListItemsController") cell:PSLinkListCell edit:nil];
    [specifier setProperty:@packageID forKey:@"defaults"];
    setKeyForSpec(@"hapticStrength");
    setDefaultForSpec(@(1));
    [specifier setValues:@[@(0), @(1), @(2), @(3)] titles:@[@"None", @"Light",@"Medium", @"Strong"] shortTitles:@[@"None", @"Light",@"Medium", @"Strong"]];
    [_dynamicHaptic addObject:specifier];
}

- (void)createDynamicTaptic {
    PSSpecifier *specifier;
    _dynamicTaptic = [NSMutableArray new];

    specifier = [PSSpecifier preferenceSpecifierNamed:@"Taptic Type" target:self set:@selector(setPreferenceValue:specifier:) get:@selector(readPreferenceValue:) detail:NSClassFromString(@"PSListItemsController") cell:PSLinkListCell edit:nil];
    [specifier setProperty:@packageID forKey:@"defaults"];
    setKeyForSpec(@"tapticStrength");
    setDefaultForSpec(@(1));
    [specifier setValues:@[@(0), @(1), @(2), @(3), @(4), @(5)] titles:@[@"None", @"Light", @"Medium", @"Heavy", @"Soft", @"Rigid"] shortTitles:@[@"None", @"Light", @"Medium", @"Heavy", @"Soft", @"Rigid"]];
    [_dynamicTaptic addObject:specifier];
}

- (void)shouldShowFeedbackSpecifiers:(int)show {
    if (show == 1) {
        [self insertContiguousSpecifiers:_dynamicTaptic afterSpecifierID:@"feedbackTypeSegment" animated:YES];
        [self removeContiguousSpecifiers:_dynamicHaptic animated:YES];
    } else if (show == 2) {
        [self insertContiguousSpecifiers:_dynamicHaptic afterSpecifierID:@"feedbackTypeSegment" animated:YES];
        [self removeContiguousSpecifiers:_dynamicTaptic animated:YES];
    }
}

@end
