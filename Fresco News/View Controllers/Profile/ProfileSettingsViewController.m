//
//  ProfileSettingsViewController.m
//  FrescoNews
//
//  Created by Zachary Mayberry on 5/12/15.
//  Copyright (c) 2015 Fresco. All rights reserved.
//

#import "ProfileSettingsViewController.h"
#import "FRSUser.h"
#import "FRSDataManager.h"
#import "FRSRootViewController.h"
#import "MKMapView+Additions.h"
#import <AFNetworking/UIImageView+AFNetworking.h>
#import <MapKit/MapKit.h>
#import "MapViewOverlayBottom.h"
#import "MapOverlayTop.h"
#import <SVPulsingAnnotationView.h>

typedef enum : NSUInteger {
    SocialNetworkFacebook,
    SocialNetworkTwitter
} SocialNetwork;

typedef enum : NSUInteger {
    SocialExists,
    SocialDisable,
    SocialUnlinked,
    SocialNoError
} SocialError;

@interface ProfileSettingsViewController () <MKMapViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate, UIActionSheetDelegate>

/***** In order of presentation *****/

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

/*
 ** Profile Picture
 */

@property (weak, nonatomic) IBOutlet UIImageView *profileImageView;
@property (strong, nonatomic) UIImage *selectedImage;

/*
 ** Text Fields
 */

@property (weak, nonatomic) IBOutlet UITextField *textfieldFirst;
@property (weak, nonatomic) IBOutlet UITextField *textfieldLast;
@property (weak, nonatomic) IBOutlet UITextField *textfieldNewPassword;
@property (weak, nonatomic) IBOutlet UITextField *textfieldConfirmPassword;
@property (weak, nonatomic) IBOutlet UITextField *textfieldEmail;

/*
 ** Buttons
 */

@property (weak, nonatomic) IBOutlet UIButton *connectTwitterButton;
@property (weak, nonatomic) IBOutlet UIButton *connectFacebookButton;
@property (weak, nonatomic) IBOutlet UIButton *logoutButton;

@property (weak, nonatomic) IBOutlet UIButton *saveChangesbutton;

/*
 ** Radius Setting
 */

@property (weak, nonatomic) IBOutlet UISlider *radiusStepper;
@property (weak, nonatomic) IBOutlet UILabel *radiusStepperLabel;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;

@property (weak, nonatomic) IBOutlet MapOverlayTop *topMapOverlay;
@property (weak, nonatomic) IBOutlet MapViewOverlayBottom *bottomMapOverlay;

/*
 ** UI Constraints
 */

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *twitterIconCenterXConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *facebookIconCenterXConstraint;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintAccountVerticalBottom;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintAccountVerticalTop;

/* Action Sheet */

@property (strong, nonatomic) UIActionSheet *disableAccountSheet;

/* Spinner */

@property (strong, nonatomic) UIActivityIndicatorView *spinner;

@end

@implementation ProfileSettingsViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    [self setSaveButtonStateEnabled:NO];

    self.saveChangesbutton.alpha = 0;

    //Checks if the user's primary login is through social, then disable the email and password fields
    if(([PFTwitterUtils isLinkedWithUser:[PFUser currentUser]]
        || [PFFacebookUtils isLinkedWithUser:[PFUser currentUser]])
       && [FRSDataManager sharedManager].currentUser.email == nil){
        
        [self.view viewWithTag:100].hidden = YES;
        [self.view viewWithTag:101].hidden = YES;
        [self.view viewWithTag:102].hidden = YES;
        
        CGFloat y = -self.view.frame.size.height/5;
        self.constraintAccountVerticalTop.constant = y;
        self.constraintAccountVerticalBottom.constant = 0;
        
        self.textfieldEmail.userInteractionEnabled = NO;
        self.textfieldNewPassword.userInteractionEnabled = NO;
        self.textfieldConfirmPassword.userInteractionEnabled = NO;
        
    } else {
        self.constraintAccountVerticalTop.constant = [self.view viewWithTag:100].frame.size.height;
        self.constraintAccountVerticalBottom.constant = 0;
    }
    
    //Update the profile image
    if ([FRSDataManager sharedManager].currentUser.avatar != nil) {
        [self.profileImageView setImageWithURLRequest:[NSURLRequest requestWithURL:[[FRSDataManager sharedManager].currentUser avatarUrl]] placeholderImage:[UIImage imageNamed:@"user"]
                                              success:nil failure:nil];
    }
    
    //TapGestureRecognizer for the profile picture, to bring up the MediaPickerController
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapDetected)];
    singleTap.numberOfTapsRequired = 1;
    
    //Make the profile image interactive
    [self.profileImageView setUserInteractionEnabled:YES];
    [self.profileImageView addGestureRecognizer:singleTap];
    self.profileImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.profileImageView.layer.cornerRadius = self.profileImageView.frame.size.width / 2;
    self.profileImageView.clipsToBounds = YES;
    
    //Round the buttons
    self.connectTwitterButton.layer.cornerRadius = 4;
    self.connectTwitterButton.clipsToBounds = YES;
    
    self.connectFacebookButton.layer.cornerRadius = 4;
    self.connectFacebookButton.clipsToBounds = YES;
    
    //Update social connect buttons
    [self updateLinkingStatus];
    
    //Initialize Disable Account UIActionSheet
    self.disableAccountSheet = [[UIActionSheet alloc]
                                initWithTitle:DISABLE_ACCT_TITLE
                                delegate:self
                                cancelButtonTitle:CANCEL
                                destructiveButtonTitle:DISABLE
                                otherButtonTitles:nil];
    
    //Disable Account Sheet Tag
    self.disableAccountSheet.tag = 100;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textFieldDidChange:) name:UITextFieldTextDidChangeNotification object:nil];
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.textfieldFirst.text = [FRSDataManager sharedManager].currentUser.first;
    self.textfieldLast.text  = [FRSDataManager sharedManager].currentUser.last;
    self.textfieldEmail.text = [FRSDataManager sharedManager].currentUser.email;
    
    // Radius slider values
    self.radiusStepper.value = [[FRSDataManager sharedManager].currentUser.notificationRadius floatValue];
    
    // update the slider label
    [self sliderValueChanged:self.radiusStepper];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    self.saveChangesbutton.alpha = 1;

}

-(void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    [self.saveChangesbutton sizeToFit];

}

-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    
    if (self.saveChangesbutton.alpha != 1) {
        

    }
}

#pragma mark - Controller Methods

/*
** Sets the state of the save button
*/

- (void)setSaveButtonStateEnabled:(BOOL)enabled {
    
    if(enabled){
        self.saveChangesbutton.enabled = YES;
        self.saveChangesbutton.backgroundColor = [UIColor greenToolbarColor];

    }
    else{
        self.saveChangesbutton.enabled = NO;
        self.saveChangesbutton.backgroundColor = [UIColor disabledToolbarColor];

    }
}

/*
** Runs Parse social connect based on SocialNetwork param
*/

- (void)socialConnect:(SocialNetwork)network networkButton:(UIButton*)button{
    
    [button setTitle:@"" forState:UIControlStateNormal];
    
    self.spinner = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(20, 20, (self.connectFacebookButton.frame.size.width), 7)];
    self.spinner.color = [UIColor whiteColor];
    [self.spinner startAnimating];
    
    [button addSubview:self.spinner];
    
    if(network == SocialNetworkFacebook){
        
        //Connect the user
        if (![PFFacebookUtils isLinkedWithUser:[PFUser currentUser]]) {
            
            [PFFacebookUtils linkUserInBackground:[PFUser currentUser] withReadPermissions:@[@"public_profile"] block:^(BOOL succeeded, NSError *error) {
                
                //If fails, alert user
                if (!succeeded) {
                    
                    [self triggerSocialResponse:SocialExists network:@"Facebook"];
                    
                    [PFFacebookUtils unlinkUserInBackground:[PFUser currentUser]];
                    
                }
                else{
                    [self triggerSocialResponse:SocialNoError network:nil];
                }
                
                
            }];
        }
        //Disconnect the user
        else {
            
            //Make sure the social account isn't their primary connector
            if([FRSDataManager sharedManager].currentUser.email != nil){
                
                [PFFacebookUtils unlinkUserInBackground:[PFUser currentUser] block:^(BOOL succeeded, NSError *error) {
                    
                    if (succeeded)
                        [self triggerSocialResponse:SocialUnlinked network:@"Facebook"];
                    else
                        [self triggerSocialResponse:SocialExists network:@"Facebook"];
                    
                }];
                
            }
            else
                [self triggerSocialResponse:SocialDisable network:@"Facebook"];
            
        }
        
    }
    else if(network == SocialNetworkTwitter){
        
        //Connect the user
        if (![PFTwitterUtils isLinkedWithUser:[PFUser currentUser]]) {
            
            [PFTwitterUtils linkUser:[PFUser currentUser] block:^(BOOL succeeded, NSError *error) {
                
                if(!succeeded){
                    
                    [PFTwitterUtils unlinkUserInBackground:[PFUser currentUser] block:^(BOOL succeeded, NSError *error){
                    
                        
                    
                    }];
                    
                    [self triggerSocialResponse:SocialExists network:@"Twitter"];
                }
                else{
                    [self triggerSocialResponse:SocialNoError network:nil];
                }
                
                
            }];
            
        }
        //Disconnect the user
        else {
            
            //Make sure the social account isn't their primary connector
            if([FRSDataManager sharedManager].currentUser.email != nil){
                
                [PFTwitterUtils unlinkUserInBackground:[PFUser currentUser] block:^(BOOL succeeded, NSError *error) {
                    
                    if (!error && succeeded)
                        [self triggerSocialResponse:SocialUnlinked network:@"Twitter"];
                    else
                        [self triggerSocialResponse:SocialExists network:@"Twitter"];
                    
                }];
                
            }
            else{
                
                [self triggerSocialResponse:SocialDisable network:@"Twitter"];
                
            }
            
        }
        
    }
    
}

/*
** Updates the status of the social buttons
*/

- (void)updateLinkingStatus {
    
    if (![PFUser currentUser]) {
        [self.connectTwitterButton setHidden:YES];
        [self.connectFacebookButton setHidden:YES];
    }
    else {
        
        [self.connectTwitterButton setHidden:NO];
        [self.connectFacebookButton setHidden:NO];
        
        //Twitter
        if ([PFTwitterUtils isLinkedWithUser:[PFUser currentUser]]) {
            [self.connectTwitterButton setTitle:@"Disconnect" forState:UIControlStateNormal];
            self.twitterIconCenterXConstraint.constant = 45;
        }
        else {
            [self.connectTwitterButton setTitle:@"Connect" forState:UIControlStateNormal];
            self.twitterIconCenterXConstraint.constant = 35;
        }
        
        //Facebook
        if ([PFFacebookUtils isLinkedWithUser:[PFUser currentUser]]) {
            [self.connectFacebookButton setTitle:@"Disconnect" forState:UIControlStateNormal];
            self.facebookIconCenterXConstraint.constant = 45;
        } else {
            [self.connectFacebookButton setTitle:@"Connect" forState:UIControlStateNormal];
            self.facebookIconCenterXConstraint.constant = 35;
        }
    }
    
}

/*
** Invokes disable account dialog, and runs disable command if confirmed
*/

- (void)disableAcctWithSocialNetwork:(NSString *)network {
    
    NSString *warningTitle;
    NSString *warningMessage;
    
    if (network) {
        
        warningTitle = ACCT_WILL_BE_DISABLED;
        
        warningMessage = [NSString stringWithFormat:@"Since you signed up with %@, disconnecting %@ will disable your account. You can sign in any time in the next year to restore your account.", network, network];
    }
    else{
        
        warningTitle = WELL_MISS_YOU;
        warningMessage = YOU_CAN_LOGIN_FOR_ONE_YR;
    
    }
    
    UIAlertController *alertCon = [[FRSAlertViewManager sharedManager]
                                   alertControllerWithTitle:warningTitle
                                   message: warningMessage
                                   action:CANCEL handler:nil];
    
    [alertCon addAction:[UIAlertAction actionWithTitle:DISABLE style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action){

        [[FRSDataManager sharedManager] disableFrescoUser:^(BOOL success, NSError *error){
            
            if (success) {

                [[FRSDataManager sharedManager] logout];
                
                FRSRootViewController *rvc = (FRSRootViewController *)[[UIApplication sharedApplication] delegate].window.rootViewController;
                
                [rvc setRootViewControllerToHighlights];
                
                [self.navigationController popViewControllerAnimated:NO];
                
            }
            else{
                
                [self presentViewController:[[FRSAlertViewManager sharedManager]
                                             alertControllerWithTitle:ERROR
                                             message:DISABLE_ACCT_ERROR
                                             action:nil]
                                   animated:YES
                                 completion:nil];
                
            }
            
        }];
    }]];
    
    [self presentViewController:alertCon animated:YES completion:nil];
}

/*
** Triggers a response based on the passed Error
*/

- (void)triggerSocialResponse:(SocialError)error network:(NSString *)network{
    
    NSString *message = @"";
    
    if(error != SocialNoError){
    
        if(error == SocialDisable){
            
            [self disableAcctWithSocialNetwork:network];
            
        }
        else{
            
            if(error == SocialExists)
                message = [NSString stringWithFormat:@"It seems you already have an account linked with %@.", network];
            else if(error == SocialUnlinked)
                message = [NSString stringWithFormat:@"You've been disconnected from %@.", network];
            
            [self presentViewController:[[FRSAlertViewManager sharedManager]
                                         alertControllerWithTitle:ERROR
                                         message:message
                                         action:nil]
                               animated:YES
                             completion:nil];
            
        }
        
    }
    
    [self updateLinkingStatus];
    
    [self.spinner removeFromSuperview];
    
}

- (void)saveChanges{
    
    //Break if the saveChangesButton is not enabled
    if(!self.saveChangesbutton.enabled) return;

    NSMutableDictionary *updateParams = [[NSMutableDictionary alloc] initWithCapacity:5];
    
    if ([self.textfieldFirst.text length])
        [updateParams setObject:self.textfieldFirst.text forKey:@"firstname"];
    
    if ([self.textfieldLast.text length])
        [updateParams setObject:self.textfieldLast.text forKey:@"lastname"];
    
    
    [updateParams setObject:[NSString stringWithFormat:@"%d", (int)self.radiusStepper.value] forKey:@"radius"];
    
    NSData *imageData = nil;
    
    if(self.selectedImage){
        
        imageData = UIImageJPEGRepresentation(self.selectedImage, 0.5);
    }
    
    [[FRSDataManager sharedManager] updateFrescoUserWithParams:updateParams withImageData:imageData block:^(BOOL success, NSError *error) {
        
        if (!success) {
            
            [self presentViewController:[[FRSAlertViewManager sharedManager]
                                         alertControllerWithTitle:ERROR
                                         message:PROFILE_SAVE_ERROR
                                         action:DISMISS handler:^(UIAlertAction *handler){
                                             
                                             NSLog(@"ok");
                                             
                                         }]
                               animated:YES
                             completion:nil];
            
        }
        // On success, run password check
        else {
            
            //Tells the ProfileHeaderViewController to update it's view
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:UD_UPDATE_PROFILE_HEADER];
            
            if (self.selectedImage){
                [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_IMAGE_SET object:self.profileImageView.image];
            }
            
            //If they are set, reset them via parse
            if ([self.textfieldNewPassword.text length]) {
                
                if([self.textfieldNewPassword.text isEqualToString:self.textfieldConfirmPassword.text]){
                    
                    [PFUser currentUser].password = self.textfieldNewPassword.text;
                    
                    [[PFUser currentUser] saveInBackgroundWithBlock:^(BOOL success, NSError *error) {
                        
                        if(success) [self.navigationController popViewControllerAnimated:YES];
                        
                    }];
                    
                }
                else{
                    
                    [self presentViewController:[[FRSAlertViewManager sharedManager]
                                                 alertControllerWithTitle:PASSWORD_ERROR_TITLE
                                                 message:PASSWORD_ERROR_MESSAGE
                                                 action:DISMISS]
                                       animated:YES
                                     completion:nil];
                }
            }
            //If passwords are not reset, just go back
            else [self.navigationController popViewControllerAnimated:YES];
            
        }
        
    }];
    
    // send a second post to save the radius -- ignore success
    [updateParams removeAllObjects];

}

#pragma mark - IBActions

- (IBAction)connectFacebook:(id)sender
{
    
    [self socialConnect:SocialNetworkFacebook networkButton:self.connectFacebookButton];
    
}

- (IBAction)connectTwitter:(id)sender
{
    
    [self socialConnect:SocialNetworkTwitter networkButton:self.connectTwitterButton];
    
}

- (IBAction)logOut:(id)sender {
    
    UIAlertController *logOutAlertController = [[FRSAlertViewManager sharedManager] alertControllerWithTitle:@"Are you sure?" message:@"" action:CANCEL];
    
    [logOutAlertController addAction:[UIAlertAction actionWithTitle:@"Log Out" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
        
        [[FRSDataManager sharedManager] logout];
        
        FRSRootViewController *rvc = (FRSRootViewController *)[[UIApplication sharedApplication] delegate].window.rootViewController;
        
        [rvc setRootViewControllerToHighlights];
        
        [self.navigationController popViewControllerAnimated:NO];
        
    
    }]];
    
    [self presentViewController:logOutAlertController animated:YES completion:nil];
}

- (IBAction)disableAccount:(id)sender {

    [self disableAcctWithSocialNetwork:nil];
}

- (IBAction)saveChangeClicked:(id)sender
{
    [self saveChanges];
}

#pragma mark - UISilder Delegate and Actions

- (IBAction)sliderValueChanged:(UISlider *)slider
{
    CGFloat roundedValue = [MKMapView roundedValueForRadiusSlider:slider];
    
    if(roundedValue > 0){
        
        NSString *pluralizer = (roundedValue > 1 || roundedValue == 0) ? @"s" : @"";
        
        NSString *newValue = [NSString stringWithFormat:@"%2.0f mile%@", roundedValue, pluralizer];
        
        // only update changes
        if (![self.radiusStepperLabel.text isEqualToString:newValue])
            self.radiusStepperLabel.text = newValue;
        
    }
    else {
        self.radiusStepperLabel.text = OFF;
    }
}

- (IBAction)sliderTouchUpInside:(UISlider *)slider
{
    if(!self.saveChangesbutton.enabled) [self setSaveButtonStateEnabled:YES];
    
    self.radiusStepper.value = [MKMapView roundedValueForRadiusSlider:slider];
    
    [self.mapView updateUserLocationCircleWithRadius:self.radiusStepper.value * kMetersInAMile];
}

#pragma mark - UITextField Delegate

- (void)textFieldDidChange:(UITextField *)textField {
     if(!self.saveChangesbutton.enabled) [self setSaveButtonStateEnabled:YES];
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    
    if (textField == self.textfieldFirst) {
        [self.textfieldLast becomeFirstResponder];
    }
    if (textField == self.textfieldLast) {
        [self.textfieldLast resignFirstResponder];
    }
    
    if (textField == self.textfieldNewPassword) {
        [self.textfieldConfirmPassword becomeFirstResponder];
    }
    
    if (textField == self.textfieldConfirmPassword) {
        [self.textfieldConfirmPassword resignFirstResponder];
    }
    
    return YES;
}


#pragma mark - MKMapViewDelegate

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
    [mapView updateUserLocationCircleWithRadius:self.radiusStepper.value * kMetersInAMile];
}

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay
{
    return [MKMapView circleRenderWithColor:[UIColor frescoBlueColor] forOverlay:overlay];
}

-(MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    
    //If the annotiation is for the user location
    if (annotation == mapView.userLocation) {
        
        MKAnnotationView *pinView = [mapView dequeueReusableAnnotationViewWithIdentifier:USER_IDENTIFIER];
        
        if(!pinView){
            
            return [MKMapView setupPinForAnnotation:annotation withAnnotationView:pinView];
            
        }
    }
    
    return nil;
}


#pragma mark - UIImagePickerController Delegate

- (void)navigationController:(UINavigationController *)navigationController
      willShowViewController:(UIViewController *)viewController
                    animated:(BOOL)animated
{
    if ([navigationController isKindOfClass:[UIImagePickerController class]])
    {
        viewController.navigationItem.title = AVATAR_PROMPT;
        navigationController.navigationBar.tintColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:.54];
        [navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"navbar-background"] forBarMetrics:UIBarMetricsDefault];
    }
}

-(void)tapDetected {
    
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.allowsEditing = YES;
    picker.delegate = self;
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    
    [self presentViewController:picker animated:YES completion:NULL];
    
}

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{

    self.selectedImage = [info valueForKey:UIImagePickerControllerOriginalImage];
    
    self.profileImageView.image = self.selectedImage;
    
    if(!self.saveChangesbutton.enabled) [self setSaveButtonStateEnabled:YES];
    
    [MKMapView updateUserPinViewForMapView:self.mapView WithImage:self.selectedImage];
    
    // Code here to work with media
    [self dismissViewControllerAnimated:YES completion:nil];
    
}

@end
