//
//  Welcome.m
//  
//
//  Created by MiRO on 7/1/20.
//
#import "Welcome.h"

@interface Welcome ()

@end


@implementation Welcome
OBWelcomeController *welcomeController; // Declaring this here outside of a method will allow the use of it later, such as dismissing.

- (void)viewDidLoad {
    [super viewDidLoad];
    // Create the OBWelcomeView with a title, a desription text, and an icon if you wish. Any of this can be nil if it doesn't apply to your view.
    welcomeController = [[OBWelcomeController alloc] initWithTitle:[NSString stringWithFormat:@"%@", @tweakName] detailText:@"A new way to edit text on iOS using gestures on the keyboard to move the cursor and select text." icon:[UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@/Header.png", @bundle]]];

    // Create a bulleted item with a title, description, and icon. Any of the parameters can be set to nil if you wish. You can have as little or as many of these as you wish. The view automatically compensates for adjustments.
    // As written here, systemImageNamed is an iOS 13 feature. It is available in the UIKitCore framework publically. You are welcome to use your own images just as usual. Make sure you set them up with UIImageRenderingModeAlwaysTemplate to allow proper coloring.
    [welcomeController addBulletedListItemWithTitle:@"Swiping up/down" description:@"to move the cursor up/down." image:[self imageWithTint: [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@/WVC_Header_1.png", @bundle]] andTintColor:tweakTintColor]];
    [welcomeController addBulletedListItemWithTitle:@"Swiping left/right" description:@"to move the cursor left/right." image:[self imageWithTint: [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@/WVC_Header_2.png", @bundle]] andTintColor:tweakTintColor]];
    
    
    // Create your button here, set some properties, and add it to the controller.
    OBBoldTrayButton *continueButton = [OBBoldTrayButton buttonWithType:1];
    [continueButton addTarget:self action:@selector(dismissWelcomeController) forControlEvents:UIControlEventTouchUpInside];
    [continueButton setTitle:@"Continue" forState:UIControlStateNormal];
    [continueButton setClipsToBounds:YES]; // There seems to be an internal issue with the properties, so you may need to force this to YES like so.
    [continueButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal]; // There seems to be an internal issue with the properties, so you may need to force this to be [UIColor whiteColor] like so.
    [continueButton.layer setCornerRadius:25]; // Set your button's corner radius. This can be whatever. If this doesn't work, make sure you make setClipsToBounds to YES.
    [welcomeController.buttonTray addButton:continueButton];
    
    
    // Set the Blur Effect Style of the Button Tray
    //welcomeController.buttonTray.effectView.effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    
    // Create the view that will contain the blur and set the frame to the View of welcomeController
    UIVisualEffectView *effectWelcomeView = [[UIVisualEffectView alloc] initWithFrame:welcomeController.viewIfLoaded.bounds];
    
    // Set the Blur Effect Style of the Blur View
    effectWelcomeView.effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleProminent];
    
    // Insert the Blur View to the View of the welcomeController atIndex:0 to put it behind everything
    [welcomeController.viewIfLoaded insertSubview:effectWelcomeView atIndex:0];
    
    // Set the background to the View of the welcomeController to clear so the blur will show
    welcomeController.viewIfLoaded.backgroundColor = [UIColor clearColor];

    //The caption text goes right above the buttons, sort of like as a thank you or disclaimer. This is optional, and can be excluded from your project.
    [welcomeController.buttonTray addCaptionText:@"Developed by MiRO"];

    welcomeController.modalPresentationStyle = UIModalPresentationPageSheet; // The same style stock iOS uses.
    welcomeController.modalInPresentation = YES; //Set this to yes if you don't want the user to dismiss this on a down swipe.
    welcomeController.view.tintColor = tweakTintColor;
    // If you want a different tint color. If you don't set this, the controller will take the default color.
    //[self presentViewController:welcomeController animated:YES completion:nil]; // Don't forget to present it!
    
    
    [self.view addSubview: welcomeController.view];

}

- (void)dismissWelcomeController { // Say goodbye to your controller. :(
    [[[HBPreferences alloc] initWithIdentifier: @packageID] removeAllObjects];
    [[NSFileManager defaultManager] removeItemAtPath:@prefFile error: nil];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{

        NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:@prefFile] ? : [NSMutableDictionary new];
        
        [prefs setObject:@YES forKey:@"showedWelcomeVC"];
        [prefs writeToFile:@prefFile atomically:YES];
        
        [[HBPreferences preferencesForIdentifier:@packageID] setObject:@YES forKey:@"showedWelcomeVC"];

        [self dismissViewControllerAnimated:YES completion:nil];
    });
}

- (UIImage *)imageWithTint:(UIImage *)image andTintColor:(UIColor *)tintColor {
    UIImage *imageNew = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:imageNew];
    imageView.tintColor = tintColor;

    UIGraphicsBeginImageContextWithOptions(imageView.bounds.size, NO, 0.0);
    [imageView.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *tintedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return tintedImage;
}

@end
